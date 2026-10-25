import 'app_layout.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences(this.storage) {
    try {
      final value = jsonDecode(storage.getString(storageKey) ?? '{}') as Map;
      background = ['white', 'cream', 'mist'].contains(value['background'])
          ? value['background'] as String
          : 'white';
      accent = ['green', 'blue', 'violet'].contains(value['accent'])
          ? value['accent'] as String
          : 'green';
      textSize = value['textSize'] == 1.15
          ? 1.15
          : value['textSize'] == 1.3
          ? 1.3
          : 1;
      sansHeadings = value['sansHeadings'] == true;
      reduceMotion = value['reduceMotion'] == true;
    } catch (_) {
      /* Invalid appearance data falls back to defaults. */
    }
  }
  static const storageKey = 'matlingo:appearance:v1';
  final SharedPreferences storage;
  String background = 'white', accent = 'green';
  double textSize = 1;
  bool sansHeadings = false, reduceMotion = false;
  Future<bool> _queue = Future.value(true);
  bool _disposed = false;
  Future<bool> update({
    String? background,
    String? accent,
    double? textSize,
    bool? sansHeadings,
    bool? reduceMotion,
  }) {
    return _queue = _queue.then((_) async {
      final next = {
        'background': background ?? this.background,
        'accent': accent ?? this.accent,
        'textSize': textSize ?? this.textSize,
        'sansHeadings': sansHeadings ?? this.sansHeadings,
        'reduceMotion': reduceMotion ?? this.reduceMotion,
      };
      try {
        if (!await storage.setString(storageKey, jsonEncode(next))) {
          return false;
        }
        this.background = next['background'] as String;
        this.accent = next['accent'] as String;
        this.textSize = next['textSize'] as double;
        this.sansHeadings = next['sansHeadings'] as bool;
        this.reduceMotion = next['reduceMotion'] as bool;
        if (!_disposed) notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  ThemeData get theme {
    final base = buildAppTheme();
    final bg = switch (background) {
      'cream' => const Color(0xFFFFFBF2),
      'mist' => const Color(0xFFF4F6FB),
      _ => Colors.white,
    };
    final color = switch (accent) {
      'blue' => const Color(0xFF3855D9),
      'violet' => const Color(0xFF7040C5),
      _ => const Color(0xFF147A40),
    };
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: color,
        secondary: color,
        surface: bg,
      ),
      appBarTheme: base.appBarTheme.copyWith(backgroundColor: bg),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: bg),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: bg),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: bg,
        selectedColor: color.withValues(alpha: .1),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: color,
        linearTrackColor: color.withValues(alpha: .1),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style!.copyWith(
          foregroundColor: WidgetStatePropertyAll(color),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style!.copyWith(
          foregroundColor: WidgetStatePropertyAll(color),
          backgroundColor: WidgetStatePropertyAll(bg),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: Color.alphaBlend(color.withValues(alpha: .025), bg),
        contentPadding: const EdgeInsets.all(16),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: bg,
        indicatorColor: color.withValues(alpha: .1),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style!.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? BrilliantPalette.track
                : color,
          ),
        ),
      ),
      textTheme: sansHeadings
          ? base.textTheme.copyWith(
              headlineLarge: base.textTheme.headlineLarge!.copyWith(
                fontFamily: 'CofoBrilliant',
                fontFamilyFallback: ['NotoSans'],
                fontWeight: FontWeight.w700,
              ),
            )
          : base.textTheme,
    );
  }
}

class AppearanceScope extends InheritedNotifier<AppPreferences> {
  const AppearanceScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()!.notifier!;
}

void openAppearance(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => const AppearancePage()),
);

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = AppearanceScope.of(context);
    Future<void> save(Future<bool> result) async {
      if (!await result && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa lưu được giao diện. Hãy thử lại.'),
          ),
        );
      }
    }

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
    Widget options(
      String prefix,
      Map<String, String> values,
      String selected,
      void Function(String) change,
    ) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in values.entries)
          ChoiceChip(
            key: ValueKey('$prefix-${entry.key}'),
            label: Text(entry.value),
            selected: selected == entry.key,
            onSelected: (_) => change(entry.key),
          ),
      ],
    );
    return Scaffold(
      appBar: const AppPageHeader(title: Text('Giao diện ứng dụng')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
          child: ListView(
            padding: AppLayout.pagePadding,
            children: [
              Text(
                'Theo cách của bạn.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Thay đổi được áp dụng ngay và lưu trên thiết bị.'),
              const SizedBox(height: 32),
              section(
                'Nền giao diện',
                options(
                  'background',
                  {'white': 'Trắng', 'cream': 'Kem', 'mist': 'Xám dịu'},
                  settings.background,
                  (v) => save(settings.update(background: v)),
                ),
              ),
              section(
                'Màu nhấn',
                options(
                  'accent',
                  {'green': 'Xanh lá', 'blue': 'Xanh lam', 'violet': 'Tím'},
                  settings.accent,
                  (v) => save(settings.update(accent: v)),
                ),
              ),
              section(
                'Cỡ chữ',
                options(
                  'text-size',
                  {'1.0': 'Tiêu chuẩn', '1.15': 'Lớn', '1.3': 'Rất lớn'},
                  settings.textSize.toStringAsFixed(
                    settings.textSize == 1.15 ? 2 : 1,
                  ),
                  (v) => save(settings.update(textSize: double.parse(v))),
                ),
              ),
              section(
                'Tiêu đề',
                options(
                  'headings',
                  {'serif': 'Có chân', 'sans': 'Gọn gàng'},
                  settings.sansHeadings ? 'sans' : 'serif',
                  (v) => save(settings.update(sansHeadings: v == 'sans')),
                ),
              ),
              SwitchListTile.adaptive(
                key: const ValueKey('reduce-motion'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Giảm chuyển động'),
                subtitle: const Text(
                  'Hạn chế hiệu ứng chuyển trang và chuyển động trang trí.',
                ),
                value: settings.reduceMotion,
                onChanged: (v) => save(settings.update(reduceMotion: v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
