import 'package:flutter/material.dart';

abstract final class AppLayout {
  static const contentWidth = 720.0;
  static const gutter = 24.0;
  static const cardRadius = 24.0;
  static const tileRadius = 16.0;
  static const pagePadding = EdgeInsets.fromLTRB(gutter, 24, gutter, 32);

  static Color panel(BuildContext context) => Color.alphaBlend(
    Theme.of(context).colorScheme.primary.withValues(alpha: .035),
    Theme.of(context).colorScheme.surface,
  );
}

class AppContentFrame extends StatelessWidget {
  const AppContentFrame({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
      child: child,
    ),
  );
}

class AppPageBody extends StatelessWidget {
  const AppPageBody({super.key, this.scrollKey, required this.children});
  final Key? scrollKey;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => AppContentFrame(
    child: ListView(
      key: scrollKey,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: AppLayout.pagePadding,
      children: children,
    ),
  );
}

class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showBack = true,
  });
  final Widget title;
  final Widget? trailing;
  final bool showBack;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 64,
    titleSpacing: 0,
    title: AppContentFrame(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.gutter),
        child: Row(
          children: [
            if (showBack && Navigator.canPop(context)) ...[
              IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: DefaultTextStyle(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.titleLarge!,
                child: title,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .6),
      ),
    ),
  );
}
