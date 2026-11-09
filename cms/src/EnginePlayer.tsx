import { LanguageEnginePlayer } from "./LanguageEnginePlayer";
import { languageEngines } from "./language-engines";
import { ExtraEnginePlayer } from "./ExtraEnginePlayer";
import { extraEngines } from "./extra-engines";
import { useState } from "react";
import { ArrowDown, ArrowUp, RotateCcw } from "lucide-react";
import type { Slide } from "./domain";
import {
  initialExtended,
  validExtended,
  type ExtendedEngine,
} from "./engine-contract";

export function EnginePlayer({
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
  const e = slide.engine as ExtendedEngine,
    c = slide.config;
  const s = { ...(validExtended(e, c) ? initialExtended(e, c) : {}), ...state };
  const [yaw, setYaw] = useState(-0.55),
    [vertex, setVertex] = useState(0);
  if (e in languageEngines)
    return (
      <LanguageEnginePlayer
        slide={slide}
        state={s}
        update={update}
        disabled={disabled}
      />
    );
  if (e in extraEngines)
    return (
      <ExtraEnginePlayer
        slide={slide}
        state={state}
        update={update}
        disabled={disabled}
      />
    );
  if (!validExtended(e, c))
    return (
      <p className="warning">
        Hoàn thiện cấu hình hợp lệ để chơi thử engine này.
      </p>
    );
  const change = (key: string, value: unknown) =>
    update({ ...s, [key]: value });
  const range = (
    key: string,
    label: string,
    min: number,
    max: number,
    step = 1,
  ) => (
    <label className="range-row" key={key}>
      <span>{label}</span>
      <input
        aria-label={label}
        disabled={disabled}
        type="range"
        min={min}
        max={max}
        step={step}
        value={Number(s[key])}
        onChange={(ev) => change(key, Number(ev.target.value))}
      />
      <output>{String(s[key])}</output>
    </label>
  );
  const values = (s.values ?? []) as number[];
  const reorder = (key: string, from: number, to: number) => {
    const next = [...(s[key] as number[])];
    next.splice(to, 0, next.splice(from, 1)[0]);
    change(key, next);
  };
  if (e === "solid3D") {
    const w = Number(s.width),
      h = Number(s.height),
      d = Number(s.depth);
    const p = (x: number, y: number, z: number) => {
      const xx = x * Math.cos(yaw) - z * Math.sin(yaw),
        zz = x * Math.sin(yaw) + z * Math.cos(yaw);
      return `${150 + xx * 23},${125 - y * 23 + zz * 9}`;
    };
    const face = (points: number[][]) =>
      points.map((v) => p(v[0], v[1], v[2])).join(" ");
    return (
      <div className="engine-play">
        <svg
          viewBox="0 0 300 240"
          role="img"
          aria-label={`Khối hộp ${w} × ${h} × ${d}`}
        >
          <polygon
            points={face([
              [0, 0, 0],
              [w, 0, 0],
              [w, h, 0],
              [0, h, 0],
            ])}
            fill="#b7e9ca"
            stroke="#16733e"
          />
          <polygon
            points={face([
              [w, 0, 0],
              [w, 0, d],
              [w, h, d],
              [w, h, 0],
            ])}
            fill="#75c49d"
            stroke="#16733e"
          />
          <polygon
            points={face([
              [0, h, 0],
              [w, h, 0],
              [w, h, d],
              [0, h, d],
            ])}
            fill="#e0f8b2"
            stroke="#16733e"
          />
        </svg>
        <p>
          Thể tích: <b>{w * h * d}</b> · Mục tiêu: {c.target_volume}
        </p>
        {range("width", "Dài", 1, 5)}
        {range("height", "Cao", 1, 5)}
        {range("depth", "Sâu", 1, 5)}
        <label className="range-row">
          Xoay khối
          <input
            aria-label="Xoay khối"
            disabled={disabled}
            type="range"
            min="-3.14"
            max="3.14"
            step="0.05"
            value={yaw}
            onChange={(ev) => setYaw(Number(ev.target.value))}
          />
        </label>
      </div>
    );
  }
  if (e === "robotRoute" || e === "loopBuilder") {
    const body = s.body as string[],
      commands =
        e === "robotRoute"
          ? (s.commands as string[])
          : Array.from({ length: Number(s.repeat) }, () => body).flat();
    let x = 0,
      y = 0,
      invalid = false;
    for (const cmd of commands) {
      x += cmd === "R" ? 1 : cmd === "L" ? -1 : 0;
      y += cmd === "D" ? 1 : cmd === "U" ? -1 : 0;
      if (
        x < 0 ||
        y < 0 ||
        x > 3 ||
        y > 3 ||
        (e === "robotRoute" && x === 1 && y === 1)
      )
        invalid = true;
    }
    const arrows: Record<string, string> = { R: "→", D: "↓", L: "←", U: "↑" };
    return (
      <div className="engine-play">
        <div
          className="robot-grid"
          role="img"
          aria-label="Bản đồ robot 4 nhân 4"
        >
          {Array.from({ length: 16 }, (_, i) => (
            <span
              key={i}
              className={i === 5 && e === "robotRoute" ? "obstacle" : ""}
            >
              {x === i % 4 && y === Math.floor(i / 4)
                ? "🤖"
                : i === 15
                  ? "★"
                  : i === 5 && e === "robotRoute"
                    ? "■"
                    : "·"}
            </span>
          ))}
        </div>
        {invalid && (
          <p className="warning">
            Robot va chạm hoặc ra khỏi bản đồ. Hãy sửa lệnh.
          </p>
        )}
        <p className="command-strip">
          {commands.map((v) => arrows[v]).join(" ") || "Thêm lệnh để bắt đầu"}
        </p>
        {e === "robotRoute" ? (
          <>
            <div className="button-row">
              {["L", "U", "D", "R"].map((cmd) => (
                <button
                  key={cmd}
                  aria-label={`Lệnh ${cmd}`}
                  disabled={disabled || commands.length >= c.max_commands!}
                  onClick={() => change("commands", [...commands, cmd])}
                >
                  {arrows[cmd]}
                </button>
              ))}
            </div>
            <button
              disabled={disabled}
              onClick={() => change("commands", commands.slice(0, -1))}
            >
              Lùi một lệnh
            </button>
            <small>
              {commands.length}/{c.max_commands} lệnh
            </small>
          </>
        ) : (
          <>
            <div className="button-row">
              {body.map((cmd, i) => (
                <label key={i}>
                  Lệnh {i + 1}
                  <select
                    aria-label={`Lệnh lặp ${i + 1}`}
                    disabled={disabled}
                    value={cmd}
                    onChange={(ev) =>
                      change(
                        "body",
                        body.map((v, n) => (n === i ? ev.target.value : v)),
                      )
                    }
                  >
                    {Object.entries(arrows).map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                </label>
              ))}
            </div>
            {range("repeat", "Số lần lặp", 1, 4)}
            <small>
              Chọn hai lệnh {c.target_body?.map((v) => arrows[v]).join(" ")} và
              lặp {c.target_repeat} lần.
            </small>
          </>
        )}
      </div>
    );
  }
  if (e === "sequenceTiles" || e === "strata3D") {
    const key = e === "strata3D" ? "layers" : "values",
      order = s[key] as number[];
    return (
      <div className="sequence-play">
        <p>
          {e === "strata3D"
            ? "Xếp tuổi đá từ trẻ đến già: 10 → 20 → 30."
            : "Kéo các thẻ để sắp xếp quy trình."}
        </p>
        {order.map((v, i) => (
          <div
            className="sequence-tile"
            key={v}
            draggable={!disabled}
            onDragStart={(ev) =>
              ev.dataTransfer.setData("text/x-sequence", String(i))
            }
            onDragOver={(ev) => ev.preventDefault()}
            onDrop={(ev) => {
              ev.preventDefault();
              const from = ev.dataTransfer.getData("text/x-sequence");
              if (
                !disabled &&
                /^\d+$/.test(from) &&
                Number(from) < order.length
              )
                reorder(key, Number(from), i);
            }}
          >
            <span>{i + 1}</span>
            <strong>{e === "strata3D" ? `${v} triệu năm` : c.items![v]}</strong>
            <button
              aria-label={`Đưa thẻ ${i + 1} lên`}
              disabled={disabled || i === 0}
              onClick={() => reorder(key, i, i - 1)}
            >
              <ArrowUp size={14} />
            </button>
            <button
              aria-label={`Đưa thẻ ${i + 1} xuống`}
              disabled={disabled || i === order.length - 1}
              onClick={() => reorder(key, i, i + 1)}
            >
              <ArrowDown size={14} />
            </button>
          </div>
        ))}
      </div>
    );
  }
  if (e === "polygonVertices") {
    const points = s.points as number[][];
    const move = (axis: number, value: number) =>
      change(
        "points",
        points.map((p, i) =>
          i === vertex ? p.map((v, a) => (a === axis ? value : v)) : p,
        ),
      );
    return (
      <div className="engine-play">
        <svg viewBox="0 0 240 240" role="img" aria-label="Đa giác trên lưới">
          <path
            d={Array.from(
              { length: 5 },
              (_, i) => `M ${20 + i * 50} 20 V 220 M 20 ${20 + i * 50} H 220`,
            ).join(" ")}
            stroke="#ddd"
            fill="none"
          />
          <polygon
            points={points
              .map((p) => `${20 + p[0] * 50},${220 - p[1] * 50}`)
              .join(" ")}
            fill="#b7e9ca"
            stroke="#16733e"
          />
          {points.map((p, i) => (
            <circle
              key={i}
              cx={20 + p[0] * 50}
              cy={220 - p[1] * 50}
              r="8"
              fill={vertex === i ? "#111" : "#16733e"}
              onPointerDown={() => setVertex(i)}
            />
          ))}
        </svg>
        <label>
          Chọn đỉnh
          <select
            aria-label="Chọn đỉnh"
            value={vertex}
            onChange={(ev) => setVertex(Number(ev.target.value))}
          >
            {points.map((_, i) => (
              <option key={i} value={i}>
                {i + 1}
              </option>
            ))}
          </select>
        </label>
        {["x", "y"].map((axis, i) => (
          <label className="range-row" key={axis}>
            {axis}
            <input
              type="range"
              aria-label={`Đỉnh ${axis}`}
              disabled={disabled}
              min="0"
              max="4"
              value={points[vertex][i]}
              onChange={(ev) => move(i, Number(ev.target.value))}
            />
            <output>{points[vertex][i]}</output>
          </label>
        ))}
        <p>Tạo hình chữ nhật có diện tích {c.target_area}.</p>
      </div>
    );
  }
  if (e === "symmetryMirror") {
    const selected = s.cells as number[],
      source = [6, 13, 18];
    return (
      <div>
        <p>Chọn các ô bên phải để phản chiếu hình qua trục giữa.</p>
        <div className="mirror-grid">
          {Array.from({ length: 36 }, (_, i) => (
            <button
              key={i}
              aria-label={`Ô gương ${i}`}
              disabled={disabled || i % 6 < 3}
              aria-pressed={selected.includes(i)}
              className={
                source.includes(i)
                  ? "source"
                  : selected.includes(i)
                    ? "picked"
                    : ""
              }
              onClick={() =>
                change(
                  "cells",
                  selected.includes(i)
                    ? selected.filter((v) => v !== i)
                    : [...selected, i],
                )
              }
            >
              {source.includes(i) || selected.includes(i) ? "●" : "·"}
            </button>
          ))}
        </div>
      </div>
    );
  }
  if (e === "tangramRotate") {
    const turns = s.turns as number[],
      placed = s.placed as boolean[];
    return (
      <div>
        <p>Xoay hai tam giác lệch nhau nửa vòng rồi đặt cả hai vào khung.</p>
        <div className="tangram-pieces">
          {turns.map((t, i) => (
            <div key={i}>
              <svg
                viewBox="0 0 100 100"
                role="img"
                aria-label={`Tam giác ${i + 1}, góc ${t * 90} độ`}
              >
                <polygon
                  points="15,15 85,15 15,85"
                  fill={i === 0 ? "#b7e9ca" : "#b9b2eb"}
                  stroke="#333"
                  transform={`rotate(${t * 90} 50 50)`}
                />
              </svg>
              <button
                disabled={disabled}
                onClick={() =>
                  change(
                    "turns",
                    turns.map((v, n) => (n === i ? (v + 1) % 4 : v)),
                  )
                }
              >
                <RotateCcw size={14} /> Xoay {i + 1}
              </button>
              <label>
                <input
                  type="checkbox"
                  disabled={disabled}
                  checked={placed[i]}
                  onChange={(ev) =>
                    change(
                      "placed",
                      placed.map((v, n) => (n === i ? ev.target.checked : v)),
                    )
                  }
                />
                Đặt vào khung
              </label>
            </div>
          ))}
        </div>
      </div>
    );
  }
  if (e === "balanceScale")
    return (
      <div className="engine-play">
        <svg viewBox="0 0 300 160" role="img" aria-label="Cân hai đĩa">
          <path
            d={`M 150 140 V 50 M 40 ${50 + Number(s.weight) * 3 - c.target_weight! * 3} L 260 ${50 - Number(s.weight) * 3 + c.target_weight! * 3}`}
            stroke="#333"
            strokeWidth="5"
          />
          <path
            d="M 15 90 Q 40 140 65 90 M 235 90 Q 260 140 285 90"
            fill="#b7e9ca"
            stroke="#16733e"
          />
          <text x="35" y="85">
            {String(s.weight)}
          </text>
          <text x="250" y="85">
            {c.target_weight}
          </text>
        </svg>
        {range("weight", "Khối lượng", 0, 10)}
      </div>
    );
  if (e === "globe3D")
    return (
      <div className="engine-play">
        <svg viewBox="0 0 240 240" role="img" aria-label="Quả địa cầu">
          <circle cx="120" cy="120" r="95" fill="#d4eaf5" stroke="#37738e" />
          {[-60, -30, 0, 30, 60].map((n) => (
            <ellipse
              key={n}
              cx="120"
              cy={120 - n}
              rx={Math.sqrt(95 * 95 - n * n)}
              ry="12"
              fill="none"
              stroke="#6b9eae"
            />
          ))}
          <ellipse
            cx="120"
            cy="120"
            rx="45"
            ry="95"
            fill="none"
            stroke="#6b9eae"
          />
          <circle
            cx={
              120 +
              80 *
                Math.sin((Number(s.longitude) * Math.PI) / 180) *
                Math.cos((Number(s.latitude) * Math.PI) / 180)
            }
            cy={120 - 80 * Math.sin((Number(s.latitude) * Math.PI) / 180)}
            r="7"
            fill="#ac3939"
          />
        </svg>
        {range("latitude", "Vĩ độ", -90, 90, 15)}
        {range("longitude", "Kinh độ", -180, 180, 15)}
        <p>
          Tìm tọa độ ({c.target_latitude}°, {c.target_longitude}°).
        </p>
      </div>
    );
  if (e === "causalLab" || e === "causalExperiment")
    return (
      <div>
        {range("x", c.axes![0], 0, 3)}
        {range("y", c.axes![1], 0, 3)}
        <label>
          Dự đoán
          <input
            aria-label="Dự đoán"
            type="number"
            min="0"
            max="9"
            disabled={disabled}
            value={Number(s.prediction)}
            onChange={(ev) => change("prediction", Number(ev.target.value))}
          />
        </label>
        <button
          disabled={disabled || Number(s.prediction) < 0}
          onClick={() =>
            update({
              ...s,
              observed: [s.x, s.y, Number(s.x) * Number(s.y)],
              trials: [
                ...(s.trials as number[][]),
                [Number(s.x), Number(s.y), Number(s.x) * Number(s.y)],
              ].slice(-6),
            })
          }
        >
          Chạy mô hình
        </button>
        <p>Tìm tích {c.target_product}, dự đoán trước khi chạy.</p>
        {(s.trials as number[][]).map((t, i) => (
          <p key={i}>
            {t[0]} × {t[1]} → {t[2]}
          </p>
        ))}
      </div>
    );
  if (e === "evidenceBoard")
    return (
      <div>
        {c.items!.map((item, i) => (
          <label className="evidence-option" key={i}>
            <input
              type="checkbox"
              disabled={disabled}
              checked={(s.selected as number[]).includes(i)}
              onChange={(ev) =>
                change(
                  "selected",
                  ev.target.checked
                    ? [...(s.selected as number[]), i]
                    : (s.selected as number[]).filter((v) => v !== i),
                )
              }
            />
            {item}
          </label>
        ))}
      </div>
    );
  if (e === "resourceBudget")
    return (
      <div>
        <p>
          Phân bổ đúng 10 đơn vị · Đã dùng {values.reduce((a, b) => a + b, 0)}
          /10
        </p>
        {c.items!.map((item, i) => (
          <label className="range-row" key={i}>
            <span>
              {item} (≥ {c.minima![i]})
            </span>
            <input
              type="range"
              min="0"
              max="10"
              aria-label={item}
              disabled={disabled}
              value={values[i]}
              onChange={(ev) =>
                change(
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
  return (
    <div>
      {c.items!.map((item, i) => (
        <label className="connection-option" key={i}>
          {item}
          <select
            aria-label={`Chọn cho ${item}`}
            value={values[i]}
            disabled={disabled}
            onChange={(ev) =>
              change(
                "values",
                values.map((v, n) => (n === i ? Number(ev.target.value) : v)),
              )
            }
          >
            <option value={-1}>Chọn đáp án</option>
            {c.choices!.map((v, n) => (
              <option value={n} key={n}>
                {v}
              </option>
            ))}
          </select>
        </label>
      ))}
    </div>
  );
}
