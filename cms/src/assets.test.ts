// @vitest-environment jsdom
import { expect, it } from "vitest";
import { File as NodeFile } from "node:buffer";
import { prepareAsset, sanitizeSvg } from "./assets";
const file = (parts: BlobPart[], name: string, type: string) =>
  new NodeFile(parts as never[], name, { type }) as unknown as File;
it("rejects oversized, empty, executable and disguised image files", async () => {
  for (const f of [
    file(["<script>alert(1)</script>"], "fake.png", "image/png"),
    file(["x"], "test.html", "text/html"),
    file([], "empty.png", "image/png"),
    file([new Uint8Array(5242881)], "huge.png", "image/png"),
  ])
    await expect(prepareAsset(f)).rejects.toThrow();
});
it("accepts raster signatures and strips active SVG content and remote references", async () => {
  expect(
    (
      await prepareAsset(
        file(
          [new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10])],
          "safe.png",
          "image/png",
        ),
      )
    ).extension,
  ).toBe("png");
  const f = file(
    [
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10" onload="alert(1)"><script>alert(1)</script><foreignObject><iframe/></foreignObject><image href="https://example.com/track"/><path d="M0 0L1 1" fill="url(https://evil.example/x)" onclick="alert(1)"/><text>Hello</text></svg>',
    ],
    "vector.svg",
    "image/svg+xml",
  );
  const result = await sanitizeSvg(f),
    xml = await result.text();
  expect(xml).not.toMatch(
    /script|foreignObject|iframe|image|onload|onclick|evil|track/,
  );
  expect(xml).toContain('d="M0 0L1 1"');
  expect(xml).toContain("Hello");
});
