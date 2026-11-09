import { readFileSync } from "node:fs";
import { expect, it } from "vitest";
import { correct, validateLesson, type Lesson } from "./domain";
export const curriculum = JSON.parse(
  readFileSync(
    new URL("../content/three-topic-curriculum.json", import.meta.url),
    "utf8",
  ),
) as {
  topics: { id: string }[];
  lessons: Lesson[];
  solutions: Record<string, Record<string, Record<string, unknown>>>;
};
it("ships exactly 4 math, 3 English and 3 coding lessons with six valid, solvable parts each", () => {
  expect(curriculum.topics).toHaveLength(3);
  expect(curriculum.lessons).toHaveLength(10);
  expect(
    curriculum.topics.map(
      (t) => curriculum.lessons.filter((l) => l.topic_id === t.id).length,
    ),
  ).toEqual([4, 3, 3]);
  for (const lesson of curriculum.lessons) {
    expect(validateLesson(lesson), lesson.id).toEqual([]);
    expect(lesson.config.slides).toHaveLength(6);
    for (const s of lesson.config.slides!) {
      expect(correct(s, curriculum.solutions[lesson.id][s.id]), s.id).toBe(
        true,
      );
      expect(correct(s, {}), s.id).toBe(false);
    }
    if (lesson.topic_id === "studio-english")
      expect(lesson.config.slides!.map((s) => s.engine)).toEqual(
        expect.arrayContaining([
          "story",
          "listeningChoice",
          "speechPractice",
          "textEntry",
        ]),
      );
  }
});
