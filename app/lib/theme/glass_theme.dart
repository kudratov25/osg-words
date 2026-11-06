import 'package:flutter/material.dart';

/// Dark, minimal palette. The app is dark-mode-first per the design
/// principles (distraction-free, easy on the eyes for glanceable
/// notifications/widgets), with the glass effect achieved by
/// [GlassContainer] rather than by theme colors alone.
class AppColors {
  static const background = Color(0xFF0B0E14);
  static const backgroundGradientEnd = Color(0xFF151A24);
  static const accent = Color(0xFF7FB3FF);
  static const accentSoft = Color(0xFF5B8DEF);
  static const textPrimary = Color(0xFFF2F4F8);
  static const textSecondary = Color(0xFFA3ADC2);
  static const glassBorder = Color(0x33FFFFFF);
  static const glassFill = Color(0x14FFFFFF);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      surface: AppColors.background,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.background.withValues(alpha: 0.9),
      indicatorColor: AppColors.accent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

/// Full-screen background: a dark base plus a few large, soft colour glows
/// that the translucent glass cards sit on.
class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Painted once and cached: nothing here changes while scrolling.
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              children: [
                Container(color: AppColors.background),
                Positioned(top: -220, left: -180, child: _blob(const Color(0xFF3D6BE0), 520)),
                Positioned(top: 80, right: -240, child: _blob(const Color(0xFF9A5CFF), 500)),
                Positioned(bottom: -260, left: -160, child: _blob(const Color(0xFF2FB8A6), 540)),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }

  /// A soft colour glow: a radial gradient fading to transparent looks like
  /// the old blurred circle without a full-screen blur on every frame.
  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
