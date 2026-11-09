import {
  extendedEngines,
  extendedConfig,
  validExtended,
  correctExtended,
  type ExtendedEngine,
  type ExtendedConfig,
} from "./engine-contract";
export type Engine = "story" | "quiz" | "pairs" | "graph" | ExtendedEngine;
export type Slide = {
  id: string;
  engine: Engine;
  locked: boolean;
  title: string;
  prompt: string;
  hint: string;
  explanation: string;
  config: ExtendedConfig & {
    text?: string;
    image_url?: string;
    image_alt?: string;
    choices?: string[];
    answer?: number;
    pairs?: { left: string; right: string }[];
    min_a?: number;
    max_a?: number;
    min_b?: number;
    max_b?: number;
    start_a?: number;
    start_b?: number;
    target_a?: number;
    target_b?: number;
  };
};
export type Topic = {
  id: string;
  title: string;
  subtitle: string;
  subject: string;
  status: string;
  sort_order: number;
  icon_key: string;
  action_label?: string;
  activity_count?: number;
};
export type Lesson = {
  id: string;
  topic_id: string;
  title: string;
  prompt: string;
  stage: string;
  hint: string;
  explanation: string;
  sort_order: number;
  status: string;
  mechanism: string;
  config: { schema_version?: number; slides?: Slide[]; [key: string]: unknown };
  revision: number;
  draft_revision: number;
  content_revision: number;
  builder_status?: string;
  evaluator_version?: number;
  published_snapshot?: Lesson;
  content_version?: number;
  convert_from_version?: number;
};
export const engines: Record<
  Engine,
  { name: string; short: string; description: string; color: string }
> = {
  ...(Object.fromEntries(
    Object.entries(extendedEngines).map(([key, [name, , description]]) => [
      key,
      { name, short: name, description, color: "lime" },
    ]),
  ) as Record<
    ExtendedEngine,
    { name: string; short: string; description: string; color: string }
  >),
  story: {
    name: "Câu chuyện & hình ảnh",
    short: "Nội dung",
    description: "Dẫn dắt bằng câu chuyện và hình minh họa.",
    color: "peach",
  },
  quiz: {
    name: "Câu hỏi lựa chọn",
    short: "Trắc nghiệm",
    description: "Đặt câu hỏi để người học tự khám phá.",
    color: "lavender",
  },
  pairs: {
    name: "Kéo thả ghép cặp",
    short: "Ghép cặp",
    description: "Kết nối các ý tưởng bằng tương tác.",
    color: "blue",
  },
  graph: {
    name: "Phòng thí nghiệm đồ thị",
    short: "Đồ thị",
    description: "Thử nghiệm y = ax + b với thanh trượt.",
    color: "lime",
  },
};
export const uid = (prefix: string) => `${prefix}-${crypto.randomUUID()}`;
export const clone = <T>(value: T): T => structuredClone(value);
export function newSlide(engine: Engine): Slide {
  return {
    id: uid("slide"),
    engine,
    locked: true,
    title: engines[engine].name,
    prompt:
      engine === "story" ? "" : "Quan sát, thử nghiệm và tìm câu trả lời.",
    hint: "Thay đổi từng yếu tố và quan sát điều xảy ra.",
    explanation: "Bạn vừa tìm ra một quy luật mới!",
    config:
      engine in extendedEngines
        ? extendedConfig(engine as ExtendedEngine)
        : {
            story: {
              text: "Mọi khám phá lớn đều bắt đầu từ một câu hỏi nhỏ. Hãy cùng tìm hiểu nhé!",
              image_url: "",
              image_alt: "",
            },
            quiz: {
              choices: [
                "Lựa chọn thứ nhất",
                "Lựa chọn thứ hai",
                "Lựa chọn thứ ba",
              ],
              answer: 0,
            },
            pairs: {
              pairs: [
                { left: "Một nửa", right: "1/2" },
                { left: "Một phần tư", right: "1/4" },
              ],
            },
            graph: {
              min_a: -5,
              max_a: 5,
              min_b: -5,
              max_b: 5,
              start_a: 0,
              start_b: 0,
              target_a: 2,
              target_b: 1,
            },
          }[engine as "story" | "quiz" | "pairs" | "graph"],
  };
}
export function templateLesson(topic: string, template: string): Lesson {
  const story = newSlide("story"),
    quiz = newSlide("quiz"),
    graph = newSlide("graph"),
    pairs = newSlide("pairs");
  story.title = "Một đường thẳng. Vô vàn khả năng.";
  story.config.text =
    "Nếu bạn có thể điều khiển một đường thẳng chỉ bằng hai con số thì sao?\n\nTrong bài này, hãy kéo, thử và tự mình tìm ra vai trò của a và b trong y = ax + b.";
  graph.title = "Điều gì làm đường thẳng thay đổi?";
  graph.prompt =
    "Hãy tạo đường thẳng đi qua (0, 1) và (1, 3). Kéo hai thanh trượt để khám phá.";
  graph.hint =
    "Giao điểm với trục dọc cho bạn b. Khi x tăng 1, y tăng bao nhiêu?";
  graph.explanation = "Đúng rồi! Với a = 2 và b = 1, ta có y = 2x + 1.";
  quiz.title = "Bạn đã nhận ra quy luật?";
  quiz.prompt = "Giữ nguyên b và tăng a. Điều gì thay đổi?";
  quiz.config.choices = [
    "Độ dốc của đường thẳng",
    "Giao điểm với trục dọc",
    "Cả hai đều không đổi",
  ];
  quiz.explanation = "a quyết định độ dốc. b quyết định vị trí cắt trục dọc.";
  pairs.title = "Kết nối ý tưởng";
  pairs.config.pairs = [
    { left: "a", right: "Độ dốc" },
    { left: "b", right: "Giao điểm trục y" },
  ];
  let slides = [story, graph, quiz, pairs],
    title = "Khám phá đường thẳng";
  if (template === "fractions") {
    story.title = "Một chiếc bánh, nhiều cách chia";
    story.config.text =
      "Chia một chiếc bánh thành 4 phần bằng nhau. Hai phần bánh chính là một nửa chiếc bánh!";
    quiz.title = "Hai phần tư bằng bao nhiêu?";
    quiz.prompt = "Chọn phân số tương đương với 2/4.";
    quiz.config.choices = ["1/2", "1/3", "1/4"];
    quiz.hint = "Chia cả tử và mẫu cho 2.";
    quiz.explanation = "2/4 = 1/2 vì cùng biểu diễn một nửa.";
    pairs.title = "Ghép phân số tương đương";
    pairs.config.pairs = [
      { left: "1/2", right: "2/4" },
      { left: "1/3", right: "2/6" },
    ];
    slides = [story, quiz, pairs];
    title = "Phân số quanh ta";
  }
  if (template === "blank") {
    slides = [newSlide("story"), newSlide("quiz")];
    title = "Bài học chưa đặt tên";
  }
  return {
    id: uid("lesson"),
    topic_id: topic,
    title,
    prompt: "Khám phá ý tưởng qua quan sát và thử nghiệm.",
    stage: "Khám phá",
    hint: "Thử từng bước.",
    explanation: "Bạn đã hoàn thành bài học!",
    sort_order: 0,
    status: "active",
    mechanism: "slideLesson",
    config: { schema_version: 1, slides },
    revision: 0,
    draft_revision: 0,
    content_revision: 0,
    builder_status: "draft",
  };
}
export function normalizeLesson(
  row: Record<string, unknown>,
  topic: string,
): Lesson {
  return {
    ...row,
    id: String(row.id ?? row.activity_id),
    topic_id: topic,
    title: String(row.title ?? ""),
    prompt: String(row.prompt ?? ""),
    stage: String(row.stage ?? "Khám phá"),
    hint: String(row.hint ?? (row.hint_levels as string[])?.[0] ?? ""),
    explanation: String(row.explanation ?? ""),
    sort_order: Number(row.sort_order ?? 0),
    status: String(row.editor_status ?? row.status ?? "active"),
    mechanism: String(row.mechanism ?? ""),
    config: clone((row.config ?? {}) as Lesson["config"]),
    revision: Number(row.content_revision ?? row.revision ?? 0),
    content_revision: Number(row.content_revision ?? row.revision ?? 0),
    draft_revision: Number(row.draft_revision ?? 0),
  } as Lesson;
}
export function payload(lesson: Lesson) {
  return {
    id: lesson.id,
    topic_id: lesson.topic_id,
    title: lesson.title.trim(),
    prompt: lesson.prompt.trim(),
    stage: lesson.stage,
    hint: lesson.hint,
    explanation: lesson.explanation,
    sort_order: lesson.sort_order,
    status: lesson.status,
    mechanism: lesson.mechanism,
    config: clone(lesson.config),
    ...(lesson.convert_from_version !== undefined
      ? { convert_from_version: lesson.convert_from_version }
      : {}),
  };
}
const text = (s: unknown, max: number, empty = false) =>
  typeof s === "string" && s.length <= max && (empty || s.trim().length > 0);
const integer = (s: unknown, min: number, max: number) =>
  typeof s === "number" && Number.isInteger(s) && s >= min && s <= max;
export function validateLesson(lesson: Lesson, interactive = true): string[] {
  const errors: string[] = [];
  if (!text(lesson.title, 160) || !text(lesson.prompt, 10000))
    errors.push("Đặt tên bài và mục tiêu học tập.");
  if (new TextEncoder().encode(JSON.stringify(payload(lesson))).length > 95000)
    errors.push("Bài học quá dài. Hãy chia thành nhiều bài nhỏ.");
  if (!integer(lesson.sort_order, 0, 100000))
    errors.push("Thứ tự bài phải là số nguyên không âm.");
  if (
    !text(lesson.stage, 160) ||
    !text(lesson.hint, 3000) ||
    !text(lesson.explanation, 10000)
  )
    errors.push("Điền giai đoạn, gợi ý và lời giải cho bài học.");
  if (lesson.mechanism === "reasonedChoice") {
    const c = lesson.config,
      choices = c.choices,
      reasons = c.reasons;
    if (
      !Array.isArray(choices) ||
      choices.length < 2 ||
      choices.length > 8 ||
      !choices.every((v) => text(v, 2000)) ||
      !Array.isArray(reasons) ||
      reasons.length < 2 ||
      reasons.length > 8 ||
      !reasons.every((v) => text(v, 2000)) ||
      !integer(c.answer, 0, choices.length - 1) ||
      !integer(c.reason, 0, reasons.length - 1) ||
      !text(c.knowledge ?? "", 10000, true) ||
      !text(c.source ?? "", 2000, true)
    )
      errors.push(
        "Kiểm tra nội dung, lựa chọn, lý do và đáp án đúng của bài trắc nghiệm.",
      );
  }
  if (lesson.mechanism !== "slideLesson") return errors;
  const slides = lesson.config.slides ?? [];
  if (
    lesson.config.schema_version !== 1 ||
    !slides.length ||
    slides.length > 12
  )
    errors.push("Bài học cần từ 1 đến 12 slide.");
  if (interactive && !slides.some((s) => s.engine !== "story"))
    errors.push("Thêm ít nhất một slide tương tác.");
  const ids = new Set<string>();
  slides.forEach((s, i) => {
    const c = s.config;
    let valid =
      /^[a-z][a-z0-9-]{0,79}$/.test(s.id) &&
      !ids.has(s.id) &&
      text(s.title, 160) &&
      text(s.prompt, 10000, s.engine === "story") &&
      text(s.hint, 3000, true) &&
      text(s.explanation, 10000, true);
    ids.add(s.id);
    switch (s.engine) {
      case "story": {
        valid &&=
          text(c.text, 10000) &&
          text(c.image_url, 2000, true) &&
          text(c.image_alt, 500, true);
        if (c.image_url) {
          try {
            const url = new URL(c.image_url);
            valid &&=
              url.protocol === "https:" &&
              !url.username &&
              !url.password &&
              !!c.image_alt?.trim();
          } catch {
            valid = false;
          }
        }
        break;
      }
      case "quiz":
        valid &&=
          !!c.choices &&
          c.choices.length >= 2 &&
          c.choices.length <= 8 &&
          c.choices.every((v) => text(v, 2000)) &&
          integer(c.answer, 0, c.choices.length - 1);
        break;
      case "pairs":
        valid &&=
          !!c.pairs &&
          c.pairs.length >= 2 &&
          c.pairs.length <= 6 &&
          c.pairs.every((p) => text(p.left, 1000) && text(p.right, 1000));
        break;
      case "graph":
        for (const axis of ["a", "b"] as const) {
          const min = c[`min_${axis}`]!,
            max = c[`max_${axis}`]!;
          valid &&=
            integer(min, -10, 10) &&
            integer(max, -10, 10) &&
            min < max &&
            integer(c[`start_${axis}`], min, max) &&
            integer(c[`target_${axis}`], min, max);
        }
        break;
      default:
        valid &&=
          s.engine in extendedEngines &&
          validExtended(s.engine as ExtendedEngine, c);
    }
    if (!valid)
      errors.push(
        `Slide ${i + 1}: kiểm tra nội dung, đáp án và giới hạn tương tác.`,
      );
  });
  return errors;
}
export function moveSlide(slides: Slide[], from: number, to: number) {
  if (from < 0 || to < 0 || from >= slides.length || to >= slides.length)
    return slides;
  const result = [...slides];
  result.splice(to, 0, result.splice(from, 1)[0]);
  return result;
}
export function correct(slide: Slide, state: Record<string, unknown>) {
  const c = slide.config;
  switch (slide.engine) {
    case "story":
      return state.ack === true;
    case "quiz":
      return state.answer === c.answer;
    case "pairs":
      return (
        Array.isArray(state.values) &&
        state.values.length === c.pairs!.length &&
        state.values.every((v, i) => v === i)
      );
    case "graph":
      return state.a === c.target_a && state.b === c.target_b;
    default:
      return correctExtended(slide.engine, c, state);
  }
}
