import { LessonIcon } from "./lesson-icons";
import { EnginePlayer } from "./EnginePlayer";
import { extendedEngines } from "./engine-contract";
import { useEffect, useState } from "react";
import {
  ArrowRight,
  Check,
  CheckCircle2,
  ChevronLeft,
  Lightbulb,
  RotateCcw,
  Smartphone,
} from "lucide-react";
import { correct, type Lesson, type Slide } from "./domain";
import katex from "katex";
import "katex/dist/katex.min.css";

export function RichText({ text }: { text: string }) {
  return (
    <>
      {text.split(/(\$[^$\n]+\$)/g).map((part, i) =>
        part.startsWith("$") && part.endsWith("$") ? (
          <span
            key={i}
            dangerouslySetInnerHTML={{
              __html: katex.renderToString(part.slice(1, -1), {
                throwOnError: false,
                trust: false,
                strict: "ignore",
                maxExpand: 100,
                maxSize: 10,
              }),
            }}
          />
        ) : (
          <span key={i}>{part}</span>
        ),
      )}
    </>
  );
}

export function Graph({
  a,
  b,
  onPoint,
}: {
  a: number;
  b: number;
  onPoint?: (a: number, b: number) => void;
}) {
  const point = (x: number, y: number) => `${160 + x * 22},${140 - y * 22}`;
  return (
    <svg
      className="graph-svg"
      viewBox="0 0 320 280"
      role="img"
      aria-label={`Đồ thị y = ${a}x + ${b}`}
    >
      <defs>
        <clipPath id="plot">
          <rect x="15" y="10" width="290" height="260" rx="12" />
        </clipPath>
      </defs>
      <g clipPath="url(#plot)">
        {Array.from({ length: 15 }, (_, i) => i - 7).map((n) => (
          <g key={n} stroke="#dde4db" strokeWidth="1">
            <line x1={160 + n * 22} y1="0" x2={160 + n * 22} y2="280" />
            <line x1="0" y1={140 + n * 22} x2="320" y2={140 + n * 22} />
          </g>
        ))}
        <path
          d="M 0 140 H 320 M 160 0 V 280"
          stroke="#83917f"
          strokeWidth="1.5"
        />
        <line
          x1="-60"
          y1={140 - (-10 * a + b) * 22}
          x2="380"
          y2={140 - (10 * a + b) * 22}
          stroke="#257549"
          strokeWidth="3.5"
          strokeLinecap="round"
        />
        {[0, 1].map((x) => (
          <circle
            key={x}
            cx={160 + x * 22}
            cy={140 - (a * x + b) * 22}
            r="6"
            fill="#c9f286"
            stroke="#257549"
            strokeWidth="2"
          />
        ))}
      </g>
      <text x="294" y="132">
        x
      </text>
      <text x="169" y="20">
        y
      </text>
      <text x="167" y="156" fontSize="10">
        0
      </text>
      <text x="265" y="156" fontSize="10">
        5
      </text>
      <text x="167" y="35" fontSize="10">
        5
      </text>
      {onPoint && (
        <g
          role="button"
          tabIndex={0}
          aria-label="Thử đường thẳng mẫu"
          onClick={() => onPoint(2, 1)}
          onKeyDown={(e) => e.key === "Enter" && onPoint(2, 1)}
        >
          <circle
            cx={point(0, 0).split(",")[0]}
            cy="140"
            r="12"
            fill="transparent"
          />
        </g>
      )}
    </svg>
  );
}

export function Interaction({
  slide,
  state,
  update,
  disabled = false,
}: {
  slide: Slide;
  state: Record<string, unknown>;
  update: (state: Record<string, unknown>) => void;
  disabled?: boolean;
}) {
  const c = slide.config;
  if (slide.engine in extendedEngines)
    return (
      <EnginePlayer
        slide={slide}
        state={state}
        update={update}
        disabled={disabled}
      />
    );
  if (slide.engine === "story")
    return (
      <div className="story-content">
        {c.image_url && (
          <img
            src={c.image_url}
            alt={c.image_alt}
            referrerPolicy="no-referrer"
            onError={(e) => {
              e.currentTarget.alt = `Không tải được ảnh: ${c.image_alt}`;
            }}
          />
        )}
        <div className="prose">
          <RichText text={c.text ?? ""} />
        </div>
        <label className="ack">
          <input
            type="checkbox"
            checked={!!state.ack}
            disabled={disabled}
            onChange={(e) => update({ ack: e.target.checked })}
          />{" "}
          Tôi đã sẵn sàng khám phá
        </label>
      </div>
    );
  if (slide.engine === "quiz")
    return (
      <div className="quiz-choices">
        {c.choices?.map((choice, i) => (
          <button
            key={i}
            className={`choice ${state.answer === i ? "picked" : ""}`}
            disabled={disabled}
            onClick={() => update({ answer: i })}
            aria-pressed={state.answer === i}
          >
            <span className="choice-letter">{String.fromCharCode(65 + i)}</span>
            <RichText text={choice} />
            {state.answer === i && <Check size={16} />}
          </button>
        ))}
      </div>
    );
  if (slide.engine === "graph") {
    const a = Number(state.a ?? c.start_a),
      b = Number(state.b ?? c.start_b);
    return (
      <div className="graph-interaction">
        <div className="graph-equation">
          y = <b>{a}</b>x {b >= 0 ? "+" : "−"} <b>{Math.abs(b)}</b>
        </div>
        <Graph a={a} b={b} />
        {(["a", "b"] as const).map((axis) => (
          <label className="range-row" key={axis}>
            <span>{axis}</span>
            <input
              aria-label={`Thay đổi ${axis}`}
              type="range"
              min={c[`min_${axis}`]}
              max={c[`max_${axis}`]}
              step="1"
              value={axis === "a" ? a : b}
              disabled={disabled}
              onChange={(e) => update({ a, b, [axis]: Number(e.target.value) })}
            />
            <output>{axis === "a" ? a : b}</output>
          </label>
        ))}
      </div>
    );
  }
  const pairs = c.pairs ?? [],
    values = (state.values as number[] | undefined) ?? pairs.map(() => -1);
  const options = pairs.map((p, i) => ({ text: p.right, index: i })).reverse();
  const assign = (row: number, value: number) =>
    update({
      values: values.map((v, i) =>
        i === row ? value : v === value && value !== -1 ? -1 : v,
      ),
    });
  return (
    <div className="pairs-interaction">
      <div className="pair-options">
        {options.map((o) => (
          <button
            key={o.index}
            className="pair-chip"
            draggable={!disabled}
            disabled={disabled}
            onDragStart={(e) =>
              e.dataTransfer.setData(
                "application/matlingo-answer",
                String(o.index),
              )
            }
            onClick={() => {
              const row = values.indexOf(-1);
              if (row !== -1) assign(row, o.index);
            }}
          >
            <RichText text={o.text} />
          </button>
        ))}
      </div>
      {pairs.map((p, row) => (
        <div className="pair-row" key={row}>
          <span>
            <RichText text={p.left} />
          </span>
          <ArrowRight size={14} />
          <div
            className={`pair-target ${values[row] !== -1 ? "assigned" : ""}`}
            onDragOver={(e) => e.preventDefault()}
            onDrop={(e) => {
              e.preventDefault();
              const raw = e.dataTransfer.getData("application/matlingo-answer");
              if (
                raw &&
                !disabled &&
                Number(raw) >= 0 &&
                Number(raw) < pairs.length
              )
                assign(row, Number(raw));
            }}
          >
            <select
              aria-label={`Ghép với ${p.left}`}
              disabled={disabled}
              value={values[row]}
              onChange={(e) => assign(row, Number(e.target.value))}
            >
              <option value={-1}>Kéo vào đây</option>
              {options.map((o) => (
                <option key={o.index} value={o.index}>
                  {o.text}
                </option>
              ))}
            </select>
          </div>
        </div>
      ))}
      <small>Kéo thả hoặc chọn đáp án trong từng ô.</small>
    </div>
  );
}

export function PhonePlayer({
  lesson,
  selected,
  follow,
}: {
  lesson: Lesson;
  selected: number;
  follow: boolean;
}) {
  const slides = lesson.config.slides ?? [];
  const [index, setIndex] = useState(0),
    [states, setStates] = useState<Record<string, Record<string, unknown>>>({});
  const [feedback, setFeedback] = useState(""),
    [done, setDone] = useState(false),
    [hint, setHint] = useState(false);
  const config = JSON.stringify(lesson.config);
  useEffect(() => {
    setStates({});
    setFeedback("");
    setDone(false);
    setHint(false);
  }, [config]);
  useEffect(() => {
    if (follow) {
      setIndex(selected);
      setFeedback("");
      setDone(false);
      setHint(false);
    }
  }, [selected, follow]);
  const safeIndex = Math.min(index, slides.length - 1),
    slide = slides[safeIndex];
  const changeIndex = (i: number) => {
    setIndex(i);
    setFeedback("");
    setHint(false);
  };
  return (
    <div className="phone-wrap">
      <div className="phone-device">
        <div className="phone-status">
          <span>9:41</span>
          <div className="dynamic-island" />
          <span>▮▮▮ ▰</span>
        </div>
        <div className="phone-scroll">
          {done ? (
            <div className="completion">
              <div className="celebration">
                <CheckCircle2 size={48} />
              </div>
              <span className="eyebrow">MỘT KHÁM PHÁ MỚI</span>
              <h2>Bạn làm được rồi!</h2>
              <p>Bạn vừa hoàn thành {slides.length} bước của bài học.</p>
              <button
                className="btn primary"
                onClick={() => {
                  setDone(false);
                  setStates({});
                  changeIndex(0);
                }}
              >
                <RotateCcw size={15} /> Chơi lại
              </button>
            </div>
          ) : slide ? (
            <>
              <div className="phone-lesson-top">
                <button
                  className="icon-btn"
                  aria-label="Bước trước"
                  disabled={safeIndex === 0}
                  onClick={() => changeIndex(safeIndex - 1)}
                >
                  <ChevronLeft size={17} />
                </button>
                <div className="lesson-progress">
                  {slides.map((s, i) => (
                    <span
                      key={s.id}
                      className={i <= safeIndex ? "filled" : ""}
                    />
                  ))}
                </div>
                <span>
                  {safeIndex + 1}/{slides.length}
                </span>
              </div>
              <div className="phone-lesson-icon">
                <LessonIcon lesson={lesson} size={34} />
                <span className="eyebrow">{lesson.stage || "KHÁM PHÁ"}</span>
              </div>
              <h2>
                <RichText text={slide.title} />
              </h2>
              {slide.prompt && (
                <p className="phone-prompt">
                  <RichText text={slide.prompt} />
                </p>
              )}
              <Interaction
                key={slide.id}
                slide={slide}
                state={states[slide.id] ?? {}}
                update={(s) => {
                  setStates((prev) => ({ ...prev, [slide.id]: s }));
                  setFeedback("");
                }}
              />
              {hint && (
                <div className="hint">
                  <Lightbulb size={15} />
                  <RichText
                    text={slide.hint || "Thử thay đổi từng yếu tố và quan sát."}
                  />
                </div>
              )}
              {feedback && (
                <div
                  className={`feedback ${feedback === "correct" ? "success" : ""}`}
                  role="status"
                >
                  {feedback === "correct" ? (
                    <>
                      <CheckCircle2 size={18} />
                      <span>
                        <strong>Chính xác!</strong>
                        <br />
                        <RichText text={slide.explanation} />
                      </span>
                    </>
                  ) : (
                    "Chưa đúng rồi. Hãy thử một ý tưởng khác nhé."
                  )}
                </div>
              )}
              <div className="phone-actions">
                <button
                  className="icon-btn"
                  aria-label="Xem gợi ý"
                  onClick={() => setHint(!hint)}
                >
                  <Lightbulb size={19} />
                </button>
                <button
                  className="btn primary"
                  onClick={() => {
                    if (feedback === "correct") {
                      if (safeIndex === slides.length - 1) setDone(true);
                      else changeIndex(safeIndex + 1);
                    } else
                      setFeedback(
                        correct(slide, states[slide.id] ?? {})
                          ? "correct"
                          : "wrong",
                      );
                  }}
                >
                  {feedback === "correct" ? "Tiếp tục" : "Kiểm tra"}
                  <ArrowRight size={15} />
                </button>
              </div>
            </>
          ) : (
            <div className="empty">
              <Smartphone size={30} />
              <p>Thả component vào trang để bắt đầu.</p>
            </div>
          )}
        </div>
        <div className="home-indicator" />
      </div>
      <p className="phone-caption">Bản mô phỏng · không ghi điểm người học</p>
    </div>
  );
}
