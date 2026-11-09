export const extraEngines = {
  numberLine: ["Trục số", "Đại số", "Đặt điểm tại giá trị mục tiêu."],
  fractionBoard: [
    "Tô phân số",
    "Đại số",
    "Tô các phần bằng nhau của một hình.",
  ],
  numberInput: ["Nhập kết quả", "Đại số", "Tự nhập đáp án số nguyên."],
  quadraticGraph: ["Đồ thị bậc hai", "Đại số", "Khám phá y = ax² + bx + c."],
  barChart: [
    "Dựng biểu đồ cột",
    "Khoa học",
    "Điều chỉnh các cột theo dữ liệu.",
  ],
  coordinatePoint: [
    "Tọa độ trên mặt phẳng",
    "Hình học",
    "Đặt điểm theo hai tọa độ.",
  ],
  vennDiagram: [
    "Sơ đồ Venn",
    "Tư duy",
    "Phân loại vào A, B, giao hoặc ngoài hai tập.",
  ],
  fractionCompare: [
    "So sánh phân số",
    "Đại số",
    "So sánh bằng hình trực quan.",
  ],
  shapeMatch: ["Nhận diện hình SVG", "Hình học", "Chọn hình giống mẫu."],
} as const;
export type ExtraEngine = keyof typeof extraEngines;
export type ExtraConfig = {
  min?: number;
  max?: number;
  start?: number;
  target?: number;
  denominator?: number;
  numerator?: number;
  target_value?: number;
  target_c?: number;
  labels?: string[];
  target_values?: number[];
  target_x?: number;
  target_y?: number;
  left_numerator?: number;
  left_denominator?: number;
  right_numerator?: number;
  right_denominator?: number;
  target_shape?: string;
};
export const shapes = ["circle", "triangle", "square", "hexagon"] as const;
export function extraConfig(e: ExtraEngine): ExtraConfig & {
  items?: string[];
  answer_values?: number[];
  target_a?: number;
  target_b?: number;
} {
  switch (e) {
    case "numberLine":
      return { min: -10, max: 10, start: 0, target: 4 };
    case "fractionBoard":
      return { denominator: 6, numerator: 4 };
    case "numberInput":
      return { target_value: 12 };
    case "quadraticGraph":
      return { target_a: 1, target_b: 0, target_c: -1 };
    case "barChart":
      return {
        labels: ["Nhóm A", "Nhóm B", "Nhóm C"],
        target_values: [2, 5, 3],
      };
    case "coordinatePoint":
      return { target_x: 3, target_y: 2 };
    case "vennDiagram":
      return {
        items: [
          "Chỉ thuộc A",
          "Chỉ thuộc B",
          "Thuộc cả hai",
          "Không thuộc tập nào",
        ],
        answer_values: [1, 2, 3, 0],
      };
    case "fractionCompare":
      return {
        left_numerator: 2,
        left_denominator: 3,
        right_numerator: 3,
        right_denominator: 4,
      };
    case "shapeMatch":
      return { target_shape: "triangle" };
  }
}
const int = (v: unknown, min: number, max: number): v is number =>
  typeof v === "number" && Number.isInteger(v) && v >= min && v <= max;
const nums = (a: unknown, min: number, max: number): a is number[] =>
  Array.isArray(a) && a.every((v) => int(v, min, max));
type Config = ExtraConfig & {
  target_a?: number;
  target_b?: number;
  items?: string[];
  answer_values?: number[];
};
export function validExtra(e: ExtraEngine, c: Config): boolean {
  switch (e) {
    case "numberLine":
      return (
        int(c.min, -100, 100) &&
        int(c.max, -100, 100) &&
        c.min < c.max &&
        c.max - c.min <= 100 &&
        int(c.start, c.min, c.max) &&
        int(c.target, c.min, c.max)
      );
    case "fractionBoard":
      return int(c.denominator, 2, 12) && int(c.numerator, 0, c.denominator);
    case "numberInput":
      return int(c.target_value, -10000, 10000);
    case "quadraticGraph":
      return (
        int(c.target_a, -3, 3) &&
        c.target_a !== 0 &&
        int(c.target_b, -5, 5) &&
        int(c.target_c, -5, 5)
      );
    case "barChart":
      return (
        Array.isArray(c.labels) &&
        c.labels.length >= 2 &&
        c.labels.length <= 6 &&
        c.labels.every(
          (v) =>
            typeof v === "string" && v.trim().length > 0 && v.length <= 100,
        ) &&
        nums(c.target_values, 0, 10) &&
        c.target_values.length === c.labels.length
      );
    case "coordinatePoint":
      return int(c.target_x, -5, 5) && int(c.target_y, -5, 5);
    case "vennDiagram":
      return (
        Array.isArray(c.items) &&
        c.items.length >= 2 &&
        c.items.length <= 8 &&
        c.items.every(
          (v) =>
            typeof v === "string" && v.trim().length > 0 && v.length <= 1000,
        ) &&
        nums(c.answer_values, 0, 3) &&
        c.answer_values.length === c.items.length
      );
    case "fractionCompare":
      return (
        int(c.left_denominator, 2, 12) &&
        int(c.right_denominator, 2, 12) &&
        int(c.left_numerator, 0, c.left_denominator) &&
        int(c.right_numerator, 0, c.right_denominator)
      );
    case "shapeMatch":
      return shapes.includes(c.target_shape as (typeof shapes)[number]);
  }
}
export function initialExtra(
  e: ExtraEngine,
  c: Config,
): Record<string, unknown> {
  switch (e) {
    case "numberLine":
      return { position: c.start };
    case "fractionBoard":
      return { selected: [] };
    case "numberInput":
      return { value: "" };
    case "quadraticGraph":
      return { a: 0, b: 0, c: 0 };
    case "barChart":
      return { values: c.labels!.map(() => 0) };
    case "coordinatePoint":
      return { x: 0, y: 0 };
    case "vennDiagram":
      return { values: c.items!.map(() => -1) };
    case "fractionCompare":
      return { comparison: -1 };
    case "shapeMatch":
      return { shape: "" };
  }
}
export function correctExtra(
  e: ExtraEngine,
  c: Config,
  s: Record<string, unknown>,
): boolean {
  switch (e) {
    case "numberLine":
      return int(s.position, c.min!, c.max!) && s.position === c.target;
    case "fractionBoard":
      return (
        nums(s.selected, 0, c.denominator! - 1) &&
        s.selected.length === c.numerator &&
        new Set(s.selected).size === s.selected.length
      );
    case "numberInput":
      return (
        typeof s.value === "string" &&
        s.value.length <= 6 &&
        /^-?\d+$/.test(s.value) &&
        Number(s.value) === c.target_value
      );
    case "quadraticGraph":
      return s.a === c.target_a && s.b === c.target_b && s.c === c.target_c;
    case "barChart":
      return (
        nums(s.values, 0, 10) &&
        s.values.length === c.target_values!.length &&
        s.values.every((v, i) => v === c.target_values![i])
      );
    case "coordinatePoint":
      return s.x === c.target_x && s.y === c.target_y;
    case "vennDiagram":
      return (
        nums(s.values, 0, 3) &&
        s.values.length === c.answer_values!.length &&
        s.values.every((v, i) => v === c.answer_values![i])
      );
    case "fractionCompare": {
      const l = c.left_numerator! * c.right_denominator!,
        r = c.right_numerator! * c.left_denominator!;
      return s.comparison === (l < r ? 0 : l === r ? 1 : 2);
    }
    case "shapeMatch":
      return s.shape === c.target_shape;
  }
}
