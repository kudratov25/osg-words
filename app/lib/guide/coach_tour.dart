import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/glass_theme.dart';
import 'guide_controller.dart';

/// One coach mark: where to point and what to say.
class TourStep {
  const TourStep({required this.target, required this.title, required this.body, this.gesture, this.reveal});

  /// Scrolls the target into view first (optional).
  final Future<void> Function()? reveal;

  /// Rect of the real widget to highlight (global coordinates), or null if
  /// it isn't on screen - the step is then skipped.
  final Rect? Function() target;
  final String title;
  final String body;

  /// Optional animated hint inside the highlight (e.g. a pull-down hand).
  final TourGesture? gesture;
}

enum TourGesture { pullDown, tap }

/// Rect of [key]'s widget, or null.
Rect? rectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize || !box.attached) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Scrolls [key]'s widget into view (if it's in a scrollable).
Future<void> revealKey(GlobalKey key) async {
  final ctx = key.currentContext;
  if (ctx == null) return;
  await Scrollable.ensureVisible(ctx, alignment: 0.3, duration: const Duration(milliseconds: 300));
}

/// Rect of navigation-bar item [index] of [count] (items share the width).
Rect? navItemRect(int index, {int count = 5}) {
  final bar = rectOf(GuideKeys.navBar);
  if (bar == null) return null;
  final w = bar.width / count;
  return Rect.fromLTWH(bar.left + w * index, bar.top, w, math.min(bar.height, 80));
}

/// Full-screen dim with a "spotlight" hole around the current target, a
/// pulsing ring and a tip card. The spotlight glides between steps. Tap
/// anywhere (or Next) to go on; Skip ends it.
class CoachTour extends StatefulWidget {
  const CoachTour({required this.steps, required this.onFinished, super.key});

  final List<TourStep> steps;
  final VoidCallback onFinished;

  @override
  State<CoachTour> createState() => _CoachTourState();
}

class _CoachTourState extends State<CoachTour> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final AnimationController _move =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  int _index = -1;
  Rect? _from;
  Rect? _to;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
  }

  @override
  void dispose() {
    _pulse.dispose();
    _move.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _advance() async {
    if (!mounted || _busy) return;
    _busy = true;
    var next = _index + 1;
    Rect? rect;
    while (next < widget.steps.length) {
      // The screen may still be loading: give each target a moment to appear.
      for (var attempt = 0; attempt < 10 && rect == null; attempt++) {
        if (attempt > 0) await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        await widget.steps[next].reveal?.call();
        if (!mounted) return;
        rect = widget.steps[next].target();
      }
      if (rect != null) break;
      next++;
    }
    _busy = false;
    if (next >= widget.steps.length || rect == null) {
      widget.onFinished();
      return;
    }
    setState(() {
      _from = _to ?? rect!.inflate(400);
      _to = rect!.inflate(8);
      _index = next;
    });
    _move.forward(from: 0);
  }

  bool get _isLast {
    for (var i = _index + 1; i < widget.steps.length; i++) {
      if (widget.steps[i].target() != null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_index < 0 || _to == null) return const SizedBox.shrink();
    final step = widget.steps[_index];
    final l = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final below = _to!.center.dy < size.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('tour-overlay'),
              behavior: HitTestBehavior.opaque,
              onTap: _advance,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulse, _move]),
                builder: (context, _) {
                  final t = Curves.easeInOutCubic.transform(_move.value);
                  final hole = Rect.lerp(_from, _to, t)!;
                  return CustomPaint(
                    painter: _SpotlightPainter(hole: hole, pulse: _pulse.value),
                    child: step.gesture == null || t < 1
                        ? const SizedBox.expand()
                        : Stack(children: [_GestureHint(gesture: step.gesture!, hole: hole, progress: _pulse.value)]),
                  );
                },
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            left: 20,
            right: 20,
            top: below ? math.min(_to!.bottom + 16, size.height - 260) : null,
            bottom: below ? null : math.max(size.height - _to!.top + 16, padding.bottom + 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _TipCard(
                key: ValueKey(_index),
                title: step.title,
                body: step.body,
                stepIndex: _index,
                stepCount: widget.steps.length,
                nextLabel: _isLast ? l.tourGotIt : l.tourNext,
                skipLabel: l.skip,
                onNext: _advance,
                onSkip: widget.onFinished,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.pulse});
  final Rect hole;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(20));
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(r),
    );
    canvas.drawPath(dim, Paint()..color = const Color(0xD9000000));
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.accent,
    );
    // Expanding, fading ring: "look here".
    final grow = 4 + 14 * pulse;
    canvas.drawRRect(
      r.inflate(grow),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.accent.withValues(alpha: (1 - pulse) * 0.6),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole || old.pulse != pulse;
}

/// A finger that demonstrates the gesture inside the highlight.
class _GestureHint extends StatelessWidget {
  const _GestureHint({required this.gesture, required this.hole, required this.progress});
  final TourGesture gesture;
  final Rect hole;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = Curves.easeInOut.transform(progress < 0.7 ? progress / 0.7 : 1);
    final dy = gesture == TourGesture.pullDown ? (hole.height * 0.5) * p : 0.0;
    final scale = gesture == TourGesture.tap ? 1 - 0.15 * math.sin(progress * math.pi) : 1.0;
    final opacity = progress < 0.8 ? 1.0 : (1 - (progress - 0.8) / 0.2);
    return Positioned(
      left: hole.center.dx - 18,
      top: hole.top + 6 + dy,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.scale(
          scale: scale,
          child: const Icon(Icons.touch_app_rounded, size: 36, color: Colors.white),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.stepCount,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final String title;
  final String body;
  final int stepIndex;
  final int stepCount;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundGradientEnd,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(body, style: const TextStyle(fontSize: 15, height: 1.35, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < stepCount; i++)
                Container(
                  margin: const EdgeInsets.only(right: 5),
                  width: i == stepIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= stepIndex ? AppColors.accent : AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              TextButton(
                key: const Key('tour-skip'),
                onPressed: onSkip,
                child: Text(skipLabel, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              FilledButton(
                key: const Key('tour-next'),
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                ),
                child: Text(nextLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
