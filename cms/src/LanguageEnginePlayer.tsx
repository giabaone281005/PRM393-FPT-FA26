import { useEffect, useRef, useState } from "react";
import type { Slide } from "./domain";
import { validLanguage, type LanguageEngine } from "./language-engines";

// Recognition is optional in browsers; mobile uses the installed native plugin.
type Recognition = {
  lang: string;
  start(): void;
  abort(): void;
  onresult:
    | ((event: {
        results: { [i: number]: { [i: number]: { transcript: string } } };
      }) => void)
    | null;
  onerror: (() => void) | null;
  onend: (() => void) | null;
};
export function LanguageEnginePlayer({
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
  const [transcript, setTranscript] = useState(false),
    [message, setMessage] = useState("");
  const recognition = useRef<Recognition | null>(null);
  const spoken = useRef<SpeechSynthesisUtterance | null>(null);
  const latest = useRef({ state, update });
  latest.current = { state, update };
  const stop = () => {
    if (recognition.current) {
      recognition.current.onresult = null;
      recognition.current.onerror = null;
      recognition.current.onend = null;
      recognition.current.abort();
      recognition.current = null;
    }
    if (spoken.current) {
      spoken.current.onend = null;
      spoken.current.onerror = null;
      spoken.current = null;
    }
    window.speechSynthesis?.cancel();
  };
  useEffect(
    () => () => {
      stop();
    },
    [slide.id, disabled],
  );
  if (!validLanguage(slide.engine as LanguageEngine, slide.config))
    return <p>Hoàn thiện cấu hình ngôn ngữ để chơi thử.</p>;
  const c = slide.config,
    listening = slide.engine === "listeningChoice",
    writing = slide.engine === "textEntry";
  const change = (s: Record<string, unknown>) => {
    const value = { ...latest.current.state, ...s };
    latest.current.state = value;
    latest.current.update(value);
  };
  function speak(slow: boolean) {
    if (!window.speechSynthesis) {
      setMessage("Âm thanh chưa sẵn sàng. Bạn có thể mở bản chữ.");
      return;
    }
    stop();
    const utterance = new SpeechSynthesisUtterance(c.text!);
    spoken.current = utterance;
    utterance.lang = "en-US";
    utterance.rate = slow ? 0.65 : 1;
    utterance.onend = () => {
      if (listening) change({ experienced: true });
    };
    utterance.onerror = () =>
      setMessage("Chưa phát được âm thanh. Bạn có thể mở bản chữ.");
    window.speechSynthesis.speak(utterance);
  }
  function listen() {
    const host = window as unknown as {
      SpeechRecognition?: new () => Recognition;
      webkitSpeechRecognition?: new () => Recognition;
    };
    const Factory = host.SpeechRecognition ?? host.webkitSpeechRecognition;
    if (!Factory) {
      setMessage(
        "Trình duyệt chưa hỗ trợ nhận giọng nói. Hãy nhập câu bên dưới hoặc thử trên mobile.",
      );
      return;
    }
    stop();
    const r = new Factory();
    recognition.current = r;
    r.lang = "en-US";
    r.onresult = (event) => {
      change({ response: event.results[0][0].transcript.slice(0, 500) });
      setMessage("");
    };
    r.onerror = () =>
      setMessage("Micro chưa sẵn sàng. Bạn vẫn có thể nhập câu.");
    r.onend = () => {
      recognition.current = null;
    };
    setMessage("Đang nghe…");
    try {
      r.start();
    } catch {
      setMessage("Chưa mở được micro.");
    }
  }
  return (
    <div className="engine-workspace">
      {!writing && (
        <>
          <div className="button-row">
            <button disabled={disabled} onClick={() => speak(false)}>
              Nghe mẫu
            </button>
            <button disabled={disabled} onClick={() => speak(true)}>
              Nghe chậm
            </button>
          </div>
          {(!listening || transcript) && <p lang="en">{c.text}</p>}
          {listening && (
            <button
              disabled={disabled}
              onClick={() => {
                setTranscript(true);
                change({ experienced: true });
              }}
            >
              Xem bản chữ thay âm thanh
            </button>
          )}
        </>
      )}
      {listening ? (
        c.choices!.map((v, i) => (
          <button
            key={i}
            disabled={disabled}
            aria-pressed={state.answer === i}
            onClick={() => change({ answer: i })}
          >
            {v}
          </button>
        ))
      ) : (
        <>
          {!writing && (
            <button disabled={disabled} onClick={listen}>
              Nói bằng micro
            </button>
          )}
          <label className="field">
            {writing ? "Câu trả lời bằng tiếng Anh" : "Câu bạn nói hoặc nhập"}
            <textarea
              lang="en"
              maxLength={500}
              disabled={disabled}
              value={typeof state.response === "string" ? state.response : ""}
              onChange={(e) => change({ response: e.target.value })}
            />
          </label>
          {!writing && (
            <small>
              Đối chiếu từ và thứ tự câu; không phải bài chấm điểm phát âm.
            </small>
          )}
        </>
      )}
      {message && <p role="status">{message}</p>}
    </div>
  );
}

export function LanguageEngineInspector({
  slide,
  edit,
}: {
  slide: Slide;
  edit: (fn: (s: Slide) => void) => void;
}) {
  const set = (key: string, value: unknown) =>
    edit((s) => {
      Object.assign(s.config, { [key]: value });
    });
  return (
    <>
      {slide.engine === "textEntry" ? (
        <label className="field">
          Câu được chấp nhận (mỗi dòng một câu, tối đa 6)
          <textarea
            value={slide.config.accepted_answers?.join("\n") ?? ""}
            onChange={(e) =>
              set("accepted_answers", e.target.value.split("\n"))
            }
          />
        </label>
      ) : (
        <label className="field">
          Câu tiếng Anh để đọc mẫu
          <textarea
            maxLength={500}
            value={slide.config.text ?? ""}
            onChange={(e) => set("text", e.target.value)}
          />
        </label>
      )}
      {slide.engine === "listeningChoice" && (
        <>
          <label className="field">
            Các lựa chọn (mỗi dòng một lựa chọn)
            <textarea
              value={slide.config.choices?.join("\n") ?? ""}
              onChange={(e) => set("choices", e.target.value.split("\n"))}
            />
          </label>
          <label className="field">
            Đáp án
            <select
              value={slide.config.answer ?? 0}
              onChange={(e) => set("answer", Number(e.target.value))}
            >
              {slide.config.choices?.map((v, i) => (
                <option key={i} value={i}>
                  {i + 1}. {v}
                </option>
              ))}
            </select>
          </label>
        </>
      )}
      <p className="tip">
        Tiếng Anh được đối chiếu từ và thứ tự câu, bỏ qua hoa/thường và dấu câu.
        Mobile cần phiên bản 1.3.7.
      </p>
    </>
  );
}
