import { LessonIcon } from "./lesson-icons";
import { useEffect, useMemo, useRef, useState } from "react";
import type { User } from "@supabase/supabase-js";
import {
  ArrowRight,
  BookOpen,
  Box,
  ChevronRight,
  Layers,
  LayoutDashboard,
  LogOut,
  Plus,
  Search,
  Users,
} from "lucide-react";
import {
  client,
  configured,
  CmsError,
  DemoRepository,
  newTopic,
  SupabaseRepository,
  type Repository,
} from "./repository";
import { clone, engines, type Lesson, type Topic } from "./domain";
import { subjects, topicRecipe } from "./planner";
import { Dialog, Field, Logo } from "./ui";
import { Studio } from "./Studio";

export function App() {
  const [user, setUser] = useState<User | null>(null),
    [ready, setReady] = useState(!client),
    [demo, setDemo] = useState(false),
    [verified, setVerified] = useState(false),
    [error, setError] = useState(""),
    [retry, setRetry] = useState(0);
  const repo = useMemo(
    () =>
      demo
        ? new DemoRepository()
        : user && client
          ? new SupabaseRepository(client, user.id)
          : null,
    [demo, user?.id],
  );
  useEffect(() => {
    if (!client) return;
    let alive = true;
    let changed = false;
    client.auth
      .getSession()
      .then(({ data, error }) => {
        if (alive && !changed) {
          setUser(data.session?.user ?? null);
          setError(error ? "Chưa đọc được phiên đăng nhập." : "");
          setReady(true);
        }
      })
      .catch(() => {
        if (alive) {
          setError("Chưa kết nối được máy chủ.");
          setReady(true);
        }
      });
    const { data } = client.auth.onAuthStateChange((_, session) => {
      changed = true;
      setUser(session?.user ?? null);
      setReady(true);
    });
    return () => {
      alive = false;
      data.subscription.unsubscribe();
    };
  }, []);
  useEffect(() => {
    let alive = true;
    setVerified(false);
    setError("");
    if (!repo) return;
    const check = async () => {
      try {
        await repo.access();
        if (alive) setVerified(true);
      } catch (e) {
        if (alive) {
          setVerified(false);
          setError(
            e instanceof Error
              ? e.message
              : "Chưa kiểm tra được quyền quản trị.",
          );
        }
      }
    };
    void check();
    const timer = setInterval(check, 30000);
    return () => {
      alive = false;
      clearInterval(timer);
    };
  }, [repo, retry]);
  async function exit() {
    try {
      if (!demo) {
        const result = await client?.auth.signOut({ scope: "local" });
        if (result?.error) throw result.error;
      }
      setDemo(false);
      setUser(null);
      setVerified(false);
    } catch {
      setError("Chưa đăng xuất được. Hãy thử lại.");
    }
  }
  if (!ready)
    return (
      <div className="access-page">
        <Logo />
        <p>Đang mở Matlingo Admin…</p>
      </div>
    );
  if (!repo) return <Login onDemo={() => setDemo(true)} />;
  if (!verified)
    return (
      <div className="access-page">
        <Logo />
        <h1>{error ? "Chưa thể truy cập" : "Đang kiểm tra quyền Admin…"}</h1>
        {error && (
          <>
            <p role="alert">{error}</p>
            <button onClick={() => setRetry(retry + 1)}>Thử lại</button>
            <button onClick={exit}>Đăng xuất</button>
          </>
        )}
      </div>
    );
  return (
    <Dashboard
      key={repo.owner}
      repo={repo}
      email={user?.email ?? "Sandbox"}
      onExit={exit}
      onDenied={(message) => {
        setVerified(false);
        setError(message);
      }}
    />
  );
}
function Login({ onDemo }: { onDemo: () => void }) {
  const [email, setEmail] = useState(""),
    [password, setPassword] = useState(""),
    [busy, setBusy] = useState(false),
    [error, setError] = useState("");
  return (
    <main className="login-page">
      <section className="login-intro">
        <Logo />
        <span className="eyebrow">MATLINGO ADMIN · KHÔNG GIAN QUẢN TRỊ</span>
        <h1>
          Một nơi quản trị.
          <br />
          Mọi hành trình học.
        </h1>
        <p>
          Quản lý người học, chủ đề và nội dung. Mở Studio khi cần thiết kế bài
          học tương tác mới.
        </p>
        <div className="login-model">
          <Box size={100} strokeWidth={1} />
          <span>Quan sát → Thử nghiệm → Suy luận → Thử thách</span>
        </div>
        <small>Matlingo Admin · Quản lý người học, nội dung và Studio</small>
      </section>
      <section className="login-form">
        <span className="eyebrow">DÀNH CHO QUẢN TRỊ VIÊN</span>
        <h2>Chào mừng trở lại.</h2>
        <p>Đăng nhập bằng tài khoản quản trị của bạn.</p>
        <form
          onSubmit={async (ev) => {
            ev.preventDefault();
            if (!client || busy) return;
            setBusy(true);
            setError("");
            try {
              const { error } = await client.auth.signInWithPassword({
                email: email.trim(),
                password,
              });
              if (error)
                setError(
                  "Email hoặc mật khẩu không đúng, hoặc tài khoản chưa xác nhận.",
                );
            } catch {
              setError("Chưa kết nối được máy chủ.");
            } finally {
              setBusy(false);
            }
          }}
        >
          <label className="field">
            Email quản trị
            <input
              type="email"
              required
              autoComplete="username"
              value={email}
              onChange={(ev) => setEmail(ev.target.value)}
              disabled={busy}
            />
          </label>
          <label className="field">
            Mật khẩu
            <input
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(ev) => setPassword(ev.target.value)}
              disabled={busy}
            />
          </label>
          {(error || !configured) && (
            <p role="alert" className="warning">
              {error || "Chưa có cấu hình cloud. Bạn vẫn có thể mở sandbox."}
            </p>
          )}
          <button className="primary" disabled={busy || !configured}>
            {busy ? "Đang đăng nhập…" : "Đăng nhập Matlingo Admin"}
            <ArrowRight size={17} />
          </button>
        </form>
        <div className="login-divider">HOẶC KHÁM PHÁ TRƯỚC</div>
        <button onClick={onDemo}>
          Mở sandbox trải nghiệm
          <ChevronRight size={17} />
        </button>
        <small>
          Sandbox không thay đổi dữ liệu máy chủ và không ghi điểm học tập.
        </small>
      </section>
    </main>
  );
}
type Account = {
  id: string;
  display_name: string;
  email: string;
  status: string;
};
export function Dashboard({
  repo,
  email,
  onExit,
  onDenied,
}: {
  repo: Repository;
  email: string;
  onExit: () => void;
  onDenied: (s: string) => void;
}) {
  const [tab, setTab] = useState("overview"),
    [topics, setTopics] = useState<Topic[]>([]),
    [topicId, setTopicId] = useState(""),
    [lessons, setLessons] = useState<Lesson[]>([]),
    [editing, setEditing] = useState<Lesson | null>(null);
  const [overview, setOverview] = useState<Record<string, unknown>>({}),
    [accounts, setAccounts] = useState<Account[]>([]),
    [total, setTotal] = useState(0),
    [offset, setOffset] = useState(0),
    [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true),
    [busy, setBusy] = useState(false),
    [error, setError] = useState(""),
    [topicForm, setTopicForm] = useState<Topic | null>(null),
    [suspend, setSuspend] = useState<Account | null>(null),
    [progress, setProgress] = useState<{
      name: string;
      data: Record<string, unknown>;
    } | null>(null),
    [refresh, setRefresh] = useState(0);
  const operations = useRef(new Map<string, string>());
  const [showArchived, setShowArchived] = useState(false);
  const visibleTopics = topics.filter(
    (t) => showArchived || t.status !== "archived",
  );
  const [topicError, setTopicError] = useState("");
  const [success, setSuccess] = useState("");
  const openTopic = (value: Topic) => {
    setTopicError("");
    setTopicForm(clone(value));
  };
  const operation = (key: string) => {
    if (!operations.current.has(key))
      operations.current.set(key, crypto.randomUUID());
    return operations.current.get(key)!;
  };
  const report = (e: unknown) => {
    if (e instanceof CmsError && e.denied) onDenied(e.message);
    else setError(e instanceof Error ? e.message : "Chưa tải được dữ liệu.");
  };
  useEffect(() => {
    let alive = true;
    setLoading(true);
    setError("");
    Promise.all([repo.topics(), repo.dashboard("overview")])
      .then(([ts, ov]) => {
        if (alive) {
          setTopics(ts);
          setOverview(ov);
          setTopicId((id) =>
            ts.some((t) => t.id === id && t.status !== "archived")
              ? id
              : (ts.find((t) => t.status !== "archived")?.id ?? ""),
          );
        }
      })
      .catch((e) => {
        if (alive) report(e);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, [repo, refresh]);
  useEffect(() => {
    let alive = true;
    setLessons([]);
    if (!topicId) return;
    setLoading(true);
    repo
      .lessons(topicId)
      .then((rows) => {
        if (alive) setLessons(rows);
      })
      .catch((e) => {
        if (alive) report(e);
      })
      .finally(() => {
        if (alive) setLoading(false);
      });
    return () => {
      alive = false;
    };
  }, [repo, topicId, refresh]);
  useEffect(() => {
    if (tab !== "users") return;
    let alive = true;
    setLoading(true);
    const timer = setTimeout(() => {
      repo
        .dashboard("accounts", search, offset)
        .then((page) => {
          if (alive) {
            setAccounts(page.items as Account[]);
            setTotal(Number(page.total));
          }
        })
        .catch((e) => {
          if (alive) report(e);
        })
        .finally(() => {
          if (alive) setLoading(false);
        });
    }, 250);
    return () => {
      alive = false;
      clearTimeout(timer);
    };
  }, [repo, tab, search, offset, refresh]);
  const topic = topics.find((t) => t.id === topicId);
  if (editing)
    return (
      <Studio
        key={editing.id}
        initial={editing}
        topic={topic}
        library={lessons}
        repository={repo}
        onBack={() => {
          setEditing(null);
          setRefresh((n) => n + 1);
        }}
        onDenied={onDenied}
      />
    );
  return (
    <div className="dashboard">
      <aside className="nav-rail">
        <Logo />
        <div className="rail-section">WORKSPACE</div>
        {[
          ["overview", "Tổng quan", LayoutDashboard],
          ["users", "Người dùng & tiến độ", Users],
          ["topics", "Quản lý chủ đề", Layers],
          ["studio", "Studio soạn thảo", Box],
        ].map(([key, label, Icon]) => (
          <button
            key={String(key)}
            className={tab === key ? "active" : ""}
            onClick={() => {
              setTab(String(key));
              setSearch("");
              setOffset(0);
            }}
          >
            {typeof Icon !== "string" && <Icon size={18} />}
            <span>{String(label)}</span>
          </button>
        ))}
        <div className="rail-bottom">
          <span className="avatar">M</span>
          <div>
            <strong>{repo.demo ? "Không gian mẫu" : "Quản trị viên"}</strong>
            <small>{email}</small>
          </div>
          <button aria-label="Đăng xuất" onClick={onExit}>
            <LogOut size={17} />
          </button>
        </div>
      </aside>
      <main className="dashboard-main">
        <header className="dashboard-top">
          <span>
            Workspace <ChevronRight size={14} />{" "}
            {tab === "studio"
              ? "Studio soạn thảo"
              : tab === "users"
                ? "Người dùng"
                : tab === "topics"
                  ? "Chủ đề"
                  : "Tổng quan"}
          </span>
          <span className="badge">
            {repo.demo ? "SANDBOX · DỮ LIỆU MẪU" : "ADMIN WORKSPACE"}
          </span>
        </header>
        <div className="dashboard-content">
          {success && (
            <p className="tip" role="status">
              {success}
            </p>
          )}
          {error && (
            <p className="error" role="alert">
              {error}
              <button onClick={() => setRefresh((n) => n + 1)}>Tải lại</button>
            </p>
          )}
          <div className="page-title">
            <div>
              <span className="eyebrow">THIẾT KẾ CHO SỰ TÒ MÒ</span>
              <h1>
                {tab === "studio"
                  ? "Xưởng khám phá."
                  : tab === "users"
                    ? "Người học & hành trình."
                    : tab === "topics"
                      ? "Mỗi chủ đề, một thế giới."
                      : "Nhịp đập học tập."}
              </h1>
              <p>
                {tab === "studio"
                  ? "Biến một ý tưởng thành bài học có thể chạm và thử."
                  : "Quản lý nội dung và theo dõi hoạt động học tập trong cùng một không gian."}
              </p>
            </div>
            <button
              onClick={() => {
                const t = newTopic();
                t.subject = subjects[0];
                openTopic(t);
              }}
              className="primary"
            >
              <Plus size={17} />
              Tạo chủ đề mới
            </button>
          </div>
          {tab === "overview" ? (
            <>
              <div className="stat-grid">
                {[
                  ["Người học", "users"],
                  ["Đang hoạt động", "active_users"],
                  ["Chủ đề", "topics"],
                  ["Hoàn thành đã xác minh", "verified_completions"],
                ].map(([label, key]) => (
                  <article key={key}>
                    <span>{label}</span>
                    <strong>
                      {key === "topics"
                        ? topics.filter((t) => t.status === "active").length
                        : String(overview[key] ?? "—")}
                    </strong>
                  </article>
                ))}
              </div>
              <section className="welcome-panel">
                <Box size={50} />
                <div>
                  <h2>Bài học hay bắt đầu bằng một câu hỏi.</h2>
                  <p>
                    Mở Studio để chọn engine và lắp ghép trải nghiệm tiếp theo.
                  </p>
                  <button onClick={() => setTab("studio")}>
                    Vào Studio
                    <ArrowRight size={16} />
                  </button>
                </div>
              </section>
            </>
          ) : tab === "users" ? (
            <>
              <label className="search-field">
                <Search size={18} />
                <input
                  aria-label="Tìm người dùng"
                  maxLength={100}
                  placeholder="Tìm tên hoặc email…"
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setOffset(0);
                  }}
                />
              </label>
              <div className="table-scroll">
                <table>
                  <thead>
                    <tr>
                      <th>Người học</th>
                      <th>Email</th>
                      <th>Trạng thái</th>
                      <th>Thao tác</th>
                    </tr>
                  </thead>
                  <tbody>
                    {accounts.map((a) => (
                      <tr key={a.id}>
                        <td>{a.display_name || "Chưa đặt tên"}</td>
                        <td>{a.email}</td>
                        <td>
                          <span className="badge">{a.status}</span>
                        </td>
                        <td>
                          <button
                            disabled={busy}
                            onClick={async () => {
                              setBusy(true);
                              try {
                                setProgress({
                                  name: a.display_name,
                                  data: await repo.progress(a.id),
                                });
                              } catch (e) {
                                report(e);
                              } finally {
                                setBusy(false);
                              }
                            }}
                          >
                            Tiến độ
                          </button>
                          <button disabled={busy} onClick={() => setSuspend(a)}>
                            {a.status === "active" ? "Tạm khóa" : "Mở lại"}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                {!accounts.length && !loading && (
                  <p className="empty">Chưa có người dùng phù hợp.</p>
                )}
              </div>
              <div className="pagination">
                <button
                  disabled={!offset || loading}
                  onClick={() => setOffset(offset - 25)}
                >
                  Trước
                </button>
                <span>
                  {total ? offset + 1 : 0}–{Math.min(offset + 25, total)} /{" "}
                  {total}
                </span>
                <button
                  disabled={offset + 25 >= total || loading}
                  onClick={() => setOffset(offset + 25)}
                >
                  Sau
                </button>
              </div>
            </>
          ) : (
            <>
              <label>
                <input
                  type="checkbox"
                  checked={showArchived}
                  onChange={(e) => {
                    setShowArchived(e.target.checked);
                    if (!e.target.checked && topic?.status === "archived")
                      setTopicId(
                        topics.find((t) => t.status !== "archived")?.id ?? "",
                      );
                  }}
                />{" "}
                Hiển thị nội dung đã lưu trữ
              </label>
              <div className="library-toolbar">
                <button
                  disabled={!topic || busy}
                  onClick={() => topic && openTopic(topic)}
                >
                  Chỉnh sửa chủ đề đang chọn
                </button>
                <div className="topic-select">
                  <span>CHỦ ĐỀ ĐANG MỞ</span>
                  <select
                    aria-label="Chọn chủ đề"
                    value={topicId}
                    onChange={(e) => setTopicId(e.target.value)}
                  >
                    {visibleTopics.map((t) => (
                      <option value={t.id} key={t.id}>
                        {t.title}
                      </option>
                    ))}
                  </select>
                </div>
                <label className="search-field">
                  <Search size={17} />
                  <input
                    aria-label="Tìm nội dung"
                    placeholder="Tìm bài học, chủ đề…"
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                  />
                </label>
              </div>
              {tab === "topics" ? (
                <div className="topic-grid">
                  {visibleTopics
                    .filter((t) =>
                      `${t.title} ${t.subject}`
                        .toLowerCase()
                        .includes(search.toLowerCase()),
                    )
                    .map((t) => (
                      <article key={t.id}>
                        <span className="badge">{t.subject}</span>
                        <h2>{t.title}</h2>
                        <p>{t.subtitle}</p>
                        <footer>
                          <span>
                            {t.status} · {t.activity_count ?? 0} bài
                          </span>
                          <button onClick={() => openTopic(t)}>
                            Chỉnh sửa
                          </button>
                          <button
                            onClick={() => {
                              setTopicId(t.id);
                              setTab("studio");
                            }}
                          >
                            Mở Studio
                            <ArrowRight size={14} />
                          </button>
                        </footer>
                      </article>
                    ))}
                </div>
              ) : (
                <>
                  <section className="recipe-banner">
                    <div className="recipe-icon">
                      <Box size={30} />
                    </div>
                    <div>
                      <span className="eyebrow">
                        BẮT ĐẦU VỚI MỘT KHUNG GIÁO ÁN
                      </span>
                      <h2>Quan sát. Thử nghiệm. Tự tìm ra.</h2>
                      <p>
                        4 bước khám phá · {Object.keys(engines).length} engine
                        tương tác · Xem trước tức thì
                      </p>
                    </div>
                    <button
                      className="primary"
                      disabled={!topic || loading}
                      onClick={() => topic && setEditing(topicRecipe(topic))}
                    >
                      Tạo bài học
                      <Plus size={17} />
                    </button>
                  </section>
                  <div className="section-title">
                    <h2>
                      Bài học trong chủ đề <span>{lessons.length}</span>
                    </h2>
                    <button
                      onClick={() => setRefresh((n) => n + 1)}
                      disabled={loading}
                    >
                      Làm mới
                    </button>
                  </div>
                  <div className="lesson-grid">
                    {lessons
                      .filter((d) => showArchived || d.status !== "archived")
                      .filter((d) =>
                        `${d.title} ${d.prompt}`
                          .toLowerCase()
                          .includes(search.toLowerCase()),
                      )
                      .map((d, i) => (
                        <button
                          className="lesson-card"
                          key={d.id}
                          onClick={() => setEditing(d)}
                        >
                          <div className={`lesson-art art-${i % 3}`}>
                            <LessonIcon lesson={d} size={62} />
                            <span>{String(i + 1).padStart(2, "0")}</span>
                          </div>
                          <div className="lesson-card-body">
                            <span className="eyebrow">
                              {d.builder_status === "published"
                                ? "ĐÃ PHÁT HÀNH"
                                : "BẢN NHÁP"}{" "}
                              · {d.config.slides?.length ?? 1} BƯỚC
                            </span>
                            <h3>{d.title}</h3>
                            <p>{d.prompt}</p>
                            <footer>
                              <span>{d.stage}</span>
                              <ArrowRight size={18} />
                            </footer>
                          </div>
                        </button>
                      ))}
                  </div>
                  {!lessons.length && !loading && (
                    <p className="empty">
                      <BookOpen />
                      Chủ đề chưa có bài học. Tạo bài đầu tiên từ khung giáo án.
                    </p>
                  )}
                </>
              )}
            </>
          )}
          {loading && <p role="status">Đang tải…</p>}
        </div>
      </main>
      {topicForm && (
        <Dialog
          title={
            topics.some((t) => t.id === topicForm.id)
              ? "Chỉnh sửa chủ đề"
              : "Tạo chủ đề mới"
          }
          onClose={() => !busy && setTopicForm(null)}
        >
          <form
            onSubmit={async (e) => {
              e.preventDefault();
              if (busy || !topicForm.title.trim()) return;
              setBusy(true);
              const key = JSON.stringify(topicForm);
              try {
                await repo.saveTopic(topicForm, operation(key));
                operations.current.delete(key);
                setTopicError("");
                setSuccess(`Đã lưu chủ đề “${topicForm.title.trim()}”.`);
                setTopicForm(null);
                setTopicId(topicForm.id);
                setRefresh((n) => n + 1);
                setTab("studio");
              } catch (e) {
                setTopicError(
                  e instanceof Error
                    ? e.message
                    : "Chưa lưu được chủ đề. Hãy thử lại.",
                );
                report(e);
              } finally {
                setBusy(false);
              }
            }}
          >
            <fieldset disabled={busy}>
              {topicError && (
                <p className="error" role="alert">
                  {topicError}
                </p>
              )}
              <Field
                label="Tên chủ đề"
                value={topicForm.title}
                max={160}
                onChange={(v) => setTopicForm({ ...topicForm, title: v })}
              />
              <Field
                label="Mô tả"
                value={topicForm.subtitle}
                max={1000}
                area
                onChange={(v) => setTopicForm({ ...topicForm, subtitle: v })}
              />
              <label className="field">
                Lĩnh vực
                <select
                  value={topicForm.subject}
                  onChange={(e) =>
                    setTopicForm({ ...topicForm, subject: e.target.value })
                  }
                >
                  {[...new Set([topicForm.subject, ...subjects])].map((s) => (
                    <option key={s}>{s}</option>
                  ))}
                </select>
              </label>
              <label className="field">
                Trạng thái
                <select
                  value={topicForm.status}
                  onChange={(e) =>
                    setTopicForm({ ...topicForm, status: e.target.value })
                  }
                >
                  {["draft", "active", "archived"].map((s) => (
                    <option key={s}>{s}</option>
                  ))}
                </select>
              </label>
              <Field
                label="Thứ tự chủ đề"
                type="number"
                min={0}
                value={topicForm.sort_order}
                onChange={(v) =>
                  setTopicForm({ ...topicForm, sort_order: Number(v) })
                }
              />
              <p className="tip">
                Bài mới được gợi ý khung 4 bước phù hợp lĩnh vực đã chọn. Nội
                dung mẫu cần được biên soạn trước khi phát hành.
              </p>
              <button className="primary" disabled={!topicForm.title.trim()}>
                {busy ? "Đang lưu…" : "Lưu chủ đề"}
              </button>
            </fieldset>
          </form>
        </Dialog>
      )}
      {suspend && (
        <Dialog
          title={
            suspend.status === "active"
              ? "Tạm khóa tài khoản?"
              : "Mở lại tài khoản?"
          }
          onClose={() => !busy && setSuspend(null)}
        >
          <p>{suspend.email} · Lịch sử học được giữ nguyên.</p>
          <button
            className="primary"
            disabled={busy}
            onClick={async () => {
              setBusy(true);
              const status =
                  suspend.status === "active" ? "suspended" : "active",
                key = `${suspend.id}:${status}`;
              try {
                await repo.setAccountStatus(suspend.id, status, operation(key));
                operations.current.delete(key);
                setSuspend(null);
                setRefresh((n) => n + 1);
              } catch (e) {
                report(e);
              } finally {
                setBusy(false);
              }
            }}
          >
            Xác nhận
          </button>
        </Dialog>
      )}
      {progress && (
        <Dialog
          title={`Tiến độ · ${progress.name}`}
          onClose={() => setProgress(null)}
        >
          <div className="stat-grid">
            {Object.entries(progress.data)
              .filter(([, v]) => typeof v === "number")
              .map(([key, v]) => (
                <article key={key}>
                  <span>
                    {{
                      profiles: "Hồ sơ học",
                      sessions: "Phiên học",
                      verified_completions: "Chủ đề hoàn thành",
                      verified_xp: "XP đã xác minh",
                    }[key] ?? key}
                  </span>
                  <strong>{String(v)}</strong>
                </article>
              ))}
          </div>
        </Dialog>
      )}
    </div>
  );
}
