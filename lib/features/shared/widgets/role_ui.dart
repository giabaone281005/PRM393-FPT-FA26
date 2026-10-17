import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shared Student visual language for family and staff workspaces.
ThemeData roleTheme(BuildContext context, {ThemeData? base}) {
  final theme = base ?? Theme.of(context);
  final dark = theme.brightness == Brightness.dark;
  final border = dark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return theme.copyWith(
    scaffoldBackgroundColor: dark
        ? AppColors.darkBackground
        : AppColors.background,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        side: BorderSide(color: border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.darkSurfaceSubtle : AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: dark ? AppColors.darkSurface : AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(15),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: border),
      ),
    ),
  );
}

class RoleScaffold extends StatelessWidget {
  const RoleScaffold({super.key, required this.appBar, required this.body});
  final PreferredSizeWidget appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) => Theme(
    data: roleTheme(context),
    child: Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: body,
          ),
        ),
      ),
    ),
  );
}

class RoleIntroCard extends StatelessWidget {
  const RoleIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primaryHover, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}

class RoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RoleAppBar({super.key, required this.title, this.actions});
  final Widget title;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 76,
    backgroundColor: Theme.of(context).colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MATHLINGO',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!
              .copyWith(fontWeight: FontWeight.w800),
          child: title,
        ),
      ],
    ),
    actions: actions,
    shape: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
  );
}

class RoleNavigationBar extends StatelessWidget {
  const RoleNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
    required this.icons,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: dark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = i == selectedIndex;
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                child: Material(
                  color: active
                      ? (dark
                            ? AppColors.primary.withAlpha(40)
                            : AppColors.primaryLight)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => onSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[i],
                            size: 22,
                            color: active
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: active
                                  ? AppColors.primary
                                  : (dark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
