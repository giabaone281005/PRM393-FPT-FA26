# Font assets

Cofo Brilliant / Cofo Robert: font files observed in Brilliant's public @font-face
declarations on 2026-10-23. WOFF2 sources and identity metadata are preserved in
`docs/evidence/styles/`; converted TTF outlines are used by Flutter.

Source Code Pro: font from the same observed page, reserved for code content.

Noto Sans and Noto Serif: Vietnamese fallbacks from the official `notofonts/noto-fonts` repository:
`hinted/ttf/NotoSans/NotoSans-{Regular,Medium,Bold}.ttf`.
`hinted/ttf/NotoSerif/NotoSerif-Medium.ttf` is used only for Cofo Robert display.
Its SIL Open Font License is preserved in `OFL-NotoSans.txt`.

Source font metadata is recorded in `docs/evidence/styles/font-manifest.json`.
Observation/download of a font does not establish a redistribution license;
the evidence records the source and does not assert ownership of Cofo fonts.
