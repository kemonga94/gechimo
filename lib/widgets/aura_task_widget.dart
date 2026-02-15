import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Aura-like task card with soft boundaries and center-out gradient.
///
/// Java comparison:
/// - This immutable Widget class is similar to a Java class with final fields
///   and constructor injection.
/// - [StatefulWidget] + [_AuraTaskWidgetState] maps to a Java UI component
///   class plus an internal state holder.
class AuraTaskWidget extends StatefulWidget {
  const AuraTaskWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.width = 220,
    this.height = 140,
    this.primaryColor = const Color(0xFF56F0B7),
    this.secondaryColor = const Color(0xFF2AB8FF),
    this.glowIntensity = 0.75,
    this.animationDuration = const Duration(seconds: 8),
    this.borderRadius = 36,
    this.padding = const EdgeInsets.all(18),
    this.child,
  });

  final String title;
  final String? subtitle;
  final double width;
  final double height;
  final Color primaryColor;
  final Color secondaryColor;

  /// 0.0 ~ 1.0, controls blur/glow alpha.
  final double glowIntensity;
  final Duration animationDuration;
  final double borderRadius;
  final EdgeInsets padding;
  final Widget? child;

  @override
  State<AuraTaskWidget> createState() => _AuraTaskWidgetState();
}

class _AuraTaskWidgetState extends State<AuraTaskWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AuraTaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _controller
        ..duration = widget.animationDuration
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clampedIntensity = widget.glowIntensity.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 2) * 0.15;
        final dy = math.cos((t + 0.25) * math.pi * 2) * 0.15;

        return RepaintBoundary(
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor
                              .withOpacity(0.45 * clampedIntensity),
                          blurRadius: 34,
                          spreadRadius: 6,
                        ),
                        BoxShadow(
                          color: widget.secondaryColor
                              .withOpacity(0.35 * clampedIntensity),
                          blurRadius: 56,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: CustomPaint(
                      painter: _AuraPainter(
                        primary: widget.primaryColor,
                        secondary: widget.secondaryColor,
                        shiftX: dx,
                        shiftY: dy,
                        intensity: clampedIntensity,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                            width: 1.1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                        ),
                        padding: widget.padding,
                        child: widget.child ?? _DefaultAuraContent(widget: widget),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DefaultAuraContent extends StatelessWidget {
  const _DefaultAuraContent({required this.widget});

  final AuraTaskWidget widget;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white.withOpacity(0.78),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(widget.title, style: titleStyle, maxLines: 2),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(widget.subtitle!, style: subtitleStyle, maxLines: 2),
        ],
      ],
    );
  }
}

class _AuraPainter extends CustomPainter {
  const _AuraPainter({
    required this.primary,
    required this.secondary,
    required this.shiftX,
    required this.shiftY,
    required this.intensity,
  });

  final Color primary;
  final Color secondary;
  final double shiftX;
  final double shiftY;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(shiftX, shiftY),
        radius: 0.95,
        colors: [
          primary.withOpacity(0.66 * intensity),
          secondary.withOpacity(0.44 * intensity),
          Colors.transparent,
        ],
        stops: const [0.05, 0.62, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.plus;

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.26 * intensity),
          Colors.transparent,
          Colors.white.withOpacity(0.14 * intensity),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect)
      ..blendMode = BlendMode.screen;

    canvas.drawRect(rect, radialPaint);
    canvas.drawRect(rect, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant _AuraPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.shiftX != shiftX ||
        oldDelegate.shiftY != shiftY ||
        oldDelegate.intensity != intensity;
  }
}
