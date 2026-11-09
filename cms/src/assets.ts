const types: Record<string, string> = {
  "image/png": "png",
  "image/jpeg": "jpg",
  "image/webp": "webp",
  "image/gif": "gif",
  "image/svg+xml": "svg",
};
export async function prepareAsset(
  file: File,
): Promise<{ body: Blob; extension: string }> {
  const extension = types[file.type];
  if (!extension || file.size === 0 || file.size > 5 * 1024 * 1024)
    throw new Error("Chọn ảnh PNG, JPEG, WebP, GIF hoặc SVG, tối đa 5 MB.");
  if (extension !== "svg") {
    const b = new Uint8Array(await file.slice(0, 16).arrayBuffer());
    const ascii = String.fromCharCode(...b);
    const valid =
      extension === "png"
        ? b[0] === 137 && ascii.slice(1, 4) === "PNG"
        : extension === "jpg"
          ? b[0] === 255 && b[1] === 216 && b[2] === 255
          : extension === "gif"
            ? /^GIF8[79]a/.test(ascii)
            : ascii.startsWith("RIFF") && ascii.slice(8, 12) === "WEBP";
    if (!valid) throw new Error("Định dạng nội dung ảnh không khớp loại file.");
    return { body: file, extension };
  }
  const safe = await sanitizeSvg(file);
  // Flutter's raster image decoder does not decode SVG. Persist a PNG so the
  // mobile runtime and web preview use the same asset without extra plugins.
  const image = new Image();
  const url = URL.createObjectURL(safe);
  try {
    await new Promise<void>((resolve, reject) => {
      image.onload = () => resolve();
      image.onerror = () => reject(new Error("Không giải mã được hình SVG."));
      image.src = url;
    });
    const canvas = document.createElement("canvas");
    const width = image.naturalWidth || 600,
      height = image.naturalHeight || 400;
    const scale = Math.min(1, 2048 / Math.max(width, height));
    canvas.width = Math.max(1, Math.round(width * scale));
    canvas.height = Math.max(1, Math.round(height * scale));
    const context = canvas.getContext("2d");
    if (!context) throw new Error("Trình duyệt chưa hỗ trợ chuyển đổi SVG.");
    context.drawImage(image, 0, 0, canvas.width, canvas.height);
    const body = await new Promise<Blob>((resolve, reject) =>
      canvas.toBlob(
        (blob) =>
          blob ? resolve(blob) : reject(new Error("Chưa chuyển đổi được SVG.")),
        "image/png",
      ),
    );
    if (body.size > 5 * 1024 * 1024)
      throw new Error("Ảnh sau chuyển đổi vượt quá 5 MB.");
    return { body, extension: "png" };
  } finally {
    URL.revokeObjectURL(url);
  }
}

export async function sanitizeSvg(file: File): Promise<Blob> {
  const xml = new DOMParser().parseFromString(
    await file.text(),
    "image/svg+xml",
  );
  if (
    xml.querySelector("parsererror") ||
    xml.documentElement.localName !== "svg"
  )
    throw new Error("File SVG không hợp lệ.");
  // Only inert vector geometry; no scripts, styles, links, foreign HTML or remote resources.
  const tags = new Set([
    "svg",
    "g",
    "path",
    "rect",
    "circle",
    "ellipse",
    "line",
    "polyline",
    "polygon",
    "text",
    "tspan",
    "title",
    "desc",
  ]);
  const attrs = new Set([
    "xmlns",
    "viewBox",
    "width",
    "height",
    "x",
    "y",
    "x1",
    "y1",
    "x2",
    "y2",
    "cx",
    "cy",
    "r",
    "rx",
    "ry",
    "d",
    "points",
    "fill",
    "stroke",
    "stroke-width",
    "opacity",
    "fill-opacity",
    "stroke-opacity",
    "transform",
    "font-size",
    "text-anchor",
  ]);
  for (const el of [xml.documentElement, ...xml.querySelectorAll("*")]) {
    if (!tags.has(el.localName)) {
      el.remove();
      continue;
    }
    for (const a of [...el.attributes])
      if (
        !attrs.has(a.name) ||
        (/url\s*\(|javascript:|data:|https?:/i.test(a.value) &&
          a.name !== "xmlns")
      )
        el.removeAttribute(a.name);
  }
  return new Blob([new XMLSerializer().serializeToString(xml)], {
    type: "image/svg+xml",
  });
}
