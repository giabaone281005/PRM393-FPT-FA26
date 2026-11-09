import type { Slide } from "./domain";
import {
  extraEngines,
  initialExtra,
  validExtra,
  shapes,
  type ExtraEngine,
} from "./extra-engines";
export const shapePath = (shape: string) =>
  shape === "circle" ? (
    <circle cx="50" cy="50" r="35" />
  ) : shape === "triangle" ? (
    <polygon points="50,10 90,85 10,85" />
  ) : shape === "square" ? (
    <rect x="15" y="15" width="70" height="70" />
  ) : (
    <polygon points="30,12 70,12 92,50 70,88 30,88 8,50" />
  );
export function ExtraEnginePlayer({
  slide,
  state,
  update,
  disabled = false,
}: {
  slide: Slide;
  state: Record<string, unknown>;
  update: (s: Record<string, unknown>) => void;
  disabled?: boolean;
}) {
  const e = slide.engine as ExtraEngine,
    c = slide.config;
  if (!(e in extraEngines) || !validExtra(e, c))
    return <p className="warning">Hoàn thiện cấu hình hợp lệ để chơi thử.</p>;
  const s = { ...initialExtra(e, c), ...state },
    set = (k: string, v: unknown) => update({ ...s, [k]: v });
  const range = (k: string, label: string, min: number, max: number) => (
    <label className="range-row" key={k}>
      <span>{label}</span>
      <input
        aria-label={label}
        type="range"
        min={min}
        max={max}
        step="1"
        disabled={disabled}
        value={Number(s[k])}
        onChange={(ev) => set(k, Number(ev.target.value))}
      />
      <output>{String(s[k])}</output>
    </label>
  );
  const fraction = (num: number, den: number) => (
    <div className="fraction-cells" role="img" aria-label={`${num}/${den}`}>
      {Array.from({ length: den }, (_, i) => (
        <span key={i} style={{ background: i < num ? "#9fce8b" : "#f5f7f2" }} />
      ))}
    </div>
  );
  if (e === "numberInput")
    return (
      <label className="field">
        Kết quả của bạn
        <input
          aria-label="Kết quả của bạn"
          inputMode="numeric"
          maxLength={6}
          disabled={disabled}
          value={String(s.value)}
          onChange={(ev) => set("value", ev.target.value)}
        />
      </label>
    );
  if (e === "numberLine")
    return (
      <div className="engine-play">
        <svg
          viewBox="0 0 300 90"
          role="img"
          aria-label={`Điểm tại ${s.position}`}
        >
          <path d="M15 45H285" stroke="#263d2b" strokeWidth="2" />
          <circle
            cx={15 + ((Number(s.position) - c.min!) / (c.max! - c.min!)) * 270}
            cy="45"
            r="9"
            fill="#16733e"
          />
          <text x="10" y="75">
            {c.min}
          </text>
          <text x="265" y="75">
            {c.max}
          </text>
        </svg>
        <p>Đặt điểm tại {c.target}.</p>
        {range("position", "Vị trí", c.min!, c.max!)}
      </div>
    );
  if (e === "fractionBoard") {
    const selected = s.selected as number[];
    return (
      <div>
        <p>
          Tô {c.numerator}/{c.denominator} hình.
        </p>
        <div className="fraction-cells">
          {Array.from({ length: c.denominator! }, (_, i) => (
            <button
              aria-label={`Phần ${i + 1}`}
              key={i}
              disabled={disabled}
              aria-pressed={selected.includes(i)}
              className={selected.includes(i) ? "picked" : ""}
              onClick={() =>
                set(
                  "selected",
                  selected.includes(i)
                    ? selected.filter((v) => v !== i)
                    : [...selected, i],
                )
              }
            >
              {i + 1}
            </button>
          ))}
        </div>
        <p>
          Đã tô {selected.length}/{c.denominator}.
        </p>
      </div>
    );
  }
  if (e === "fractionCompare")
    return (
      <div>
        {fraction(c.left_numerator!, c.left_denominator!)}
        <p>
          {c.left_numerator}/{c.left_denominator}
        </p>
        <div className="button-row">
          {["<", "=", ">"].map((v, i) => (
            <button
              key={v}
              disabled={disabled}
              aria-pressed={s.comparison === i}
              className={s.comparison === i ? "picked" : ""}
              onClick={() => set("comparison", i)}
            >
              {v}
            </button>
          ))}
        </div>
        <p>
          {c.right_numerator}/{c.right_denominator}
        </p>
        {fraction(c.right_numerator!, c.right_denominator!)}
      </div>
    );
  if (e === "shapeMatch")
    return (
      <div>
        <p>Tìm hình giống mẫu:</p>
        <svg
          viewBox="0 0 100 100"
          className="shape-sample"
          role="img"
          aria-label="Hình mẫu"
        >
          <g fill="#9fce8b" stroke="#234c32" strokeWidth="2">
            {shapePath(c.target_shape!)}
          </g>
        </svg>
        <div className="shape-options">
          {shapes.map((v) => (
            <button
              aria-label={`Chọn ${v}`}
              key={v}
              disabled={disabled}
              aria-pressed={s.shape === v}
              className={s.shape === v ? "picked" : ""}
              onClick={() => set("shape", v)}
            >
              <svg viewBox="0 0 100 100">
                <g fill="#c4d6eb" stroke="#34546b" strokeWidth="2">
                  {shapePath(v)}
                </g>
              </svg>
            </button>
          ))}
        </div>
      </div>
    );
  if (e === "barChart") {
    const values = s.values as number[];
    return (
      <div className="engine-play">
        <svg viewBox="0 0 300 220" role="img" aria-label="Biểu đồ cột">
          {values.map((v, i) => (
            <rect
              key={i}
              x={20 + (i * 260) / values.length}
              y={190 - v * 16}
              width={210 / values.length}
              height={v * 16}
              fill="#9fce8b"
              stroke="#467144"
            />
          ))}
          <path d="M10 10V191H290" stroke="#333" fill="none" />
        </svg>
        <p>Dựng dữ liệu: {c.target_values!.join(", ")}.</p>
        {c.labels!.map((label, i) => (
          <label className="range-row" key={i}>
            {label}
            <input
              aria-label={label}
              type="range"
              min="0"
              max="10"
              step="1"
              disabled={disabled}
              value={values[i]}
              onChange={(ev) =>
                set(
                  "values",
                  values.map((v, n) => (n === i ? Number(ev.target.value) : v)),
                )
              }
            />
            <output>{values[i]}</output>
          </label>
        ))}
      </div>
    );
  }
  if (e === "vennDiagram") {
    const values = s.values as number[];
    return (
      <div>
        <svg
          viewBox="0 0 300 180"
          role="img"
          aria-label="Hai tập A và B giao nhau"
        >
          <circle
            cx="110"
            cy="90"
            r="70"
            fill="#b2dba2"
            fillOpacity=".6"
            stroke="#45713b"
          />
          <circle
            cx="190"
            cy="90"
            r="70"
            fill="#b6cee8"
            fillOpacity=".6"
            stroke="#436383"
          />
          <text x="70" y="90">
            A
          </text>
          <text x="220" y="90">
            B
          </text>
        </svg>
        {c.items!.map((item, i) => (
          <label className="connection-option" key={i}>
            {item}
            <select
              aria-label={`Phân loại ${item}`}
              disabled={disabled}
              value={values[i]}
              onChange={(ev) =>
                set(
                  "values",
                  values.map((v, n) => (n === i ? Number(ev.target.value) : v)),
                )
              }
            >
              <option value={-1}>Chọn vùng</option>
              {["Ngoài A và B", "Chỉ A", "Chỉ B", "Giao A ∩ B"].map((v, n) => (
                <option key={n} value={n}>
                  {v}
                </option>
              ))}
            </select>
          </label>
        ))}
      </div>
    );
  }
  const isPoint = e === "coordinatePoint",
    a = Number(s.a),
    b = Number(s.b),
    cc = Number(s.c);
  return (
    <div className="engine-play">
      <svg
        viewBox="0 0 300 240"
        role="img"
        aria-label={isPoint ? "Mặt phẳng tọa độ" : "Đồ thị bậc hai"}
      >
        <defs>
          <clipPath id={`extra-${slide.id}`}>
            <rect width="300" height="240" />
          </clipPath>
        </defs>
        <g clipPath={`url(#extra-${slide.id})`}>
          <path d="M0 120H300M150 0V240" stroke="#8f9b8b" />
          {isPoint ? (
            <circle
              cx={150 + Number(s.x) * 25}
              cy={120 - Number(s.y) * 20}
              r="8"
              fill="#24693d"
            />
          ) : (
            <polyline
              points={Array.from({ length: 81 }, (_, i) => {
                const x = (i - 40) / 8;
                return `${150 + x * 25},${120 - (a * x * x + b * x + cc) * 12}`;
              }).join(" ")}
              fill="none"
              stroke="#24693d"
              strokeWidth="3"
            />
          )}
        </g>
      </svg>
      {isPoint ? (
        <>
          <p>
            Đặt điểm ({c.target_x}, {c.target_y}).
          </p>
          {range("x", "Tọa độ x", -5, 5)}
          {range("y", "Tọa độ y", -5, 5)}
        </>
      ) : (
        <>
          <p>
            y = {a}x² + {b}x + {cc}
          </p>
          <p>
            Tạo y = {c.target_a}x² + {c.target_b}x + {c.target_c}.
          </p>
          {range("a", "Hệ số a", -3, 3)}
          {range("b", "Hệ số b", -5, 5)}
          {range("c", "Hệ số c", -5, 5)}
        </>
      )}
    </div>
  );
}
