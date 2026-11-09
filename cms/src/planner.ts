import {
  newSlide,
  templateLesson,
  type Engine,
  type Lesson,
  type Topic,
} from "./domain";
export const subjects = [
  "Hình học & không gian",
  "Đại số & hàm số",
  "Lập trình & thuật toán",
  "Vật lý & khoa học",
  "Tư duy & ngôn ngữ",
];
const fold = (s: string) =>
  s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/đ/g, "d")
    .toLowerCase();
export function suggestEngines(title: string, subject = ""): Engine[] {
  const t = fold(`${title} ${subject}`);
  const groups: [RegExp, Engine[]][] = [
    [
      /phan so|tu so|mau so/,
      ["fractionBoard", "fractionCompare", "numberLine"],
    ],
    [/bieu do|du lieu|thong ke/, ["barChart"]],
    [/bac hai|parabol/, ["quadraticGraph"]],
    [/toa do|mat phang/, ["coordinatePoint"]],
    [/tap hop|venn/, ["vennDiagram"]],
    [/phep tinh|ket qua/, ["numberInput"]],
    [/nhan dien|hinh dang/, ["shapeMatch"]],
    [
      /goc|tam giac|dien tich|hinh hoc|khong gian|the tich/,
      ["polygonVertices", "solid3D", "symmetryMirror", "tangramRotate"],
    ],
    [
      /vong lap|duong di|buoc lam|lap trinh|thuat toan|robot/,
      ["robotRoute", "loopBuilder", "sequenceTiles"],
    ],
    [
      /van toc|ti le|do doc|dai so|ham so/,
      ["graph", "causalLab", "balanceScale"],
    ],
    [
      /vat ly|khoa hoc|dia tang|dia cau|tai nguyen/,
      ["causalExperiment", "strata3D", "globe3D", "resourceBudget"],
    ],
    [
      /tu duy|ngon ngu|bang chung|phan loai/,
      ["evidenceBoard", "categorySort", "clozeBank", "matchPairs"],
    ],
  ];
  return [
    ...new Set(groups.filter(([re]) => re.test(t)).flatMap(([, e]) => e)),
  ];
}
export function topicRecipe(
  topic: Pick<Topic, "id" | "title" | "subject">,
): Lesson {
  const doc = templateLesson(topic.id, "blank");
  const suggested = suggestEngines(topic.title, topic.subject);
  doc.title = `Khám phá ${topic.title}`.slice(0, 160);
  doc.config.slides = [
    newSlide("story"),
    newSlide(suggested[0] ?? "graph"),
    newSlide("sequenceTiles"),
    newSlide("quiz"),
  ];
  const titles = [
    "Trực giác ban đầu",
    "Thử nghiệm & khám phá",
    "Phát biểu quy luật",
    "Thử thách cuối",
  ];
  doc.config.slides.forEach((s, i) => (s.title = titles[i]));
  doc.config.slides[0].config.text = `Điều gì khiến ${topic.title.toLowerCase()} thú vị? Quan sát mô hình ở bước tiếp theo, thay đổi một yếu tố và mô tả điều bạn nhận ra.`;
  return doc;
}
function tokens(s: string) {
  return new Set(fold(s).match(/[a-z0-9]+/g) ?? []);
}
export function similarity(a: Lesson, b: Lesson): number {
  const content = (d: Lesson) =>
    [
      d.title,
      d.prompt,
      ...(d.config.slides ?? []).flatMap((s) => [
        s.title,
        s.prompt,
        s.config.text ?? "",
        ...(s.config.choices ?? []),
        ...(s.config.items ?? []),
      ]),
    ].join(" ");
  const x = tokens(content(a)),
    y = tokens(content(b));
  const union = new Set([...x, ...y]).size;
  const lexical = union ? [...x].filter((t) => y.has(t)).length / union : 0;
  const mx = new Set((a.config.slides ?? []).map((s) => s.engine)),
    my = new Set((b.config.slides ?? []).map((s) => s.engine));
  const mechanics =
    [...mx].filter((e) => my.has(e)).length /
    (new Set([...mx, ...my]).size || 1);
  return lexical * 0.85 + mechanics * 0.15;
}
export function qualityReport(doc: Lesson, library: Lesson[]) {
  const peers = library
    .map((d) => d.published_snapshot ?? d)
    .filter(
      (d) =>
        d.id !== doc.id &&
        d.topic_id === doc.topic_id &&
        d.builder_status === "published" &&
        d.status !== "archived",
    );
  const slides = [...peers, doc]
    .flatMap((d) => d.config.slides ?? [])
    .filter((s) => s.engine !== "story");
  const ratio = slides.length
    ? slides.filter((s) => s.engine === "quiz").length / slides.length
    : 0;
  const duplicates = peers
    .map((d) => ({ id: d.id, title: d.title, score: similarity(doc, d) }))
    .filter((d) => d.score > 0.7);
  return {
    ratio,
    diversity: new Set(slides.map((s) => s.engine)).size,
    duplicates,
    warnings: [
      ...(ratio > 0.5
        ? ["Hơn 50% tương tác là trắc nghiệm. Thử thêm mô hình trực quan."]
        : []),
      ...duplicates.map(
        (d) =>
          `Tương đồng ${Math.round(d.score * 100)}% với “${d.title}”. Hãy kiểm tra mục tiêu và câu hỏi.`,
      ),
    ],
  };
}
