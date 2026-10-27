import 'package:flutter/material.dart';

/// Presentation only: the activity state and educational colors stay intact.
class LessonTheme {
  LessonTheme(String topicId, int lessonIndex, ThemeData base) {
    final seed = HSLColor.fromColor(
      topicSeeds[topicId] ?? topicSeeds['logic']!,
    );
    final offset = lessonIndex * (lessonIndex.isEven ? 4.0 : -4.0);
    final color = seed.withHue((seed.hue + offset) % 360).toColor();
    theme = _themed(base, color, base.brightness);
    // Existing canvases use fixed ink/paper for diagrams. Keep a readable
    // light drawing surface while the surrounding lesson follows brightness.
    canvasTheme = _themed(base, color, Brightness.light);
  }

  static const topicSeeds = <String, Color>{
    'logic': Color(0xFF6651B8),
    'math': Color(0xFF315DA8),
    'science': Color(0xFFAD562B),
    'data': Color(0xFF357541),
    'geometry': Color(0xFF2D708D),
    'coding': Color(0xFF087E80),
    'circuits': Color(0xFF8B691F),
    'probability': Color(0xFFAA4464),
    'algebra': Color(0xFF69469E),
    'optimization': Color(0xFF4C6F28),
    'geography': Color(0xFF26745C),
    'marxism': Color(0xFFA12D40),
    'painting': Color(0xFFA03A91),
  };

  late final ThemeData theme, canvasTheme;

  static ThemeData _themed(ThemeData base, Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surfaceContainerLow,
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: base.iconTheme.copyWith(color: scheme.primary),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: base.iconButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurfaceVariant
                : scheme.onPrimaryContainer,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.surfaceContainerHighest
                : scheme.primaryContainer,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? scheme.outlineVariant
                  : scheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: .15),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: base.textTheme.labelMedium?.copyWith(
          color: scheme.onPrimary,
        ),
      ),
      switchTheme: base.switchTheme.copyWith(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: scheme.primaryContainer,
        secondarySelectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          color: scheme.onSurface,
        ),
        side: BorderSide(color: scheme.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .12)
                : scheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .38)
                : scheme.onPrimary,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }
}
