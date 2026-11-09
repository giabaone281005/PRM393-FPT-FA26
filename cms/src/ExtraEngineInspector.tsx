import type { Slide } from "./domain";
import { Field } from "./ui";
import { shapes } from "./extra-engines";
export function ExtraEngineInspector({
  slide,
  edit,
}: {
  slide: Slide;
  edit: (fn: (s: Slide) => void) => void;
}) {
  const c = slide.config,
    set = (k: string, v: unknown) =>
      edit((s) => {
        Object.assign(s.config, { [k]: v });
      });
  const num = (
    k: keyof Slide["config"],
    label: string,
    min: number,
    max: number,
  ) => (
    <Field
      key={k}
      label={label}
      type="number"
      min={min}
      maxNumber={max}
      value={Number(c[k] ?? 0)}
      onChange={(v) => set(k, Number(v))}
    />
  );
  switch (slide.engine) {
    case "numberLine":
      return (
        <>
          {num("min", "Giá trị nhỏ nhất", -100, 100)}
          {num("max", "Giá trị lớn nhất", -100, 100)}
          {num("start", "Vị trí ban đầu", -100, 100)}
          {num("target", "Vị trí mục tiêu", -100, 100)}
        </>
      );
    case "fractionBoard":
      return (
        <>
          {num("denominator", "Số phần bằng nhau", 2, 12)}
          {num("numerator", "Số phần cần tô", 0, 12)}
        </>
      );
    case "numberInput":
      return num("target_value", "Kết quả số nguyên đúng", -10000, 10000);
    case "quadraticGraph":
      return (
        <>
          {num("target_a", "Hệ số a mục tiêu (khác 0)", -3, 3)}
          {num("target_b", "Hệ số b mục tiêu", -5, 5)}
          {num("target_c", "Hệ số c mục tiêu", -5, 5)}
        </>
      );
    case "coordinatePoint":
      return (
        <>
          {num("target_x", "Tọa độ x mục tiêu", -5, 5)}
          {num("target_y", "Tọa độ y mục tiêu", -5, 5)}
        </>
      );
    case "barChart":
      return (
        <>
          <Field
            label="Tên các cột (mỗi dòng một cột)"
            area
            value={c.labels!.join("\n")}
            onChange={(v) => set("labels", v.split("\n"))}
          />
          <Field
            label="Giá trị mục tiêu các cột (0–10, cách nhau bằng dấu phẩy)"
            value={c.target_values!.join(", ")}
            onChange={(v) =>
              set(
                "target_values",
                v
                  .split(",")
                  .map((s) => (s.trim() === "" ? NaN : Number(s.trim()))),
              )
            }
          />
        </>
      );
    case "vennDiagram":
      return (
        <>
          <Field
            label="Nội dung các thẻ (mỗi dòng một thẻ)"
            area
            value={c.items!.join("\n")}
            onChange={(v) => set("items", v.split("\n"))}
          />
          <Field
            label="Vùng đúng từng thẻ (0: ngoài, 1: A, 2: B, 3: giao)"
            value={c.answer_values!.join(", ")}
            onChange={(v) =>
              set(
                "answer_values",
                v
                  .split(",")
                  .map((s) => (s.trim() === "" ? NaN : Number(s.trim()))),
              )
            }
          />
        </>
      );
    case "fractionCompare":
      return (
        <>
          {num("left_numerator", "Tử số bên trái", 0, 12)}
          {num("left_denominator", "Mẫu số bên trái", 2, 12)}
          {num("right_numerator", "Tử số bên phải", 0, 12)}
          {num("right_denominator", "Mẫu số bên phải", 2, 12)}
        </>
      );
    default:
      return (
        <label className="field">
          Hình mẫu
          <select
            value={c.target_shape}
            onChange={(e) => set("target_shape", e.target.value)}
          >
            {shapes.map((v) => (
              <option key={v} value={v}>
                {v}
              </option>
            ))}
          </select>
        </label>
      );
  }
}
