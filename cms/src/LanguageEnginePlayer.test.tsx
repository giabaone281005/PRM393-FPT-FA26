// @vitest-environment jsdom
import { afterEach, expect, it, vi } from "vitest";
import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { useState } from "react";
import { newSlide, type Slide } from "./domain";
import { LanguageEnginePlayer } from "./LanguageEnginePlayer";
afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
});
it("keeps a choice made while TTS is playing and cancels audio on exit", () => {
  let utterance: SpeechSynthesisUtterance | undefined;
  const cancel = vi.fn();
  vi.stubGlobal(
    "SpeechSynthesisUtterance",
    class {
      lang = "";
      rate = 1;
      onend: (() => void) | null = null;
      onerror: (() => void) | null = null;
    },
  );
  vi.stubGlobal("speechSynthesis", {
    cancel,
    speak: (u: SpeechSynthesisUtterance) => {
      utterance = u;
    },
  });
  const update = vi.fn();
  const slide = newSlide("listeningChoice");
  function Host() {
    const [s, set] = useState<Record<string, unknown>>({
      answer: -1,
      experienced: false,
    });
    return (
      <LanguageEnginePlayer
        slide={slide}
        state={s}
        update={(v) => {
          set(v);
          update(v);
        }}
      />
    );
  }
  const view = render(<Host />);
  fireEvent.click(screen.getByText("Nghe mẫu"));
  fireEvent.click(screen.getByText("At eight."));
  utterance!.onend!(new Event("end") as SpeechSynthesisEvent);
  expect(update).toHaveBeenLastCalledWith({ answer: 1, experienced: true });
  view.unmount();
  expect(utterance!.onend).toBeNull();
  expect(cancel).toHaveBeenCalled();
});
it("allows a transcript fallback and typed writing when audio is unavailable", () => {
  const update = vi.fn();
  const slide = newSlide("listeningChoice");
  const view = render(
    <LanguageEnginePlayer
      slide={slide}
      state={{ answer: 1 }}
      update={update}
    />,
  );
  fireEvent.click(screen.getByText("Xem bản chữ thay âm thanh"));
  expect(update).toHaveBeenCalledWith({ answer: 1, experienced: true });
  expect(screen.getByText(slide.config.text!)).toBeTruthy();
  view.rerender(
    <LanguageEnginePlayer
      slide={newSlide("textEntry") as Slide}
      state={{ response: "" }}
      update={update}
    />,
  );
  fireEvent.change(screen.getByRole("textbox"), {
    target: { value: "My name is Mia." },
  });
  expect(update).toHaveBeenLastCalledWith({ response: "My name is Mia." });
});
