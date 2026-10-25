import 'package:flutter/material.dart';

/// Finite motion only: no animation changes the persisted lesson model.
abstract final class AppMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);
  static Duration duration(BuildContext context, [int milliseconds = 320]) =>
      reduced(context) ? Duration.zero : Duration(milliseconds: milliseconds);
}

/// Forward and reverse share one spatial path, adapted from Flutter Samples.
class DiscoveryRoute<T> extends MaterialPageRoute<T> {
  DiscoveryRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 360);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final eased = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(.07, 0),
          end: Offset.zero,
        ).animate(eased),
        child: child,
      ),
    );
  }
}

/// Replays on a meaningful screen/step change without replacing child state.
class MotionEntrance extends StatefulWidget {
  const MotionEntrance({super.key, required this.child, this.replayKey});
  final Widget child;
  final Object? replayKey;
  @override
  State<MotionEntrance> createState() => _MotionEntranceState();
}

class _MotionEntranceState extends State<MotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = AppMotion.duration(context, 420);
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MotionEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replayKey != widget.replayKey) {
      if (AppMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _eased,
    child: SlideTransition(
      position: Tween(
        begin: const Offset(0, .025),
        end: Offset.zero,
      ).animate(_eased),
      child: widget.child,
    ),
  );
}
