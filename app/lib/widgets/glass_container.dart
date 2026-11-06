import 'package:flutter/material.dart';

import '../theme/glass_theme.dart';

/// Glass card: translucent gradient fill + subtle border over the soft
/// [AppBackground], the recurring visual motif for every surface in the app.
///
/// Deliberately no BackdropFilter: a live blur per card is re-rendered on
/// every scroll frame (measured ~25 ms/frame on a 120 Hz phone = visible
/// stutter), and the background is already soft, so it adds almost nothing.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            AppColors.glassFill,
          ],
        ),
        borderRadius: radius,
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: child,
    );
  }
}
