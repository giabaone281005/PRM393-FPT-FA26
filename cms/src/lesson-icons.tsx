import { useState } from "react";
import {
  BookOpen,
  Calculator,
  Coins,
  Shapes,
  Box,
  ChartColumn,
  Divide,
  Ruler,
  Compass,
  Puzzle,
  Headphones,
  Mic,
  Languages,
  PenLine,
  Globe,
  MessageCircle,
  Bot,
  CodeXml,
  Repeat2,
  Route,
  Terminal,
  Bug,
  Lightbulb,
  Trophy,
  type LucideIcon,
} from "lucide-react";
import type { Lesson } from "./domain";

export const lessonIcons: Record<
  string,
  { label: string; icon: LucideIcon; group: string }
> = {
  book: { label: "Sách", icon: BookOpen, group: "Chung" },
  calculator: { label: "Máy tính", icon: Calculator, group: "Toán học" },
  coins: { label: "Ngân sách", icon: Coins, group: "Toán học" },
  shapes: { label: "Hình học", icon: Shapes, group: "Toán học" },
  cube: { label: "Khối 3D", icon: Box, group: "Toán học" },
  chart: { label: "Biểu đồ", icon: ChartColumn, group: "Toán học" },
  fraction: { label: "Phân số", icon: Divide, group: "Toán học" },
  ruler: { label: "Đo lường", icon: Ruler, group: "Toán học" },
  compass: { label: "Compa", icon: Compass, group: "Toán học" },
  puzzle: { label: "Ghép hình", icon: Puzzle, group: "Chung" },
  headphones: { label: "Luyện nghe", icon: Headphones, group: "Ngôn ngữ" },
  microphone: { label: "Luyện nói", icon: Mic, group: "Ngôn ngữ" },
  alphabet: { label: "Ngôn ngữ", icon: Languages, group: "Ngôn ngữ" },
  pen: { label: "Luyện viết", icon: PenLine, group: "Ngôn ngữ" },
  globe: { label: "Thế giới", icon: Globe, group: "Chung" },
  chat: { label: "Hội thoại", icon: MessageCircle, group: "Ngôn ngữ" },
  robot: { label: "Robot", icon: Bot, group: "Lập trình" },
  code: { label: "Lập trình", icon: CodeXml, group: "Lập trình" },
  loop: { label: "Vòng lặp", icon: Repeat2, group: "Lập trình" },
  route: { label: "Thuật toán", icon: Route, group: "Lập trình" },
  terminal: { label: "Dòng lệnh", icon: Terminal, group: "Lập trình" },
  bug: { label: "Sửa lỗi", icon: Bug, group: "Lập trình" },
  lightbulb: { label: "Ý tưởng", icon: Lightbulb, group: "Chung" },
  trophy: { label: "Thử thách", icon: Trophy, group: "Chung" },
};
const engineIcon: Record<string, string> = {
  resourceBudget: "coins",
  numberLine: "calculator",
  numberInput: "calculator",
  fractionBoard: "fraction",
  fractionCompare: "fraction",
  polygonVertices: "shapes",
  shapeMatch: "shapes",
  symmetryMirror: "shapes",
  solid3D: "cube",
  graph: "chart",
  quadraticGraph: "chart",
  barChart: "chart",
  listeningChoice: "headphones",
  speechPractice: "microphone",
  textEntry: "pen",
  clozeBank: "alphabet",
  robotRoute: "robot",
  loopBuilder: "loop",
  categorySort: "code",
  vennDiagram: "code",
};
export function lessonIconKey(lesson: Pick<Lesson, "config">): string {
  const key = lesson.config.lesson_icon;
  if (typeof key === "string" && Object.hasOwn(lessonIcons, key)) return key;
  const slides = lesson.config.slides;
  const engine = Array.isArray(slides)
    ? (slides.find((s) => s.engine !== "story")?.engine ?? "")
    : "";
  return engineIcon[engine] ?? "book";
}
export function LessonIcon({
  lesson,
  size = 28,
}: {
  lesson: Pick<Lesson, "config">;
  size?: number;
}) {
  const entry = lessonIcons[lessonIconKey(lesson)],
    Icon = entry.icon;
  return (
    <Icon
      size={size}
      strokeWidth={1.7}
      aria-label={`Icon bài học: ${entry.label}`}
      role="img"
    />
  );
}
const normalise = (s: string) =>
  s
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replaceAll("đ", "d");
export function LessonIconPicker({
  lesson,
  onChange,
}: {
  lesson: Lesson;
  onChange: (key: string | undefined) => void;
}) {
  const [query, setQuery] = useState("");
  const explicit =
    typeof lesson.config.lesson_icon === "string" &&
    Object.hasOwn(lessonIcons, lesson.config.lesson_icon)
      ? lesson.config.lesson_icon
      : undefined;
  const entries = Object.entries(lessonIcons).filter(([key, v]) =>
    normalise(`${key} ${v.label} ${v.group}`).includes(normalise(query)),
  );
  return (
    <section className="lesson-icon-picker" aria-label="Icon bài học">
      <div className="lesson-icon-preview">
        <LessonIcon lesson={lesson} size={38} />
        <div>
          <strong>Icon bài học</strong>
          <small>
            {lessonIcons[lessonIconKey(lesson)].label}
            {explicit ? "" : " · Tự động"}
          </small>
        </div>
      </div>
      <details>
        <summary>Chọn icon bài học</summary>
        <label className="field">
          Tìm icon
          <input
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Robot, phân số, nghe…"
          />
        </label>
        <button
          type="button"
          aria-pressed={!explicit}
          onClick={() => onChange(undefined)}
        >
          Tự động theo engine
        </button>
        <div className="lesson-icon-grid" aria-label="Các icon có sẵn">
          {entries.map(([key, { label, icon: Icon }]) => (
            <button
              key={key}
              type="button"
              aria-label={`Chọn icon ${label}`}
              aria-pressed={explicit === key}
              title={label}
              onClick={() => onChange(key)}
            >
              <Icon size={26} aria-hidden="true" />
              <span>{label}</span>
            </button>
          ))}
        </div>
        {!entries.length && <small>Thử tìm theo tên hoặc lĩnh vực.</small>}
      </details>
      <small>Lưu và phát hành để đồng bộ icon vào app.</small>
    </section>
  );
}
