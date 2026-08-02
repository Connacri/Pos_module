import 'package:flutter/material.dart';

/// Simple, tasteful motion toolkit shared across the app.
///
/// Only uses Flutter's built-in implicit/explicit animations so it works
/// identically on mobile, desktop and web (no extra dependency).
/// Fades a child in while sliding it up by [animationPx]. Used to stagger the
/// appearance of dashboard sections so the screen feels alive instead of
/// appearing all at once.
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final double animationPx;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.animationPx = 24,
    this.duration = const Duration(milliseconds: 520),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _controller, curve: widget.curve);
    Future<void>.delayed(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _anim.value) * widget.animationPx),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Animates a numeric value towards its latest target with an ease-out curve
/// (a "count up"). The [formatter] lets callers render currency, counts or
/// percentages.
class AnimatedNumber extends StatefulWidget {
  final double value;
  final String Function(double value) formatter;
  final TextStyle? style;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _controller
      ..duration = widget.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final eased = _curve.value;
        final display = widget.value * eased;
        return Text(
          widget.formatter(display),
          style: widget.style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

/// An [AnimatedSwitcher] tuned for whole-page cross fades, used when switching
/// between tabs so navigation feels smooth instead of hard-cutting.
class PageFadeTransition extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final bool from;

  const PageFadeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.from = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: const Interval(0, 0.4, curve: Curves.easeIn),
      transitionBuilder: (child, animation) {
        final offset = from
            ? Offset(0, (1 - animation.value) * 0.04)
            : Offset((1 - animation.value) * 0.06, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: offset, end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Key>(child.key ?? ObjectKey(child)),
        child: child,
      ),
    );
  }
}

/// A quiet decorative accent used behind headers/cards to give depth. Use as a
/// pure visual element; it respects the current color scheme.
class GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const GlowOrb({super.key, required this.color, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}