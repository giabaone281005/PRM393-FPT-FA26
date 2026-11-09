import { prepareAsset } from "./assets";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  clone,
  normalizeLesson,
  payload,
  templateLesson,
  uid,
  type Lesson,
  type Topic,
  type Slide,
} from "./domain";

export type Message = { role: "user" | "assistant"; content: string };
export class CmsError extends Error {
  constructor(
    message: string,
    public denied = false,
    public conflict = false,
  ) {
    super(message);
  }
}
export interface Repository {
  readonly demo: boolean;
  owner: string;
  access(): Promise<void>;
  topics(): Promise<Topic[]>;
  dashboard(
    section: "overview" | "accounts",
    search?: string,
    offset?: number,
  ): Promise<Record<string, unknown>>;
  setAccountStatus(
    id: string,
    status: string,
    operation: string,
  ): Promise<void>;
  progress(id: string): Promise<Record<string, unknown>>;
  uploadAsset(file: File): Promise<string>;
  lessons(topic: string): Promise<Lesson[]>;
  saveDraft(doc: Lesson, revision: number, operation: string): Promise<number>;
  publish(
    doc: Lesson,
    revision: number,
    draftRevision: number,
    operation: string,
  ): Promise<number>;
  saveTopic(topic: Topic, operation: string): Promise<void>;
  chat(messages: Message[], lesson: Lesson): Promise<string>;
  generate(
    prompt: string,
    topic: string,
    design: Lesson["config"],
  ): Promise<Slide[]>;
}
export const configured =
  !!import.meta.env.VITE_SUPABASE_URL &&
  !!import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
export const client = configured
  ? createClient(
      import.meta.env.VITE_SUPABASE_URL,
      import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
      {
        auth: {
          storageKey: "matlingo-studio-auth",
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: false,
        },
      },
    )
  : null;

export class SupabaseRepository implements Repository {
  readonly demo = false;
  constructor(
    private db: SupabaseClient,
    public owner: string,
  ) {}
  private async rpc<T>(
    name: string,
    args: Record<string, unknown>,
  ): Promise<T> {
    // Stale requests cannot acknowledge a different account's changes.
    if ((await this.db.auth.getSession()).data.session?.user.id !== this.owner)
      throw new CmsError("Phiên đăng nhập đã thay đổi.", true);
    const { data, error } = await this.db
      .rpc(name, args)
      .abortSignal(AbortSignal.timeout(25000));
    if (error) {
      if (["42501", "PGRST301", "PGRST303"].includes(error.code))
        throw new CmsError(
          "Quyền quản trị hoặc phiên đăng nhập đã thay đổi.",
          true,
        );
      if (error.code === "PT409")
        throw new CmsError(
          "Bài đã được sửa ở nơi khác. Xuất bản sao để giữ thay đổi, rồi tải lại bản máy chủ.",
          false,
          true,
        );
      throw new CmsError(
        "Chưa lưu được dữ liệu. Kiểm tra nội dung và kết nối rồi thử lại.",
      );
    }
    if ((await this.db.auth.getSession()).data.session?.user.id !== this.owner)
      throw new CmsError("Phiên đăng nhập đã thay đổi.", true);
    return data as T;
  }
  async access() {
    const rows = await this.rpc<{ role: string; status: string }[]>(
      "get_my_access",
      {},
    );
    if (
      rows.length !== 1 ||
      rows[0].role !== "admin" ||
      rows[0].status !== "active"
    )
      throw new CmsError("Chỉ Admin đang hoạt động được truy cập CMS.", true);
  }
  async dashboard(section: "overview" | "accounts", search = "", offset = 0) {
    return this.rpc<Record<string, unknown>>("admin_dashboard_read", {
      section,
      search_text: search,
      page_offset: offset,
      page_size: 25,
    });
  }
  async setAccountStatus(id: string, status: string, operation: string) {
    await this.rpc("admin_learning_mutate", {
      operation_id: operation,
      operation_type: "account.status",
      payload: { id, status },
    });
  }
  async progress(id: string) {
    return this.rpc<Record<string, unknown>>("admin_studio_progress", {
      account_id: id,
    });
  }
  async uploadAsset(file: File) {
    const { body, extension } = await prepareAsset(file);
    await this.access();
    const path = `${this.owner}/${crypto.randomUUID()}.${extension}`;
    const { error } = await this.db.storage
      .from("lesson-assets")
      .upload(path, body, {
        contentType: body.type,
        upsert: false,
        cacheControl: "31536000",
      });
    if (error)
      throw new CmsError(
        "Chưa tải được ảnh. Kiểm tra kết nối và quyền Storage rồi thử lại.",
      );
    if ((await this.db.auth.getSession()).data.session?.user.id !== this.owner)
      throw new CmsError("Phiên đăng nhập đã thay đổi.", true);
    return this.db.storage.from("lesson-assets").getPublicUrl(path).data
      .publicUrl;
  }
  async topics() {
    const rows: Topic[] = [];
    let total = 1;
    while (rows.length < total) {
      const page = await this.rpc<{ items: Topic[]; total: number }>(
        "admin_dashboard_read",
        {
          section: "topics",
          search_text: "",
          page_offset: rows.length,
          page_size: 100,
        },
      );
      total = page.total;
      rows.push(...page.items);
      if (!page.items.length) break;
    }
    return rows;
  }
  async lessons(topic: string) {
    const [content, drafts] = await Promise.all([
      this.rpc<{ items: Record<string, unknown>[] }>("admin_content_read", {
        topic,
      }),
      this.rpc<{ items: Record<string, unknown>[] }>("admin_builder_read", {
        topic,
      }),
    ]);
    const rows = new Map<string, Lesson>(
      content.items.map((row) => [
        String(row.activity_id),
        { ...normalizeLesson(row, topic), builder_status: "published" },
      ]),
    );
    for (const row of drafts.items) {
      const id = String(row.id),
        published = rows.get(id);
      // A saved draft is authoritative until explicitly published.
      if (row.builder_status === "draft" || !published)
        rows.set(id, {
          ...normalizeLesson(row, topic),
          content_version:
            published?.content_version ?? Number(row.content_version ?? 0),
          published_snapshot: published,
        });
      else
        rows.set(id, {
          ...published,
          draft_revision: Number(row.draft_revision),
          builder_status: "published",
        });
    }
    return [...rows.values()].sort((a, b) => a.sort_order - b.sort_order);
  }
  async saveDraft(doc: Lesson, revision: number, operation: string) {
    const result = await this.rpc<{ revision: number }>("admin_builder_save", {
      operation_id: operation,
      payload: { ...payload(doc), revision },
    });
    return result.revision;
  }
  async publish(
    doc: Lesson,
    revision: number,
    draftRevision: number,
    operation: string,
  ) {
    await this.rpc("admin_content_mutate", {
      operation_id: operation,
      payload: { ...payload(doc), revision, builder_revision: draftRevision },
    });
    return revision + 1;
  }
  async saveTopic(topic: Topic, operation: string) {
    if (
      !topic.title.trim() ||
      topic.title.trim().length > 160 ||
      !topic.subject.trim() ||
      !Number.isInteger(topic.sort_order) ||
      topic.sort_order < 0
    )
      throw new CmsError(
        "Điền tên, lĩnh vực và thứ tự nguyên không âm cho chủ đề.",
      );
    await this.rpc("admin_learning_mutate", {
      operation_id: operation,
      operation_type: "topic.save",
      payload: {
        id: topic.id,
        title: topic.title.trim(),
        subtitle: topic.subtitle ?? "",
        subject: topic.subject.trim(),
        status: topic.status,
        sort_order: topic.sort_order,
        icon_key: topic.icon_key || "menu_book_outlined",
        action_label: topic.action_label ?? "Khám phá",
      },
    });
  }
  private async invoke(name: string, body: Record<string, unknown>) {
    await this.access();
    const result = await this.db.functions.invoke(name, {
      body,
      signal: AbortSignal.timeout(60000),
    });
    if (result.error) {
      const status = result.error.context?.status;
      if (status === 401 || status === 403)
        throw new CmsError(
          "Phiên đăng nhập hoặc quyền Admin không còn hợp lệ.",
          true,
        );
      throw new CmsError(
        status === 429
          ? "Gemini đang bận hoặc đã đạt giới hạn. Chờ một phút rồi thử lại."
          : "Chưa nhận được phản hồi từ Gemini. Nội dung hiện tại được giữ nguyên.",
      );
    }
    if ((await this.db.auth.getSession()).data.session?.user.id !== this.owner)
      throw new CmsError("Phiên đăng nhập đã thay đổi.", true);
    return result.data;
  }
  async chat(messages: Message[], lesson: Lesson) {
    const result = await this.invoke("tutor-chat", {
      messages: messages.slice(-30),
      canvas: {
        purpose:
          "Admin đang biên soạn bài học; hỗ trợ kiến thức và gợi ý sư phạm.",
        title: lesson.title,
        components: lesson.config.slides ?? [],
        goal: lesson.prompt,
      },
    });
    if (typeof result.text !== "string")
      throw new CmsError("Gemini chưa trả lời được. Hãy thử lại.");
    return result.text as string;
  }
  async generate(prompt: string, topic: string, design: Lesson["config"]) {
    const result = await this.invoke("author-lesson", {
      prompt,
      topic,
      design,
    });
    if (!Array.isArray(result.draft?.slides))
      throw new CmsError("Gemini chưa tạo được cấu trúc hợp lệ.");
    return result.draft.slides as Slide[];
  }
}

// Explicit sandbox: never constructs an authenticated client or issues network writes.
export class DemoRepository implements Repository {
  readonly demo = true;
  owner = "demo";
  private documents = new Map<string, Lesson>();
  private operations = new Map<string, number>();
  private catalog: Topic[] = [
    {
      id: "demo-math",
      title: "Tư duy toán học",
      subtitle: "Khám phá quy luật bằng trực giác.",
      subject: "Toán học",
      status: "active",
      sort_order: 0,
      icon_key: "functions",
    },
  ];
  constructor() {
    const doc = templateLesson("demo-math", "graph");
    this.documents.set(doc.id, doc);
  }
  async access() {}
  async dashboard(section: "overview" | "accounts") {
    return section === "overview"
      ? {
          users: 0,
          active_users: 0,
          topics: this.catalog.length,
          verified_completions: 0,
        }
      : { items: [], total: 0 };
  }
  async setAccountStatus() {
    throw new CmsError("Sandbox không thay đổi tài khoản thật.");
  }
  async progress() {
    return { profiles: [], sessions: [] };
  }
  async uploadAsset(file: File): Promise<string> {
    const { body } = await prepareAsset(file);
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(String(reader.result));
      reader.onerror = () => reject(new CmsError("Không đọc được ảnh."));
      reader.readAsDataURL(body);
    });
  }
  async topics() {
    return clone(this.catalog);
  }
  async lessons(topic: string) {
    return clone(
      [...this.documents.values()].filter((d) => d.topic_id === topic),
    );
  }
  async saveDraft(doc: Lesson, revision: number, operation: string) {
    if (this.operations.has(operation)) return this.operations.get(operation)!;
    const previous = this.documents.get(doc.id);
    if ((previous?.draft_revision ?? 0) !== revision)
      throw new CmsError("Bản nháp đã thay đổi.", false, true);
    this.documents.set(doc.id, {
      ...clone(doc),
      draft_revision: revision + 1,
      builder_status: "draft",
    });
    this.operations.set(operation, revision + 1);
    return revision + 1;
  }
  async publish(
    doc: Lesson,
    revision: number,
    draftRevision: number,
    operation: string,
  ) {
    if (this.operations.has(operation)) return this.operations.get(operation)!;
    const previous = this.documents.get(doc.id);
    if (
      (previous?.content_revision ?? 0) !== revision ||
      previous?.draft_revision !== draftRevision
    )
      throw new CmsError("Bản nháp đã thay đổi.", false, true);
    this.documents.set(doc.id, {
      ...clone(doc),
      draft_revision: draftRevision,
      content_revision: revision + 1,
      builder_status: "published",
    });
    this.operations.set(operation, revision + 1);
    return revision + 1;
  }
  async saveTopic(topic: Topic) {
    this.catalog = [
      ...this.catalog.filter((t) => t.id !== topic.id),
      clone(topic),
    ];
  }
  async chat() {
    return "Đây là không gian trải nghiệm, chưa gọi Gemini thật. Đăng nhập bằng tài khoản Admin để hỏi kiến thức và soạn bài cùng Gemini. Bạn vẫn có thể kéo thả, chỉnh các khối và thử bài trên điện thoại bên cạnh.";
  }
  async generate(
    _prompt: string,
    _topic: string,
    _design: Lesson["config"],
  ): Promise<Slide[]> {
    throw new CmsError("Đăng nhập Admin để dùng Gemini thật.");
  }
}
export function newTopic(): Topic {
  return {
    id: uid("topic"),
    title: "",
    subtitle: "",
    subject: "Toán học",
    status: "draft",
    sort_order: 0,
    icon_key: "menu_book_outlined",
    action_label: "Khám phá",
  };
}
