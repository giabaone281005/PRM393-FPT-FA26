import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_motion.dart';

// Base palette/fonts: Brilliant's public CSS, captured by REA on 2026-10-23.
// Typography sizes and shared page geometry are adapted for Matlingo.
// See docs/STYLE_RECONSTRUCTION.md for source tokens and measured limits.
const ink = Color(0xFF000000);
const paper = Color(0xFFFFFFFF);
const green = Color(0xFF29CC57);

abstract final class BrilliantPalette {
  static const surface = Color(0xFFF8F8F8); // gray.50 / bg.secondary
  static const track = Color(0xFFE5E5E5); // gray.200
  static const border = Color(0xFFCCCCCC); // gray.300
  static const secondaryText = Color(0xFF666666); // blackAlpha.700 on white
  static const action = Color(0xFF383838); // bg.inverse.secondary
  static const successSurface = Color(0xFFEAFAEE); // green.100
  static const successInk = Color(0xFF007C23); // green.800
  static const errorSurface = surface;
}

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: const ColorScheme.light(
    primary: ink,
    onPrimary: paper,
    primaryContainer: BrilliantPalette.successSurface,
    onPrimaryContainer: ink,
    secondary: green,
    onSecondary: ink,
    secondaryContainer: BrilliantPalette.successSurface,
    onSecondaryContainer: ink,
    tertiary: green,
    onTertiary: ink,
    tertiaryContainer: BrilliantPalette.successSurface,
    onTertiaryContainer: ink,
    surface: paper,
    onSurface: ink,
    surfaceContainerHighest: BrilliantPalette.surface,
    surfaceContainerLowest: paper,
    surfaceContainerLow: BrilliantPalette.surface,
    surfaceContainer: BrilliantPalette.surface,
    surfaceContainerHigh: BrilliantPalette.track,
    onSurfaceVariant: BrilliantPalette.secondaryText,
    outline: BrilliantPalette.border,
    outlineVariant: BrilliantPalette.track,
    error: ink,
    onError: paper,
    errorContainer: BrilliantPalette.surface,
    onErrorContainer: ink,
    inverseSurface: BrilliantPalette.action,
    onInverseSurface: paper,
    inversePrimary: green,
    surfaceTint: Colors.transparent,
  ),
  fontFamily: 'CofoBrilliant',
  fontFamilyFallback: const ['NotoSans'],
  textTheme: const TextTheme(
    // Marketing display and lesson headings are different source styles.
    headlineLarge: TextStyle(
      fontFamily: 'CofoRobert',
      fontFamilyFallback: ['NotoSerif'],
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.18,
      letterSpacing: -.36,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0,
    ),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    toolbarHeight: 64,
    titleTextStyle: TextStyle(
      fontFamily: 'CofoBrilliant',
      fontFamilyFallback: ['NotoSans'],
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    backgroundColor: paper,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: paper,
    surfaceTintColor: Colors.transparent,
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: paper,
    surfaceTintColor: Colors.transparent,
  ),
  snackBarTheme: const SnackBarThemeData(
    backgroundColor: BrilliantPalette.action,
    contentTextStyle: TextStyle(
      fontFamily: 'CofoBrilliant',
      fontFamilyFallback: ['NotoSans'],
      color: paper,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? BrilliantPalette.track
            : BrilliantPalette.action,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? BrilliantPalette.secondaryText
            : paper,
      ),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'CofoBrilliant',
          fontFamilyFallback: ['NotoSans'],
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: ink,
      backgroundColor: paper,
      side: const BorderSide(color: BrilliantPalette.border),
      minimumSize: const Size(48, 48),
      shape: const StadiumBorder(),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: ink),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: ink,
      highlightColor: BrilliantPalette.track,
    ),
  ),
  chipTheme: const ChipThemeData(
    backgroundColor: paper,
    selectedColor: BrilliantPalette.successSurface,
    surfaceTintColor: Colors.transparent,
    side: BorderSide(color: BrilliantPalette.track),
    labelStyle: TextStyle(
      fontFamily: 'CofoBrilliant',
      fontFamilyFallback: ['NotoSans'],
      fontSize: 14,
      color: ink,
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: paper,
    surfaceTintColor: Colors.transparent,
    indicatorColor: BrilliantPalette.successSurface,
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'CofoBrilliant',
        fontFamilyFallback: ['NotoSans'],
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: BrilliantPalette.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: BrilliantPalette.track),
    ),
  ),
);

/// The source CTA has a 4px solid bottom shadow, not a blurred Material shadow.
class PrimaryAction extends StatefulWidget {
  const PrimaryAction({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = false,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final bool expand;
  @override
  State<PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<PrimaryAction> {
  final _states = WidgetStatesController();
  @override
  void initState() {
    super.initState();
    _states.addListener(_changed);
  }

  bool _pressed = false;
  void _changed() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (_pressed == pressed) return;
    void update() {
      if (mounted) {
        setState(() => _pressed = _states.value.contains(WidgetState.pressed));
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => update());
    } else {
      update();
    }
  }

  @override
  void dispose() {
    _states.removeListener(_changed);
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed;
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          child: IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AnimatedContainer(
                duration: AppMotion.duration(context, 110),
                curve: Curves.easeOut,
                transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: widget.onPressed == null
                      ? const []
                      : [
                          BoxShadow(
                            color: ink,
                            offset: Offset(0, pressed ? 1 : 4),
                          ),
                        ],
                ),
                child: FilledButton(
                  statesController: _states,
                  onPressed: widget.onPressed,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessonProgress extends StatelessWidget {
  const LessonProgress({super.key, required this.step, this.total = 3});
  final int step, total;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Tiến độ bài học',
    value: 'Bước ${step + 1} trên $total',
    child: Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i != 0) const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: i <= step ? 1 : 0),
                duration: AppMotion.duration(context),
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor:
                      Theme.of(context)
                          .progressIndicatorTheme
                          .linearTrackColor ??
                      BrilliantPalette.track,
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
