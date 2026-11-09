// @vitest-environment jsdom
import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import {
  cleanup,
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { templateLesson, type Lesson } from "./domain";
import { DemoRepository } from "./repository";
import { Studio } from "./Studio";
import { Dashboard } from "./App";

beforeAll(() => {
  HTMLDialogElement.prototype.showModal = function () {
    this.setAttribute("open", "");
  };
  HTMLDialogElement.prototype.close = function () {
    this.removeAttribute("open");
  };
});
beforeEach(() => localStorage.clear());
afterEach(cleanup);
function open(
  repo = new DemoRepository(),
  doc = templateLesson("math", "graph"),
) {
  const onDenied = vi.fn();
  render(
    <Studio
      initial={doc}
      topic={{
        id: "math",
        title: "Toán",
        subject: "Hình học",
        subtitle: "",
        status: "active",
        sort_order: 0,
        icon_key: "functions",
      }}
      repository={repo}
      onBack={vi.fn()}
      onDenied={onDenied}
    />,
  );
  return { repo, doc, onDenied };
}
const phone = () =>
  within(document.querySelector(".phone-device") as HTMLElement);
const count = () => document.querySelectorAll(".flow-node").length;
function transfer() {
  const m = new Map<string, string>();
  return {
    setData: (k: string, v: string) => m.set(k, v),
    getData: (k: string) => m.get(k) ?? "",
  };
}
describe("new four-column Studio", () => {
  it("selects, undoes, saves and publishes the lesson icon", async () => {
    const { repo } = open();
    const publish = vi.spyOn(repo, "publish");
    fireEvent.click(screen.getByText("Chọn icon bài học"));
    fireEvent.click(screen.getByRole("button", { name: "Chọn icon Robot" }));
    fireEvent.click(screen.getByLabelText("Hoàn tác"));
    expect(
      screen
        .getByRole("button", { name: "Tự động theo engine" })
        .getAttribute("aria-pressed"),
    ).toBe("true");
    fireEvent.click(screen.getByRole("button", { name: "Chọn icon Robot" }));
    fireEvent.click(screen.getByRole("button", { name: "Phát hành" }));
    fireEvent.click(screen.getByRole("button", { name: /Xác nhận phát hành/ }));
    await waitFor(() => expect(publish).toHaveBeenCalledTimes(1));
    expect(publish.mock.calls[0][0].config.lesson_icon).toBe("robot");
    expect(
      (await repo.lessons("math")).find(
        (l) => l.id === publish.mock.calls[0][0].id,
      )?.config.lesson_icon,
    ).toBe("robot");
  });

  it("explicitly converts a packaged lesson so new engines can be inserted, with undo preserving the original", () => {
    const doc = templateLesson("math", "blank");
    doc.mechanism = "solidExplorer";
    doc.content_version = 1;
    doc.config = { target_volume: 12 };
    const original = structuredClone(doc);
    open(new DemoRepository(), doc);
    expect(count()).toBe(0);
    fireEvent.click(
      screen.getByRole("button", {
        name: "Soạn lại bằng Studio và thêm engine",
      }),
    );
    fireEvent.click(screen.getByRole("button", { name: "Chuyển sang Studio" }));
    expect(count()).toBe(2);
    fireEvent.click(screen.getByRole("button", { name: /Dựng biểu đồ cột/ }));
    expect(count()).toBe(3);
    fireEvent.click(screen.getByLabelText("Hoàn tác"));
    fireEvent.click(screen.getByLabelText("Hoàn tác"));
    expect(count()).toBe(0);
    expect(doc).toEqual(original);
  });
  it("edits, saves and publishes an existing reasoned-choice lesson including its correct answers", async () => {
    const doc = templateLesson("math", "blank");
    doc.mechanism = "reasonedChoice";
    doc.config = {
      knowledge: "Kiến thức ban đầu",
      choices: ["A", "B"],
      reasons: ["Lý do A", "Lý do B"],
      answer: 0,
      reason: 0,
      source: "",
    };
    const { repo } = open(new DemoRepository(), doc),
      publish = vi.spyOn(repo, "publish");
    fireEvent.change(screen.getByLabelText("Tên bài học"), {
      target: { value: "Bài hiện có đã chỉnh" },
    });
    fireEvent.change(screen.getByLabelText("Kiến thức cốt lõi"), {
      target: { value: "Kiến thức mới" },
    });
    fireEvent.change(screen.getByLabelText("Đáp án đúng"), {
      target: { value: "1" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Phát hành" }));
    fireEvent.click(screen.getByRole("button", { name: /Xác nhận phát hành/ }));
    await waitFor(() => expect(publish).toHaveBeenCalledTimes(1));
    expect(publish.mock.calls[0][0].config.answer).toBe(1);
    expect(publish.mock.calls[0][0].title).toBe("Bài hiện có đã chỉnh");
    expect(publish.mock.calls[0][2]).toBe(1);
  });
  it("adds and reorders through drag/drop, undo, redo, duplication and deletion", () => {
    open();
    expect(count()).toBe(4);
    const data = transfer();
    fireEvent.dragStart(screen.getByRole("button", { name: /Xưởng khối 3D/ }), {
      dataTransfer: data,
    });
    fireEvent.drop(screen.getByTestId("drop-1"), { dataTransfer: data });
    expect(count()).toBe(5);
    expect(screen.getByLabelText("Thể tích mục tiêu")).toBeTruthy();
    fireEvent.click(screen.getByLabelText("Hoàn tác"));
    expect(count()).toBe(4);
    fireEvent.click(screen.getByLabelText("Làm lại"));
    expect(count()).toBe(5);
    fireEvent.click(screen.getByLabelText("Đưa slide 2 lên"));
    expect(document.querySelector(".flow-node")!.textContent).toContain(
      "Xưởng khối 3D",
    );
    fireEvent.click(screen.getByLabelText("Nhân bản slide 1"));
    expect(count()).toBe(6);
    fireEvent.click(screen.getByLabelText("Xóa slide 2"));
    expect(count()).toBe(5);
  });
  it("updates the simulator immediately and evaluates real graph answers", () => {
    open();
    fireEvent.click(screen.getByLabelText("Chọn slide 2"));
    fireEvent.change(screen.getByLabelText("Tiêu đề slide"), {
      target: { value: "Đường thẳng của tôi" },
    });
    expect(phone().getByText("Đường thẳng của tôi")).toBeTruthy();
    fireEvent.click(phone().getByRole("button", { name: /Kiểm tra/ }));
    expect(phone().getByText(/Chưa đúng/)).toBeTruthy();
    fireEvent.change(phone().getByLabelText("Thay đổi a"), {
      target: { value: "2" },
    });
    fireEvent.change(phone().getByLabelText("Thay đổi b"), {
      target: { value: "1" },
    });
    fireEvent.click(phone().getByRole("button", { name: /Kiểm tra/ }));
    expect(phone().getByText("Chính xác!")).toBeTruthy();
  });
  it("keeps malformed inspector edits visible without crashing the simulator", () => {
    open();
    fireEvent.click(screen.getByRole("button", { name: /Sắp xếp quy trình/ }));
    fireEvent.change(
      screen.getByLabelText("Thứ tự chỉ số đúng (bắt đầu từ 0)"),
      { target: { value: "0, 0" } },
    );
    expect(phone().getByText(/Hoàn thiện cấu hình hợp lệ/)).toBeTruthy();
    expect(
      screen.getAllByText(/kiểm tra nội dung, đáp án/).length,
    ).toBeGreaterThan(0);
  });
  it("reviews AI content before inserting a new slide and allows undo", async () => {
    const { repo } = open();
    vi.spyOn(repo, "chat").mockResolvedValue(
      "Thử quan sát một hộp có ba chiều.",
    );
    fireEvent.click(screen.getByRole("button", { name: "Trợ lý AI" }));
    fireEvent.change(screen.getByLabelText("Nhắn Gemini"), {
      target: { value: "Gợi ý một thí nghiệm" },
    });
    fireEvent.click(screen.getByRole("button", { name: /Gửi câu hỏi/ }));
    await waitFor(() =>
      expect(
        screen.getByRole("button", { name: "Duyệt và chèn vào bài" }),
      ).toBeTruthy(),
    );
    fireEvent.click(
      screen.getByRole("button", { name: "Duyệt và chèn vào bài" }),
    );
    expect(count()).toBe(4);
    fireEvent.click(
      screen.getByRole("button", { name: "Áp dụng vào slide mới" }),
    );
    expect(count()).toBe(5);
    fireEvent.click(screen.getByRole("button", { name: "Đóng" }));
    fireEvent.click(screen.getByLabelText("Hoàn tác"));
    expect(count()).toBe(4);
  });
  it("awaits the saved draft and retries a publication with identical IDs and payload", async () => {
    const { repo } = open();
    const actual = repo.publish.bind(repo);
    let lost = true;
    const publish = vi
      .spyOn(repo, "publish")
      .mockImplementation(async (...args) => {
        const rev = await actual(...args);
        if (lost) {
          lost = false;
          throw new Error("Lost acknowledgement");
        }
        return rev;
      });
    const save = vi.spyOn(repo, "saveDraft");
    fireEvent.click(screen.getByRole("button", { name: "Phát hành" }));
    fireEvent.click(screen.getByRole("button", { name: /Xác nhận phát hành/ }));
    await waitFor(() => expect(publish).toHaveBeenCalledTimes(1));
    expect(save).toHaveBeenCalledTimes(1);
    await waitFor(() =>
      expect(
        screen
          .getByRole("button", { name: /Xác nhận phát hành/ })
          .hasAttribute("disabled"),
      ).toBe(false),
    );
    fireEvent.click(screen.getByRole("button", { name: /Xác nhận phát hành/ }));
    await waitFor(() => expect(publish).toHaveBeenCalledTimes(2));
    expect(publish.mock.calls[1]).toEqual(publish.mock.calls[0]);
  });
  it("uploads to the selected slide and preserves the asset when selecting another slide", async () => {
    const { repo } = open();
    const upload = vi
      .spyOn(repo, "uploadAsset")
      .mockResolvedValue("https://images.example/illustration.png");
    fireEvent.change(screen.getByLabelText("Tải ảnh minh họa"), {
      target: {
        files: [new File(["image"], "hộp.png", { type: "image/png" })],
      },
    });
    await waitFor(() => expect(upload).toHaveBeenCalledTimes(1));
    await waitFor(() =>
      expect(screen.getByLabelText("URL hình ảnh HTTPS")).toHaveProperty(
        "value",
        "https://images.example/illustration.png",
      ),
    );
    expect(screen.getByLabelText("Mô tả ảnh")).toHaveProperty("value", "hộp");
  });
  it("restores an owner-scoped unsaved design after remount", () => {
    const doc = templateLesson("math", "blank");
    const cached = structuredClone(doc);
    cached.title = "Thiết kế chưa đồng bộ";
    localStorage.setItem(
      `matlingo-studio-v2:demo:${doc.id}`,
      JSON.stringify({ document: cached, revision: 0, contentRevision: 0 }),
    );
    open(new DemoRepository(), doc);
    fireEvent.click(screen.getByRole("button", { name: "Khôi phục" }));
    expect(document.querySelector(".flow-intro h1")!.textContent).toBe(
      cached.title,
    );
  });
});
it("edits an existing topic, displays save errors inside its dialog, and retries without creating a duplicate", async () => {
  const repo = new DemoRepository(),
    save = vi
      .spyOn(repo, "saveTopic")
      .mockRejectedValueOnce(new Error("Mất kết nối, thử lại."));
  render(
    <Dashboard
      repo={repo}
      email="Sandbox"
      onExit={vi.fn()}
      onDenied={vi.fn()}
    />,
  );
  fireEvent.click(screen.getByRole("button", { name: "Studio soạn thảo" }));
  await waitFor(() =>
    expect(
      screen
        .getByRole("button", { name: "Chỉnh sửa chủ đề đang chọn" })
        .hasAttribute("disabled"),
    ).toBe(false),
  );
  fireEvent.click(
    screen.getByRole("button", { name: "Chỉnh sửa chủ đề đang chọn" }),
  );
  fireEvent.change(screen.getByLabelText("Tên chủ đề"), {
    target: { value: "Chủ đề đã sửa" },
  });
  fireEvent.click(screen.getByRole("button", { name: "Lưu chủ đề" }));
  await waitFor(() =>
    expect(
      within(screen.getByRole("dialog")).getByRole("alert").textContent,
    ).toContain("Mất kết nối"),
  );
  expect(screen.getByLabelText("Tên chủ đề")).toHaveProperty(
    "value",
    "Chủ đề đã sửa",
  );
  fireEvent.click(screen.getByRole("button", { name: "Lưu chủ đề" }));
  await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
  expect(save).toHaveBeenCalledTimes(2);
  const topics = await repo.topics();
  expect(topics).toHaveLength(1);
  expect(topics[0].title).toBe("Chủ đề đã sửa");
});
it("new dashboard creates a topic, recommends a four-step lesson and opens the new Studio", async () => {
  const repo = new DemoRepository();
  render(
    <Dashboard
      repo={repo}
      email="Sandbox"
      onExit={vi.fn()}
      onDenied={vi.fn()}
    />,
  );
  fireEvent.click(screen.getByRole("button", { name: "Studio soạn thảo" }));
  await waitFor(() =>
    expect(
      screen
        .getByRole("button", { name: /Tạo bài học/ })
        .hasAttribute("disabled"),
    ).toBe(false),
  );
  fireEvent.click(screen.getByRole("button", { name: /Tạo chủ đề mới/ }));
  fireEvent.change(screen.getByLabelText("Tên chủ đề"), {
    target: { value: "Không gian 3D" },
  });
  fireEvent.click(screen.getByRole("button", { name: "Lưu chủ đề" }));
  await waitFor(() => expect(screen.queryByRole("dialog")).toBeNull());
  await waitFor(() =>
    expect(
      (screen.getByLabelText("Chọn chủ đề") as HTMLSelectElement)
        .selectedOptions[0].text,
    ).toBe("Không gian 3D"),
  );
  fireEvent.click(screen.getByRole("button", { name: /Tạo bài học/ }));
  expect(count()).toBe(4);
  expect(document.querySelectorAll(".studio-columns>aside")).toHaveLength(3);
  expect(
    screen.getByRole("button", { name: /Xưởng khối 3D/ }).className,
  ).toContain("recommended");
});
