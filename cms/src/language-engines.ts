export const languageEngines = {
  listeningChoice: [
    "Nghe và chọn",
    "Ngôn ngữ",
    "Nghe tiếng Anh, đọc bản chữ khi cần và chọn đáp án.",
  ],
  speechPractice: [
    "Luyện nói tiếng Anh",
    "Ngôn ngữ",
    "Nghe mẫu, nói hoặc nhập câu để đối chiếu từ.",
  ],
  textEntry: [
    "Viết câu tiếng Anh",
    "Ngôn ngữ",
    "Viết câu ngắn theo mẫu và ngữ cảnh.",
  ],
} as const;
export type LanguageEngine = keyof typeof languageEngines;
export type LanguageConfig = {
  text?: string;
  choices?: string[];
  answer?: number;
  accepted_answers?: string[];
};
export const normaliseEnglish = (s: string) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
export function languageConfig(e: LanguageEngine): LanguageConfig {
  return e === "listeningChoice"
    ? {
        text: "I go to school at eight.",
        choices: ["At seven.", "At eight.", "At nine."],
        answer: 1,
      }
    : e === "speechPractice"
      ? { text: "I can ride a bike." }
      : { accepted_answers: ["My name is Mia.", "I am Mia."] };
}
export function validLanguage(e: LanguageEngine, c: LanguageConfig): boolean {
  if (e === "textEntry")
    return (
      Array.isArray(c.accepted_answers) &&
      c.accepted_answers.length >= 1 &&
      c.accepted_answers.length <= 6 &&
      c.accepted_answers.every(
        (v) =>
          typeof v === "string" &&
          v.length <= 500 &&
          normaliseEnglish(v).length > 0,
      )
    );
  if (
    typeof c.text !== "string" ||
    c.text.length > 500 ||
    !normaliseEnglish(c.text)
  )
    return false;
  return (
    e === "speechPractice" ||
    (Array.isArray(c.choices) &&
      c.choices.length >= 2 &&
      c.choices.length <= 8 &&
      c.choices.every(
        (v) => typeof v === "string" && v.trim().length > 0 && v.length <= 1000,
      ) &&
      Number.isInteger(c.answer) &&
      c.answer! >= 0 &&
      c.answer! < c.choices.length)
  );
}
export function initialLanguage(e: LanguageEngine): Record<string, unknown> {
  return e === "listeningChoice"
    ? { answer: -1, experienced: false }
    : { response: "" };
}
export function correctLanguage(
  e: LanguageEngine,
  c: LanguageConfig,
  s: Record<string, unknown>,
): boolean {
  if (e === "listeningChoice")
    return s.experienced === true && s.answer === c.answer;
  return (
    typeof s.response === "string" &&
    s.response.length <= 500 &&
    (e === "speechPractice" ? [c.text!] : c.accepted_answers!).some(
      (v) => normaliseEnglish(s.response as string) === normaliseEnglish(v),
    )
  );
}
