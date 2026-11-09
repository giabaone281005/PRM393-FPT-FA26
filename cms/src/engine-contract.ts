import {
  languageEngines,
  languageConfig,
  validLanguage,
  initialLanguage,
  correctLanguage,
  type LanguageConfig,
  type LanguageEngine,
} from "./language-engines";
import {
  extraEngines,
  extraConfig,
  validExtra,
  initialExtra,
  correctExtra,
  type ExtraConfig,
  type ExtraEngine,
} from "./extra-engines";
/** Declarative engine contract. No executable expressions are accepted. */
export const extendedEngines = {
  ...languageEngines,
  ...extraEngines,
  solid3D: ["Xưởng khối 3D", "Hình học", "Thay đổi kích thước và xoay khối."],
  polygonVertices: [
    "Đỉnh đa giác",
    "Hình học",
    "Kéo các đỉnh trên lưới 4 × 4.",
  ],
  symmetryMirror: ["Gương đối xứng", "Hình học", "Vẽ ảnh đối xứng qua trục."],
  tangramRotate: [
    "Ghép hình Tangram",
    "Hình học",
    "Xoay và ghép hai tam giác.",
  ],
  causalLab: [
    "Phòng lab nhân quả",
    "Đại số",
    "Dự đoán và kiểm chứng tích hai biến.",
  ],
  balanceScale: ["Cân thăng bằng", "Đại số", "Tìm khối lượng để cân hai bên."],
  robotRoute: [
    "Đường đi robot",
    "Lập trình",
    "Lập trình đường đi tránh chướng ngại vật.",
  ],
  loopBuilder: ["Xây vòng lặp", "Lập trình", "Ghép hai lệnh và số lần lặp."],
  sequenceTiles: [
    "Sắp xếp quy trình",
    "Lập trình",
    "Kéo thẻ theo đúng trình tự.",
  ],
  causalExperiment: [
    "Thí nghiệm khoa học",
    "Khoa học",
    "Thay từng biến, dự đoán rồi quan sát.",
  ],
  strata3D: ["Địa tầng 3D", "Khoa học", "Sắp xếp các lớp đá theo tuổi."],
  globe3D: ["Quả địa cầu", "Khoa học", "Khám phá kinh độ và vĩ độ."],
  resourceBudget: [
    "Phân bổ tài nguyên",
    "Khoa học",
    "Phân chia ngân sách có ràng buộc.",
  ],
  evidenceBoard: [
    "Bảng bằng chứng",
    "Tư duy",
    "Chọn bằng chứng hỗ trợ kết luận.",
  ],
  categorySort: ["Phân loại thẻ", "Tư duy", "Đưa từng thẻ vào nhóm phù hợp."],
  clozeBank: [
    "Điền chỗ trống",
    "Tư duy",
    "Hoàn thiện quy luật với ngân hàng từ.",
  ],
  matchPairs: ["Kết nối ý tưởng", "Tư duy", "Ghép các ý tưởng tương ứng."],
} as const;
export type ExtendedEngine = keyof typeof extendedEngines;
export type ExtendedConfig = ExtraConfig &
  LanguageConfig & {
    target_volume?: number;
    target_area?: number;
    target_weight?: number;
    target_product?: number;
    target_latitude?: number;
    target_longitude?: number;
    target_repeat?: number;
    target_body?: string[];
    max_commands?: number;
    items?: string[];
    choices?: string[];
    answer_values?: number[];
    minima?: number[];
    axes?: string[];
  };
export function extendedConfig(engine: ExtendedEngine): ExtendedConfig {
  if (engine in languageEngines)
    return languageConfig(engine as LanguageEngine);
  if (engine in extraEngines) return extraConfig(engine as ExtraEngine);
  switch (engine) {
    case "solid3D":
      return { target_volume: 12 };
    case "polygonVertices":
      return { target_area: 6 };
    case "symmetryMirror":
    case "tangramRotate":
    case "strata3D":
      return {};
    case "balanceScale":
      return { target_weight: 6 };
    case "robotRoute":
      return { max_commands: 32 };
    case "loopBuilder":
      return { target_repeat: 3, target_body: ["R", "D"] };
    case "globe3D":
      return { target_latitude: 30, target_longitude: 45 };
    case "causalLab":
    case "causalExperiment":
      return { target_product: 6, axes: ["Lực tác động", "Thời gian"] };
    case "sequenceTiles":
      return {
        items: ["Quan sát", "Đặt giả thuyết", "Kiểm chứng"],
        answer_values: [0, 1, 2],
      };
    case "resourceBudget":
      return { items: ["Năng lượng", "Nước", "Dự phòng"], minima: [3, 4, 1] };
    case "evidenceBoard":
      return {
        items: [
          "Thí nghiệm lặp lại cho cùng kết quả",
          "Một lời phỏng đoán",
          "Số liệu đo được",
        ],
        answer_values: [0, 2],
      };
    default:
      return {
        items: ["2 + 2", "3 + 3"],
        choices: ["4", "6"],
        answer_values: [0, 1],
      };
  }
}
const int = (v: unknown, min: number, max: number): v is number =>
  typeof v === "number" && Number.isInteger(v) && v >= min && v <= max;
const strings = (v: unknown, min = 2, max = 8): v is string[] =>
  Array.isArray(v) &&
  v.length >= min &&
  v.length <= max &&
  v.every(
    (x) => typeof x === "string" && x.trim().length > 0 && x.length <= 1000,
  );
const nums = (v: unknown, min: number, max: number): v is number[] =>
  Array.isArray(v) && v.every((x) => int(x, min, max));
const same = (a: unknown, b: unknown): boolean =>
  Array.isArray(a) &&
  Array.isArray(b) &&
  a.length === b.length &&
  a.every((x, i) => x === b[i]);
export function validExtended(
  engine: ExtendedEngine,
  c: ExtendedConfig,
): boolean {
  if (engine in languageEngines)
    return validLanguage(engine as LanguageEngine, c);
  if (engine in extraEngines) return validExtra(engine as ExtraEngine, c);
  switch (engine) {
    case "solid3D":
      return (
        int(c.target_volume, 1, 125) &&
        Array.from({ length: 5 }, (_, i) => i + 1).some((w) =>
          Array.from({ length: 5 }, (_, i) => i + 1).some((h) =>
            int(c.target_volume! / w / h, 1, 5),
          ),
        )
      );
    case "polygonVertices":
      return (
        int(c.target_area, 1, 16) &&
        [1, 2, 3, 4].some((w) => int(c.target_area! / w, 1, 4))
      );
    case "balanceScale":
      return int(c.target_weight, 0, 10);
    case "robotRoute":
      return int(c.max_commands, 6, 32);
    case "loopBuilder":
      return (
        int(c.target_repeat, 1, 4) &&
        Array.isArray(c.target_body) &&
        c.target_body.length === 2 &&
        c.target_body.every((x) => ["R", "D", "L", "U"].includes(x))
      );
    case "globe3D":
      return (
        int(c.target_latitude, -90, 90) &&
        int(c.target_longitude, -180, 180) &&
        c.target_latitude % 15 === 0 &&
        c.target_longitude % 15 === 0
      );
    case "causalLab":
    case "causalExperiment":
      return (
        int(c.target_product, 0, 9) &&
        [0, 1, 2, 3].some((x) =>
          [0, 1, 2, 3].some((y) => x * y === c.target_product),
        ) &&
        strings(c.axes, 2, 2)
      );
    case "symmetryMirror":
    case "tangramRotate":
    case "strata3D":
      return true;
    case "resourceBudget":
      return (
        strings(c.items, 2, 6) &&
        nums(c.minima, 0, 10) &&
        c.minima.length === c.items.length &&
        c.minima.reduce((a, b) => a + b, 0) <= 10
      );
    default: {
      if (!strings(c.items) || !nums(c.answer_values, 0, 7)) return false;
      const a = c.answer_values;
      if (engine === "evidenceBoard")
        return (
          a.length > 0 &&
          a.length <= c.items.length &&
          new Set(a).size === a.length &&
          a.every((x) => x < c.items!.length)
        );
      if (engine === "sequenceTiles")
        return (
          a.length === c.items.length &&
          new Set(a).size === a.length &&
          a.every((x) => x < c.items!.length)
        );
      return (
        strings(c.choices) &&
        a.length === c.items.length &&
        a.every((x) => x < c.choices!.length) &&
        (engine !== "matchPairs" || new Set(a).size === a.length)
      );
    }
  }
}
export function initialExtended(
  engine: ExtendedEngine,
  c: ExtendedConfig,
): Record<string, unknown> {
  if (engine in languageEngines)
    return initialLanguage(engine as LanguageEngine);
  if (engine in extraEngines) return initialExtra(engine as ExtraEngine, c);
  switch (engine) {
    case "solid3D":
      return { width: 2, height: 2, depth: 2 };
    case "polygonVertices":
      return {
        points: [
          [0, 0],
          [4, 0],
          [4, 4],
          [0, 4],
        ],
      };
    case "symmetryMirror":
      return { cells: [] };
    case "tangramRotate":
      return { turns: [1, 1], placed: [false, false] };
    case "robotRoute":
      return { commands: [] };
    case "loopBuilder":
      return { body: ["D", "R"], repeat: 1 };
    case "balanceScale":
      return { weight: 0 };
    case "causalLab":
    case "causalExperiment":
      return { x: 0, y: 0, prediction: -1, trials: [], observed: [] };
    case "globe3D":
      return { latitude: 0, longitude: 0 };
    case "strata3D":
      return { layers: [30, 10, 20] };
    case "evidenceBoard":
      return { selected: [] };
    case "sequenceTiles":
      return { values: c.items!.map((_, i) => i).reverse() };
    case "resourceBudget":
      return { values: c.items!.map(() => 0) };
    default:
      return { values: c.items!.map(() => -1) };
  }
}
export function correctExtended(
  engine: ExtendedEngine,
  c: ExtendedConfig,
  s: Record<string, unknown>,
): boolean {
  if (engine in languageEngines)
    return correctLanguage(engine as LanguageEngine, c, s);
  if (engine in extraEngines) return correctExtra(engine as ExtraEngine, c, s);
  switch (engine) {
    case "solid3D":
      return (
        [s.width, s.height, s.depth].every((x) => int(x, 1, 5)) &&
        Number(s.width) * Number(s.height) * Number(s.depth) === c.target_volume
      );
    case "balanceScale":
      return int(s.weight, 0, 10) && s.weight === c.target_weight;
    case "polygonVertices": {
      const p = s.points;
      if (
        !Array.isArray(p) ||
        p.length !== 4 ||
        !p.every((x) => nums(x, 0, 4) && x.length === 2)
      )
        return false;
      return (
        p[0][1] === p[1][1] &&
        p[1][0] === p[2][0] &&
        p[2][1] === p[3][1] &&
        p[3][0] === p[0][0] &&
        Math.abs((p[1][0] - p[0][0]) * (p[3][1] - p[0][1])) === c.target_area
      );
    }
    case "symmetryMirror":
      return (
        nums(s.cells, 0, 35) &&
        s.cells.length === 3 &&
        [11, 16, 23].every((x) => (s.cells as number[]).includes(x))
      );
    case "tangramRotate":
      return (
        nums(s.turns, 0, 3) &&
        s.turns.length === 2 &&
        Math.abs(s.turns[0] - s.turns[1]) === 2 &&
        same(s.placed, [true, true])
      );
    case "strata3D":
      return same(s.layers, [10, 20, 30]);
    case "globe3D":
      return (
        s.latitude === c.target_latitude && s.longitude === c.target_longitude
      );
    case "loopBuilder":
      return s.repeat === c.target_repeat && same(s.body, c.target_body);
    case "robotRoute": {
      if (!Array.isArray(s.commands) || s.commands.length > c.max_commands!)
        return false;
      let x = 0,
        y = 0;
      for (const command of s.commands) {
        if (!["R", "L", "D", "U"].includes(command)) return false;
        x += command === "R" ? 1 : command === "L" ? -1 : 0;
        y += command === "D" ? 1 : command === "U" ? -1 : 0;
        if (x < 0 || x > 3 || y < 0 || y > 3 || (x === 1 && y === 1))
          return false;
      }
      return x === 3 && y === 3;
    }
    case "causalLab":
    case "causalExperiment":
      return (
        int(s.x, 0, 3) &&
        int(s.y, 0, 3) &&
        s.x * s.y === c.target_product &&
        s.prediction === c.target_product &&
        same(s.observed, [s.x, s.y, c.target_product])
      );
    case "resourceBudget":
      return (
        nums(s.values, 0, 10) &&
        s.values.length === c.items!.length &&
        s.values.reduce((a, b) => a + b, 0) === 10 &&
        s.values.every((x, i) => x >= c.minima![i])
      );
    case "evidenceBoard":
      return (
        nums(s.selected, 0, 7) &&
        same(
          [...s.selected].sort((a, b) => a - b),
          [...c.answer_values!].sort((a, b) => a - b),
        )
      );
    default:
      return same(s.values, c.answer_values);
  }
}
