// @vitest-environment jsdom
import { afterEach, expect, it } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { LessonIconPicker, lessonIcons, lessonIconKey } from "./lesson-icons";
import { payload, templateLesson, newSlide } from "./domain";
afterEach(cleanup);
it("uses safe engine defaults and preserves explicit icons through the publication payload", () => {
  const d = templateLesson("math", "blank");
  d.config.slides = [newSlide("robotRoute")];
  expect(Object.keys(lessonIcons)).toHaveLength(24);
  expect(lessonIconKey(d)).toBe("robot");
  d.config.lesson_icon = "coins";
  expect(lessonIconKey(d)).toBe("coins");
  expect(payload(d).config.lesson_icon).toBe("coins");
  d.config.lesson_icon = "__proto__";
  expect(lessonIconKey(d)).toBe("robot");
  d.config.lesson_icon = "<script>";
  expect(lessonIconKey(d)).toBe("robot");
});
it("searches accent-insensitively, selects icons and restores automatic mode", () => {
  function Host() {
    const [d, set] = useState(templateLesson("math", "blank"));
    return (
      <LessonIconPicker
        lesson={d}
        onChange={(key) =>
          set({ ...d, config: { ...d.config, lesson_icon: key } })
        }
      />
    );
  }
  render(<Host />);
  fireEvent.click(screen.getByText("Chọn icon bài học"));
  fireEvent.change(screen.getByLabelText("Tìm icon"), {
    target: { value: "phan so" },
  });
  expect(
    screen.getByRole("button", { name: "Chọn icon Phân số" }),
  ).toBeTruthy();
  fireEvent.click(screen.getByRole("button", { name: "Chọn icon Phân số" }));
  expect(
    screen
      .getByRole("button", { name: "Chọn icon Phân số" })
      .getAttribute("aria-pressed"),
  ).toBe("true");
  expect(
    screen.getByRole("img", { name: "Icon bài học: Phân số" }),
  ).toBeTruthy();
  fireEvent.click(screen.getByRole("button", { name: "Tự động theo engine" }));
  expect(
    screen
      .getByRole("button", { name: "Tự động theo engine" })
      .getAttribute("aria-pressed"),
  ).toBe("true");
});
