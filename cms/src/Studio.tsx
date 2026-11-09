import { LessonIcon, LessonIconPicker } from "./lesson-icons";
import { LanguageEngineInspector } from "./LanguageEnginePlayer";
import { languageEngines } from "./language-engines";
import { editableStudioVersion } from "./lesson-conversion";
import { ExtraEngineInspector } from "./ExtraEngineInspector";
import { extraEngines } from "./extra-engines";
import { createElement } from "react";
import { engineIcons } from "./engine-icons";
import { useEffect, useRef, useState, type DragEvent } from "react";
import {
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  Box,
  Check,
  Copy,
  Download,
  GripVertical,
  Layers,
  Plus,
  Redo2,
  Save,
  Search,
  Settings2,
  Smartphone,
  Sparkles,
  Trash2,
  Undo2,
} from "lucide-react";
import {
  clone,
  engines,
  moveSlide,
  newSlide,
  payload,
  uid,
  validateLesson,
  type Engine,
  type Lesson,
  type Slide,
  type Topic,
} from "./domain";
import { extendedEngines } from "./engine-contract";
import { qualityReport, suggestEngines } from "./planner";
import { CmsError, type Message, type Repository } from "./repository";
import { DraftWriter, fingerprint, type PendingWrite } from "./draft-writer";
import { PhonePlayer, RichText } from "./Player";
import { Dialog, Field, Logo } from "./ui";

type Recovery = {
  document: Lesson;
  revision: number;
  contentRevision: number;
  pending?: PendingWrite;
  publication?: Publication;
};
type Publication = {
  operation: string;
  document: Lesson;
  revision: number;
  draftRevision: number;
};
function recovery(key: string): Recovery | null {
  try {
    const raw = localStorage.getItem(key);
    if (!raw || raw.length > 400000) return null;
    const c = JSON.parse(raw);
    return c.document?.id &&
      c.document?.config &&
      Number.isInteger(c.revision) &&
      Number.isInteger(c.contentRevision)
      ? c
      : null;
  } catch {
    return null;
  }
}
export function Studio({
  initial,
  topic,
  library = [],
  repository,
  onBack,
  onDenied,
}: {
  initial: Lesson;
  topic?: Topic;
  library?: Lesson[];
  repository: Repository;
  onBack: () => void;
  onDenied: (s: string) => void;
}) {
  const [convertDialog, setConvertDialog] = useState(false);
  const cacheKey = `matlingo-studio-v2:${repository.owner}:${initial.id}`;
  const [restore, setRestore] = useState(() => {
    const c = recovery(cacheKey);
    return c &&
      (c.pending ||
        c.publication ||
        fingerprint(c.document) !== fingerprint(initial))
      ? c
      : null;
  });
  const [doc, setDoc] = useState(() => clone(initial)),
    [selected, setSelected] = useState(0),
    [history, setHistory] = useState<Lesson[]>([]),
    [future, setFuture] = useState<Lesson[]>([]);
  const [search, setSearch] = useState(""),
    [notice, setNotice] = useState(""),
    [busy, setBusy] = useState(false),
    [saving, setSaving] = useState(false),
    [uploading, setUploading] = useState(false),
    [saveLabel, setSaveLabel] = useState("Bản nháp");
  const [confirm, setConfirm] = useState(false),
    [leave, setLeave] = useState(false),
    [assistant, setAssistant] = useState(false),
    [follow, setFollow] = useState(true),
    [chat, setChat] = useState<Message[]>([]),
    [prompt, setPrompt] = useState(""),
    [thinking, setThinking] = useState(false),
    [candidate, setCandidate] = useState("");
  const current = useRef(doc),
    alive = useRef(true),
    pending = useRef<PendingWrite | undefined>(undefined),
    publication = useRef<Publication | undefined>(undefined),
    contentRevision = useRef(initial.content_revision),
    writer = useRef<DraftWriter | null>(null),
    working = useRef(false),
    uploadGeneration = useRef(0);
  const checkpoint = () => {
    try {
      localStorage.setItem(
        cacheKey,
        JSON.stringify({
          document: current.current,
          revision: writer.current?.revision ?? initial.draft_revision,
          contentRevision: contentRevision.current,
          pending: pending.current,
          publication: publication.current,
        }),
      );
    } catch {
      if (alive.current)
        setNotice(
          "Bộ nhớ trình duyệt không khả dụng. Hãy lưu lên máy chủ hoặc xuất bản sao.",
        );
    }
  };
  if (!writer.current) {
    writer.current = new DraftWriter(
      repository,
      initial.draft_revision,
      (p) => {
        pending.current = p;
        checkpoint();
      },
    );
    writer.current.saved =
      initial.draft_revision || initial.content_revision
        ? fingerprint(initial)
        : "";
  }
  const slides = doc.config.slides ?? [],
    slide = slides[selected],
    isCanvas = doc.mechanism === "slideLesson",
    disabled = busy || !!restore || !!publication.current;
  const quality = qualityReport(doc, library),
    suggested = suggestEngines(doc.title, topic?.subject);
  const report = (e: unknown) => {
    if (!alive.current) return;
    if (e instanceof CmsError && e.denied) onDenied(e.message);
    else {
      setNotice(
        e instanceof Error
          ? e.message
          : "Chưa kết nối được máy chủ. Bản đang soạn được giữ lại.",
      );
      setSaveLabel("Chưa đồng bộ");
    }
  };
  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
      uploadGeneration.current++;
    };
  }, []);
  useEffect(() => {
    if (restore) return;
    checkpoint();
    if (disabled || uploading || fingerprint(doc) === writer.current?.saved)
      return;
    const timer = setTimeout(() => void save(), 1600);
    return () => clearTimeout(timer);
  }, [doc, restore, busy, uploading]);
  useEffect(() => {
    const before = (e: BeforeUnloadEvent) => {
      if (
        fingerprint(current.current) !== writer.current?.saved ||
        pending.current ||
        publication.current
      ) {
        e.preventDefault();
        e.returnValue = "";
      }
    };
    window.addEventListener("beforeunload", before);
    return () => window.removeEventListener("beforeunload", before);
  }, []);
  function apply(next: Lesson, record = true) {
    if (record) {
      const previous = clone(current.current);
      setHistory((h) => [...h.slice(-39), previous]);
      setFuture([]);
    }
    current.current = next;
    setDoc(next);
    setSaveLabel("Có thay đổi");
  }
  function change(fn: (d: Lesson) => void) {
    if (disabled) return;
    const next = clone(current.current);
    fn(next);
    apply(next);
  }
  function edit(fn: (s: Slide) => void) {
    change((d) => {
      if (d.config.slides?.[selected]) fn(d.config.slides[selected]);
    });
  }
  function travel(redo = false) {
    if (disabled) return;
    const stack = redo ? future : history;
    if (!stack.length) return;
    const next = clone(stack.at(-1)!),
      previous = clone(current.current);
    if (redo) {
      setFuture((f) => f.slice(0, -1));
      setHistory((h) => [...h, previous]);
    } else {
      setHistory((h) => h.slice(0, -1));
      setFuture((f) => [...f, previous]);
    }
    apply(next, false);
    setSelected(
      Math.max(0, Math.min(selected, (next.config.slides?.length ?? 1) - 1)),
    );
  }
  function add(engine: Engine, at = slides.length) {
    if (disabled || !isCanvas) return;
    if (slides.length >= 12) {
      setNotice("Mỗi bài hỗ trợ tối đa 12 slide.");
      return;
    }
    change((d) => d.config.slides!.splice(at, 0, newSlide(engine)));
    setSelected(at);
  }
  function drop(e: DragEvent, at: number) {
    e.preventDefault();
    const engine = e.dataTransfer.getData("application/matlingo-engine");
    if (engine in engines) {
      add(engine as Engine, at);
      return;
    }
    const raw = e.dataTransfer.getData("application/matlingo-slide");
    if (!/^\d+$/.test(raw) || disabled) return;
    const from = Number(raw),
      to = Math.min(at > from ? at - 1 : at, slides.length - 1);
    change((d) => {
      d.config.slides = moveSlide(d.config.slides!, from, to);
    });
    setSelected(to);
  }
  async function save() {
    if (working.current || restore) return false;
    setSaving(true);
    try {
      await writer.current!.save(current.current);
      if (!alive.current) return false;
      setSaveLabel(repository.demo ? "Đã lưu mô phỏng" : "Đã lưu máy chủ");
      checkpoint();
      return true;
    } catch (e) {
      report(e);
      return false;
    } finally {
      if (alive.current) setSaving(false);
    }
  }
  async function publish() {
    if (working.current || saving || uploading) return;
    const errors = validateLesson(current.current);
    if (errors.length) {
      setNotice(errors.join(" "));
      return;
    }
    setBusy(true);
    try {
      if (!publication.current) {
        if (!(await save())) return;
        publication.current = {
          operation: crypto.randomUUID(),
          document: clone(current.current),
          revision: contentRevision.current,
          draftRevision: writer.current!.revision,
        };
        checkpoint();
      }
      working.current = true;
      const p = publication.current;
      contentRevision.current = await repository.publish(
        p.document,
        p.revision,
        p.draftRevision,
        p.operation,
      );
      if (!alive.current) return;
      publication.current = undefined;
      writer.current!.saved = fingerprint(current.current);
      setConfirm(false);
      setSaveLabel(repository.demo ? "Đã phát hành mô phỏng" : "Đã phát hành");
      checkpoint();
      setNotice(
        repository.demo
          ? "Đã mô phỏng phát hành. Không thay đổi máy chủ."
          : "Đã phát hành phiên bản mới. Mobile tương thích nhận bài khi tải lại danh mục.",
      );
    } catch (e) {
      if (e instanceof CmsError && e.conflict) {
        publication.current = undefined;
        checkpoint();
      }
      report(e);
    } finally {
      working.current = false;
      if (alive.current) setBusy(false);
    }
  }
  function exportCopy() {
    const url = URL.createObjectURL(
      new Blob([JSON.stringify(payload(doc), null, 2)], {
        type: "application/json",
      }),
    );
    const a = document.createElement("a");
    a.href = url;
    a.download = `${doc.id}.json`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  async function upload(file: File) {
    if (uploading || disabled || !slide) return;
    const id = slide.id,
      generation = ++uploadGeneration.current;
    setUploading(true);
    try {
      const url = await repository.uploadAsset(file);
      if (!alive.current || generation !== uploadGeneration.current) return;
      change((d) => {
        const target = d.config.slides?.find((s) => s.id === id);
        if (target) {
          target.config.image_url = url;
          target.config.image_alt ||= file.name.replace(/\.[^.]+$/, "");
        }
      });
      setNotice(
        repository.demo
          ? "Ảnh chỉ lưu trong sandbox. URL ảnh thật được tạo khi đăng nhập Admin."
          : "Đã tải ảnh lên thư viện.",
      );
    } catch (e) {
      report(e);
    } finally {
      if (alive.current) setUploading(false);
    }
  }
  async function ask() {
    if (!prompt.trim() || thinking) return;
    const outgoing: Message[] = [
      ...chat,
      { role: "user" as const, content: prompt.trim() },
    ].slice(-12);
    setChat(outgoing);
    setPrompt("");
    setThinking(true);
    try {
      const text = await repository.chat(outgoing, clone(current.current));
      if (alive.current)
        setChat([...outgoing, { role: "assistant", content: text }]);
    } catch (e) {
      report(e);
      if (alive.current) setPrompt(outgoing.at(-1)!.content);
    } finally {
      if (alive.current) setThinking(false);
    }
  }
  return (
    <div className="studio-shell">
      <header className="studio-header">
        <button
          aria-label="Về thư viện"
          onClick={() =>
            fingerprint(doc) !== writer.current?.saved ||
            pending.current ||
            publication.current
              ? setLeave(true)
              : onBack()
          }
        >
          <ArrowLeft size={18} />
        </button>
        <Logo small />
        <span className="header-divider" />
        <div className="studio-document">
          <span>{topic?.title ?? "Chủ đề"}</span>
          <strong>{doc.title}</strong>
        </div>
        <span className="save-status" role="status">
          {saving ? "Đang lưu…" : saveLabel}
        </span>
        <div className="header-actions">
          <button
            aria-label="Hoàn tác"
            disabled={!history.length || disabled}
            onClick={() => travel()}
          >
            <Undo2 size={18} />
          </button>
          <button
            aria-label="Làm lại"
            disabled={!future.length || disabled}
            onClick={() => travel(true)}
          >
            <Redo2 size={18} />
          </button>
          <button disabled={disabled} onClick={() => setAssistant(true)}>
            <Sparkles size={16} />
            <span>Trợ lý AI</span>
          </button>
          <button aria-label="Xuất bản sao JSON" onClick={exportCopy}>
            <Download size={17} />
          </button>
          <button disabled={disabled || saving || uploading} onClick={save}>
            <Save size={16} />
            <span>Lưu nháp</span>
          </button>
          <button
            className="primary"
            disabled={busy || saving || uploading || !!restore}
            onClick={() => setConfirm(true)}
          >
            <span>Phát hành</span>
            <ArrowRight size={16} />
          </button>
        </div>
      </header>
      {repository.demo && (
        <div className="sandbox-strip">
          SANDBOX · Bản thiết kế thử nghiệm, không thay đổi dữ liệu thật.
        </div>
      )}
      {notice && (
        <div className="studio-notice" role="status">
          {notice}
          <button aria-label="Đóng thông báo" onClick={() => setNotice("")}>
            ×
          </button>
        </div>
      )}
      <div className="studio-columns">
        <aside className="engine-palette">
          <div className="panel-title">
            <Box size={17} />
            <strong>Kho engine</strong>
            <span>{Object.keys(engines).length}</span>
          </div>
          <label className="search-field">
            <Search size={15} />
            <input
              aria-label="Tìm engine"
              placeholder="Tìm tương tác…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </label>
          <p className="panel-help">Kéo engine vào luồng, hoặc bấm để thêm.</p>
          <p className="tip">
            Bài phát hành từ Studio cần mobile 1.3.7 trở lên.
          </p>
          {[
            "Dẫn nhập",
            "Hình học",
            "Đại số",
            "Lập trình",
            "Ngôn ngữ",
            "Khoa học",
            "Tư duy",
          ].map((group) => {
            const rows = (Object.keys(engines) as Engine[]).filter(
              (e) =>
                (e in extendedEngines
                  ? extendedEngines[e as keyof typeof extendedEngines][1]
                  : e === "graph"
                    ? "Đại số"
                    : "Dẫn nhập") === group &&
                `${engines[e].name} ${e}`
                  .toLowerCase()
                  .includes(search.toLowerCase()),
            );
            return (
              rows.length > 0 && (
                <section className="engine-group" key={group}>
                  <h3>{group}</h3>
                  {rows.map((e) => (
                    <button
                      className={`engine-tile ${suggested.includes(e) ? "recommended" : ""}`}
                      key={e}
                      draggable={!disabled && isCanvas}
                      disabled={disabled || !isCanvas}
                      onDragStart={(ev) =>
                        ev.dataTransfer.setData(
                          "application/matlingo-engine",
                          e,
                        )
                      }
                      onClick={() => add(e)}
                    >
                      <span className={`engine-symbol ${engines[e].color}`}>
                        {createElement(engineIcons[e], { size: 18 })}
                      </span>
                      <span>
                        <strong>{engines[e].name}</strong>
                        <small>
                          {suggested.includes(e) ? "ĐỀ XUẤT CHO BÀI NÀY" : e}
                        </small>
                      </span>
                      <Plus size={13} />
                    </button>
                  ))}
                </section>
              )
            );
          })}
        </aside>
        <main className="flow-canvas">
          <div className="canvas-toolbar">
            <span>
              <Layers size={16} />
              Luồng bài học
            </span>
            <span>{slides.length}/12 slide</span>
          </div>
          <div className="flow-intro">
            <span className="eyebrow">THIẾT KẾ MỘT HÀNH TRÌNH KHÁM PHÁ</span>
            <h1>
              <LessonIcon lesson={doc} />
              {doc.title}
            </h1>
            <p>{doc.prompt}</p>
          </div>
          {isCanvas ? (
            <>
              <div className="flow-track">
                {slides.map((s, i) => (
                  <div key={s.id}>
                    <div
                      className="flow-drop"
                      data-testid={`drop-${i}`}
                      onDragOver={(e) => e.preventDefault()}
                      onDrop={(e) => drop(e, i)}
                    >
                      Thả slide ở đây
                    </div>
                    <article
                      className={`flow-node ${selected === i ? "selected" : ""}`}
                    >
                      <button
                        className="flow-node-select"
                        aria-label={`Chọn slide ${i + 1}`}
                        onClick={() => setSelected(i)}
                      >
                        <span className="flow-number">
                          {String(i + 1).padStart(2, "0")}
                        </span>
                        <span
                          className={`engine-symbol ${engines[s.engine]?.color ?? "lime"}`}
                        >
                          {createElement(engineIcons[s.engine] ?? Box, {
                            size: 23,
                          })}
                        </span>
                        <span>
                          <small>{engines[s.engine]?.name ?? s.engine}</small>
                          <strong>{s.title}</strong>
                          <em>{s.prompt || s.config.text}</em>
                        </span>
                        <GripVertical size={16} />
                      </button>
                      <div className="node-actions">
                        <button
                          aria-label={`Kéo slide ${i + 1}`}
                          draggable={!disabled}
                          disabled={disabled}
                          onDragStart={(e) =>
                            e.dataTransfer.setData(
                              "application/matlingo-slide",
                              String(i),
                            )
                          }
                        >
                          <GripVertical size={14} />
                        </button>
                        <button
                          aria-label={`Đưa slide ${i + 1} lên`}
                          disabled={disabled || i === 0}
                          onClick={() => {
                            change((d) => {
                              d.config.slides = moveSlide(
                                d.config.slides!,
                                i,
                                i - 1,
                              );
                            });
                            setSelected(i - 1);
                          }}
                        >
                          <ArrowUp size={14} />
                        </button>
                        <button
                          aria-label={`Đưa slide ${i + 1} xuống`}
                          disabled={disabled || i === slides.length - 1}
                          onClick={() => {
                            change((d) => {
                              d.config.slides = moveSlide(
                                d.config.slides!,
                                i,
                                i + 1,
                              );
                            });
                            setSelected(i + 1);
                          }}
                        >
                          <ArrowDown size={14} />
                        </button>
                        <button
                          aria-label={`Nhân bản slide ${i + 1}`}
                          disabled={disabled || slides.length >= 12}
                          onClick={() => {
                            change((d) => {
                              const copy = clone(s);
                              copy.id = uid("slide");
                              d.config.slides!.splice(i + 1, 0, copy);
                            });
                            setSelected(i + 1);
                          }}
                        >
                          <Copy size={14} />
                        </button>
                        <button
                          aria-label={`Xóa slide ${i + 1}`}
                          disabled={disabled || slides.length <= 1}
                          onClick={() => {
                            change((d) => d.config.slides!.splice(i, 1));
                            setSelected(
                              Math.max(
                                0,
                                Math.min(selected, slides.length - 2),
                              ),
                            );
                          }}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </article>
                  </div>
                ))}
                <div
                  className="flow-drop end"
                  data-testid={`drop-${slides.length}`}
                  onDragOver={(e) => e.preventDefault()}
                  onDrop={(e) => drop(e, slides.length)}
                >
                  <Plus size={19} />
                  <span>Kéo engine để thêm bước khám phá</span>
                </div>
              </div>
              <section className="quality-card">
                <div>
                  <span className="eyebrow">QUALITY GUARD · CÙNG CHỦ ĐỀ</span>
                  <h3>{quality.diversity} cơ chế tương tác</h3>
                </div>
                <meter
                  aria-label="Tỷ lệ trắc nghiệm"
                  min="0"
                  max="1"
                  value={quality.ratio}
                />
                <small>{Math.round(quality.ratio * 100)}% trắc nghiệm</small>
                {quality.warnings.map((w) => (
                  <p className="warning" key={w}>
                    {w}
                  </p>
                ))}
              </section>
            </>
          ) : (
            <section className="quality-card">
              <span className="eyebrow">CHỈNH SỬA BÀI HIỆN CÓ</span>
              <h2>{doc.title}</h2>
              <button
                className="primary"
                disabled={disabled || !doc.content_version}
                onClick={() => setConvertDialog(true)}
              >
                Soạn lại bằng Studio và thêm engine
              </button>
              <div className="prose">
                <RichText text={doc.prompt} />
              </div>
              {doc.mechanism === "reasonedChoice" ? (
                <p>
                  Sửa kiến thức, câu hỏi, lựa chọn và đáp án trong bảng thuộc
                  tính. Phát hành tạo phiên bản mới và giữ đáp án của phiên học
                  cũ.
                </p>
              ) : (
                <p>
                  Sửa tên bài, yêu cầu, giai đoạn, gợi ý, lời giải và thứ tự
                  trong bảng thuộc tính. Mô hình tương tác và bộ chấm gốc được
                  giữ để tương thích lịch sử học.
                </p>
              )}
            </section>
          )}
        </main>
        <aside className="inspector-panel">
          <div className="panel-title">
            <Settings2 size={17} />
            <strong>Thuộc tính</strong>
            <span>{slide ? `#${selected + 1}` : "Bài"}</span>
          </div>
          <fieldset disabled={disabled}>
            {isCanvas && (
              <LessonIconPicker
                lesson={doc}
                onChange={(key) =>
                  change((d) => {
                    if (key) d.config.lesson_icon = key;
                    else delete d.config.lesson_icon;
                  })
                }
              />
            )}
            <details className="lesson-details" open={!isCanvas}>
              <summary>Thông tin bài học</summary>
              <Field
                label="Tên bài học"
                value={doc.title}
                max={160}
                onChange={(v) =>
                  change((d) => {
                    d.title = v;
                  })
                }
              />
              <Field
                label="Mục tiêu bài học"
                value={doc.prompt}
                area
                onChange={(v) =>
                  change((d) => {
                    d.prompt = v;
                  })
                }
              />
              <Field
                label="Giai đoạn bài học"
                value={doc.stage}
                max={160}
                onChange={(v) =>
                  change((d) => {
                    d.stage = v;
                  })
                }
              />
              <Field
                label="Thứ tự bài"
                type="number"
                min={0}
                value={doc.sort_order}
                onChange={(v) =>
                  change((d) => {
                    d.sort_order = Number(v);
                  })
                }
              />
              <label className="field">
                Trạng thái bài
                <select
                  value={doc.status}
                  onChange={(e) =>
                    change((d) => {
                      d.status = e.target.value;
                    })
                  }
                >
                  <option value="active">Hoạt động</option>
                  <option value="archived">Lưu trữ</option>
                </select>
              </label>
            </details>
            {slide && isCanvas ? (
              <>
                <div className="inspector-engine">
                  <span className="engine-symbol lime">
                    {createElement(engineIcons[slide.engine] ?? Box, {
                      size: 20,
                    })}
                  </span>
                  <div>
                    <strong>{engines[slide.engine]?.name}</strong>
                    <small>{slide.engine}</small>
                  </div>
                </div>
                <Field
                  label="Tiêu đề slide"
                  value={slide.title}
                  max={160}
                  onChange={(v) =>
                    edit((s) => {
                      s.title = v;
                    })
                  }
                />
                <Field
                  label="Yêu cầu cho người học"
                  value={slide.prompt}
                  area
                  onChange={(v) =>
                    edit((s) => {
                      s.prompt = v;
                    })
                  }
                />
                <EngineInspector slide={slide} edit={edit} />
                {slide.engine === "story" && (
                  <>
                    <div
                      className="asset-drop"
                      onDragOver={(e) => e.preventDefault()}
                      onDrop={(e) => {
                        e.preventDefault();
                        const file = e.dataTransfer.files[0];
                        if (file) void upload(file);
                      }}
                    >
                      <label>
                        {uploading
                          ? "Đang tải ảnh…"
                          : "Kéo ảnh vào đây hoặc chọn từ máy"}
                        <input
                          aria-label="Tải ảnh minh họa"
                          type="file"
                          accept="image/png,image/jpeg,image/webp,image/gif,image/svg+xml"
                          disabled={uploading || disabled}
                          onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (file) void upload(file);
                            e.target.value = "";
                          }}
                        />
                      </label>
                      <small>PNG, JPEG, GIF, WebP, SVG · Tối đa 5 MB</small>
                    </div>
                    {slide.config.image_url && (
                      <img
                        className="asset-thumbnail"
                        src={slide.config.image_url}
                        alt={slide.config.image_alt ?? "Ảnh minh họa"}
                      />
                    )}
                  </>
                )}
                <Field
                  label="Gợi ý khi gặp khó"
                  value={slide.hint}
                  area
                  max={3000}
                  onChange={(v) =>
                    edit((s) => {
                      s.hint = v;
                    })
                  }
                />
                <Field
                  label="Giải thích khi làm đúng"
                  value={slide.explanation}
                  area
                  onChange={(v) =>
                    edit((s) => {
                      s.explanation = v;
                    })
                  }
                />
              </>
            ) : (
              <>
                {doc.mechanism === "reasonedChoice" && (
                  <AuthoredChoiceInspector lesson={doc} change={change} />
                )}
                <Field
                  label="Gợi ý"
                  value={doc.hint}
                  area
                  onChange={(v) =>
                    change((d) => {
                      d.hint = v;
                    })
                  }
                />
                <Field
                  label="Giải thích"
                  value={doc.explanation}
                  area
                  onChange={(v) =>
                    change((d) => {
                      d.explanation = v;
                    })
                  }
                />
              </>
            )}
          </fieldset>
          <div className="inspector-validation">
            {validateLesson(doc).map((e) => (
              <p className="warning" key={e}>
                {e}
              </p>
            ))}
          </div>
        </aside>
        <aside className="simulator-panel">
          <div className="panel-title">
            <Smartphone size={17} />
            <strong>Phone simulator</strong>
            <span className="live-dot">LIVE</span>
          </div>
          <label className="follow-label">
            <input
              type="checkbox"
              checked={follow}
              onChange={(e) => setFollow(e.target.checked)}
            />
            Theo slide đang chọn
          </label>
          {isCanvas ? (
            <PhonePlayer lesson={doc} selected={selected} follow={follow} />
          ) : (
            <p className="empty">Bài đóng gói sử dụng renderer trên mobile.</p>
          )}
          <p className="simulator-footnote">
            Thử như người học. Thay đổi thuộc tính xuất hiện ngay trên điện
            thoại.
          </p>
        </aside>
      </div>
      {convertDialog && (
        <Dialog
          title="Tạo phiên bản Studio cho bài hiện có"
          onClose={() => setConvertDialog(false)}
        >
          <p>
            Nội dung dẫn dắt sẽ được giữ lại. Bạn có thể thay engine, cấu hình
            và đáp án của phiên bản mới; các phiên học cũ giữ nguyên mô hình
            gốc.
          </p>
          <p className="warning">
            Kiểm tra lại tương tác và đáp án mẫu sau khi chuyển. Bản cũ chưa
            thay đổi cho tới khi bạn phát hành.
          </p>
          <button
            className="primary"
            onClick={() => {
              change((d) => Object.assign(d, editableStudioVersion(d)));
              setSelected(0);
              setConvertDialog(false);
            }}
          >
            Chuyển sang Studio
          </button>
        </Dialog>
      )}
      {confirm && (
        <Dialog
          title="Kiểm tra trước khi phát hành"
          onClose={() => !busy && setConfirm(false)}
        >
          <h3>{doc.title}</h3>
          <p>
            {slides.length} bước · {topic?.title}
          </p>
          {validateLesson(doc).map((e) => (
            <p className="error" key={e}>
              {e}
            </p>
          ))}
          {quality.warnings.map((w) => (
            <p className="warning" key={w}>
              {w}
            </p>
          ))}
          {topic?.status !== "active" && (
            <p className="warning">
              Chủ đề chưa hoạt động; bài chưa hiển thị cho người học.
            </p>
          )}
          <p>
            Phát hành tạo phiên bản mới. Phiên học đang diễn ra tiếp tục dùng
            phiên bản cũ.
          </p>
          <button
            className="primary"
            disabled={busy || saving || !!validateLesson(doc).length}
            onClick={publish}
          >
            {busy ? "Đang phát hành…" : "Xác nhận phát hành"}
            <Check size={16} />
          </button>
        </Dialog>
      )}
      {leave && (
        <Dialog
          title="Giữ bản thiết kế đang soạn"
          onClose={() => setLeave(false)}
        >
          <p>Bạn còn thay đổi hoặc yêu cầu chưa được xác nhận.</p>
          <div className="button-row">
            <button onClick={exportCopy}>Xuất bản sao</button>
            <button disabled={saving || busy} onClick={onBack}>
              Rời Studio
            </button>
            <button
              className="primary"
              disabled={saving || busy}
              onClick={async () => {
                if (await save()) onBack();
              }}
            >
              Lưu rồi quay lại
            </button>
          </div>
        </Dialog>
      )}
      {restore && (
        <Dialog
          title="Khôi phục thiết kế chưa đồng bộ"
          onClose={() => setRestore(null)}
        >
          <p>
            Tìm thấy bản đang soạn của tài khoản này. Khôi phục tiếp tục kiểm
            tra revision trên máy chủ.
          </p>
          <div className="button-row">
            <button
              onClick={() => {
                setRestore(null);
                checkpoint();
              }}
            >
              Dùng bản máy chủ
            </button>
            <button
              className="primary"
              onClick={() => {
                const c = restore;
                current.current = c.document;
                setDoc(c.document);
                pending.current = c.pending;
                publication.current = c.publication;
                contentRevision.current = c.contentRevision;
                writer.current = new DraftWriter(
                  repository,
                  c.revision,
                  (p) => {
                    pending.current = p;
                    checkpoint();
                  },
                  c.pending,
                );
                setRestore(null);
              }}
            >
              Khôi phục
            </button>
          </div>
        </Dialog>
      )}
      {assistant && (
        <Dialog
          title="Cộng sự thiết kế · Gemini"
          onClose={() => setAssistant(false)}
          wide
        >
          <p>
            Hỏi kiến thức, đề xuất thí nghiệm hoặc kiểm tra lời giải trong ngữ
            cảnh bài học.
          </p>
          <div className="chat-log">
            {chat.map((m, i) => (
              <article key={i} className={`chat-message ${m.role}`}>
                <small>{m.role === "user" ? "Bạn" : "Gemini"}</small>
                <div className="prose">
                  <RichText text={m.content} />
                </div>
                {m.role === "assistant" && (
                  <button
                    disabled={disabled || slides.length >= 12 || !isCanvas}
                    onClick={() => setCandidate(m.content)}
                  >
                    Duyệt và chèn vào bài
                  </button>
                )}
              </article>
            ))}
          </div>
          <Field
            label="Nhắn Gemini"
            value={prompt}
            max={3000}
            area
            onChange={setPrompt}
          />
          <button
            className="primary"
            disabled={thinking || !prompt.trim()}
            onClick={ask}
          >
            {thinking ? "Đang suy nghĩ…" : "Gửi câu hỏi"}
            <Sparkles size={16} />
          </button>
          {candidate && (
            <section className="candidate">
              <h3>Duyệt nội dung trước khi chèn</h3>
              <div className="prose">
                <RichText text={candidate} />
              </div>
              <p>
                Kiểm tra độ chính xác và điều chỉnh nội dung phù hợp người học.
              </p>
              <button
                className="primary"
                disabled={disabled || slides.length >= 12}
                onClick={() => {
                  const s = newSlide("story");
                  s.title = "Ý tưởng khám phá";
                  s.config.text = candidate.slice(0, 10000);
                  change((d) => d.config.slides!.splice(selected + 1, 0, s));
                  setSelected(selected + 1);
                  setCandidate("");
                }}
              >
                Áp dụng vào slide mới
              </button>
              <button onClick={() => setCandidate("")}>Bỏ đề xuất</button>
            </section>
          )}
        </Dialog>
      )}
    </div>
  );
}

function AuthoredChoiceInspector({
  lesson,
  change,
}: {
  lesson: Lesson;
  change: (fn: (d: Lesson) => void) => void;
}) {
  const c = lesson.config;
  const list = (key: "choices" | "reasons") =>
    Array.isArray(c[key]) ? (c[key] as string[]) : [];
  return (
    <>
      <Field
        label="Kiến thức cốt lõi"
        area
        value={String(c.knowledge ?? "")}
        onChange={(v) =>
          change((d) => {
            d.config.knowledge = v;
          })
        }
      />
      <Field
        label="Nguồn tham khảo"
        max={2000}
        value={String(c.source ?? "")}
        onChange={(v) =>
          change((d) => {
            d.config.source = v;
          })
        }
      />
      {typeof c.code === "string" && (
        <Field
          label="Mã minh họa (chỉ hiển thị)"
          area
          value={c.code}
          onChange={(v) =>
            change((d) => {
              d.config.code = v;
            })
          }
        />
      )}
      {(c.answer === undefined || c.reason === undefined) && (
        <p className="tip">
          Bài gốc dùng bộ chấm đóng gói. Chọn rõ đáp án và lý do đúng trước khi
          phát hành phiên bản mới.
        </p>
      )}
      {(["choices", "reasons"] as const).map((key) => (
        <section key={key}>
          <Field
            label={
              key === "choices"
                ? "Các lựa chọn (mỗi dòng một đáp án)"
                : "Các lý do (mỗi dòng một lý do)"
            }
            area
            value={list(key).join("\n")}
            onChange={(v) =>
              change((d) => {
                d.config[key] = v.split("\n");
              })
            }
          />
          <label className="field">
            {key === "choices" ? "Đáp án đúng" : "Lý do đúng"}
            <select
              value={Number(c[key === "choices" ? "answer" : "reason"] ?? -1)}
              onChange={(e) =>
                change((d) => {
                  d.config[key === "choices" ? "answer" : "reason"] = Number(
                    e.target.value,
                  );
                })
              }
            >
              <option value={-1}>Chọn đáp án đúng</option>
              {list(key).map((v, i) => (
                <option key={i} value={i}>
                  {i + 1}. {v}
                </option>
              ))}
            </select>
          </label>
        </section>
      ))}
    </>
  );
}

export function EngineInspector({
  slide,
  edit,
}: {
  slide: Slide;
  edit: (fn: (s: Slide) => void) => void;
}) {
  if (slide.engine in languageEngines)
    return <LanguageEngineInspector slide={slide} edit={edit} />;
  if (slide.engine in extraEngines)
    return <ExtraEngineInspector slide={slide} edit={edit} />;
  const c = slide.config;
  const set = (key: string, value: unknown) =>
    edit((s) => {
      Object.assign(s.config, { [key]: value });
    });
  const number = (
    key: keyof Slide["config"],
    label: string,
    min = -10,
    max = 125,
  ) => (
    <Field
      key={key}
      label={label}
      type="number"
      min={min}
      maxNumber={max}
      value={Number(c[key] ?? 0)}
      onChange={(v) => set(key, Number(v))}
    />
  );
  const lines = (key: keyof Slide["config"], label: string) => (
    <Field
      key={key}
      label={label}
      value={((c[key] as string[]) ?? []).join("\n")}
      area
      onChange={(v) => set(key, v.split("\n"))}
    />
  );
  const indexes = (key: keyof Slide["config"], label: string) => (
    <Field
      key={key}
      label={label}
      value={((c[key] as number[]) ?? []).join(", ")}
      onChange={(v) =>
        set(
          key,
          v.split(",").map((n) => (n.trim() === "" ? NaN : Number(n.trim()))),
        )
      }
    />
  );
  switch (slide.engine) {
    case "story":
      return (
        <>
          <Field
            label="Nội dung / KaTeX ($...$)"
            value={c.text ?? ""}
            area
            onChange={(v) => set("text", v)}
          />
          <Field
            label="URL hình ảnh HTTPS"
            value={c.image_url ?? ""}
            max={2000}
            onChange={(v) => set("image_url", v)}
          />
          <Field
            label="Mô tả ảnh"
            value={c.image_alt ?? ""}
            max={500}
            onChange={(v) => set("image_alt", v)}
          />
        </>
      );
    case "quiz":
      return (
        <>
          {lines("choices", "Các lựa chọn (mỗi dòng một đáp án)")}
          <label className="field">
            Đáp án đúng
            <select
              value={c.answer}
              onChange={(e) => set("answer", Number(e.target.value))}
            >
              {c.choices?.map((choice, i) => (
                <option key={i} value={i}>
                  {i + 1}. {choice}
                </option>
              ))}
            </select>
          </label>
        </>
      );
    case "pairs":
      return (
        <>
          <p className="tip">Hai ô cùng hàng là một cặp đúng.</p>
          {c.pairs?.map((p, i) => (
            <div className="pair-editor" key={i}>
              <Field
                label={`Vế trái ${i + 1}`}
                value={p.left}
                max={1000}
                onChange={(v) =>
                  set(
                    "pairs",
                    c.pairs!.map((x, n) => (n === i ? { ...x, left: v } : x)),
                  )
                }
              />
              <Field
                label={`Vế phải ${i + 1}`}
                value={p.right}
                max={1000}
                onChange={(v) =>
                  set(
                    "pairs",
                    c.pairs!.map((x, n) => (n === i ? { ...x, right: v } : x)),
                  )
                }
              />
              <button
                aria-label={`Xóa cặp ${i + 1}`}
                disabled={c.pairs!.length <= 2}
                onClick={() =>
                  set(
                    "pairs",
                    c.pairs!.filter((_, n) => n !== i),
                  )
                }
              >
                <Trash2 size={13} />
              </button>
            </div>
          ))}
          <button
            disabled={c.pairs!.length >= 6}
            onClick={() =>
              set("pairs", [...c.pairs!, { left: "Ý tưởng", right: "Kết nối" }])
            }
          >
            Thêm cặp
          </button>
        </>
      );
    case "graph":
      return (
        <>
          {(["a", "b"] as const).map((axis) => (
            <section key={axis}>
              <h4>Tham số {axis}</h4>
              <div className="number-grid">
                {(["min", "max", "start", "target"] as const).map((k) =>
                  number(
                    `${k}_${axis}`,
                    {
                      min: "Tối thiểu",
                      max: "Tối đa",
                      start: "Ban đầu",
                      target: "Mục tiêu",
                    }[k],
                    -10,
                    10,
                  ),
                )}
              </div>
            </section>
          ))}
        </>
      );
    case "solid3D":
      return (
        <>
          {number("target_volume", "Thể tích mục tiêu", 1, 125)}
          <p className="tip">
            Mỗi chiều từ 1 đến 5, bước 1. Chọn thể tích tạo được trong giới hạn
            này.
          </p>
        </>
      );
    case "polygonVertices":
      return (
        <>
          {number("target_area", "Diện tích chữ nhật mục tiêu", 1, 16)}
          <p className="tip">
            Bốn đỉnh trên lưới 0–4. Hình phải là hình chữ nhật.
          </p>
        </>
      );
    case "balanceScale":
      return number("target_weight", "Khối lượng đĩa phải", 0, 10);
    case "robotRoute":
      return (
        <>
          {number("max_commands", "Giới hạn lệnh", 6, 32)}
          <p className="tip">
            Bản đồ 4 × 4: từ (0,0) tới (3,3), tránh đá (1,1).
          </p>
        </>
      );
    case "loopBuilder":
      return (
        <>
          {number("target_repeat", "Số lần lặp mục tiêu", 1, 4)}
          <Field
            label="Hai lệnh mục tiêu (R, D, L, U)"
            value={c.target_body!.join(", ")}
            onChange={(v) =>
              set(
                "target_body",
                v.split(",").map((s) => s.trim().toUpperCase()),
              )
            }
          />
        </>
      );
    case "globe3D":
      return (
        <>
          {number("target_latitude", "Vĩ độ mục tiêu (bội số 15)", -90, 90)}
          {number(
            "target_longitude",
            "Kinh độ mục tiêu (bội số 15)",
            -180,
            180,
          )}
        </>
      );
    case "causalLab":
    case "causalExperiment":
      return (
        <>
          {lines("axes", "Tên hai biến (hai dòng)")}
          {number("target_product", "Tích mục tiêu", 0, 9)}
          <p className="tip">
            Mỗi biến từ 0–3; người học cần dự đoán và chạy mô hình.
          </p>
        </>
      );
    case "symmetryMirror":
      return (
        <p className="tip">
          Lưới gương 6 × 6. Các ô nguồn (6, 13, 18) phản chiếu sang (11, 16,
          23).
        </p>
      );
    case "tangramRotate":
      return (
        <p className="tip">
          Hai tam giác quay lệch nhau 180° và được đặt vào khung.
        </p>
      );
    case "strata3D":
      return (
        <p className="tip">
          Ba lớp đá tuổi 10, 20, 30 triệu năm; sắp từ trẻ đến già.
        </p>
      );
    case "resourceBudget":
      return (
        <>
          {lines("items", "Tên tài nguyên (mỗi dòng một loại)")}
          {indexes(
            "minima",
            "Mức tối thiểu từng loại (cách nhau bằng dấu phẩy)",
          )}
          <p className="tip">
            Tổng tài nguyên là 10; có thể có nhiều phương án đúng.
          </p>
        </>
      );
    default:
      return (
        <>
          {lines("items", "Nội dung từng thẻ (mỗi dòng một thẻ)")}
          {slide.engine !== "sequenceTiles" &&
            slide.engine !== "evidenceBoard" &&
            lines("choices", "Ngân hàng lựa chọn (mỗi dòng một mục)")}
          {indexes(
            "answer_values",
            slide.engine === "evidenceBoard"
              ? "Chỉ số bằng chứng đúng (bắt đầu từ 0)"
              : slide.engine === "sequenceTiles"
                ? "Thứ tự chỉ số đúng (bắt đầu từ 0)"
                : "Chỉ số đáp án từng thẻ (bắt đầu từ 0)",
          )}
        </>
      );
  }
}
