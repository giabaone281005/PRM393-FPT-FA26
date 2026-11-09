import {
  clone,
  engines,
  newSlide,
  type Engine,
  type Lesson,
  type Slide,
} from "./domain";
import {
  validExtended,
  extendedEngines,
  type ExtendedEngine,
} from "./engine-contract";
/** Explicitly reviewed conversion; immutable original versions remain on the server. */
export function editableStudioVersion(source: Lesson): Lesson {
  const d = clone(source),
    story = newSlide("story");
  const aliases: Record<string, Engine> = {
    solidExplorer: "solid3D",
    globeExplorer: "globe3D",
    strataExplorer: "strata3D",
    balanceBlocks: "balanceScale",
  };
  const engine =
    aliases[source.mechanism] ??
    (source.mechanism in engines ? (source.mechanism as Engine) : "quiz");
  const interaction = newSlide(engine);
  story.title = source.title;
  story.config.text = [
    String(source.config.knowledge ?? source.prompt),
    typeof source.config.code === "string" ? source.config.code : "",
    typeof source.config.source === "string"
      ? `Nguồn: ${source.config.source}`
      : "",
  ]
    .filter(Boolean)
    .join("\n\n")
    .slice(0, 10000);
  interaction.title = "Thực hành và kiểm chứng";
  interaction.prompt = source.prompt;
  interaction.hint = source.hint;
  interaction.explanation = source.explanation;
  if (source.mechanism === "reasonedChoice")
    interaction.config = {
      choices: clone(source.config.choices as string[]),
      answer: Number.isInteger(source.config.answer)
        ? (source.config.answer as number)
        : -1,
    };
  else if (
    engine in extendedEngines &&
    validExtended(engine as ExtendedEngine, source.config as Slide["config"])
  )
    interaction.config = clone(source.config as Slide["config"]);
  d.mechanism = "slideLesson";
  d.config = { schema_version: 1, slides: [story, interaction] };
  d.convert_from_version = source.content_version;
  return d;
}
