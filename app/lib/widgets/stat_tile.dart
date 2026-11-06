import 'package:flutter/material.dart';

import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// One stat box (number + label). Every tile has the same height whatever
/// its label: the label always gets room for two lines (labels like
/// "O'rganilgan so'zlar" wrap, "Ketma-ketlik" doesn't), and the number is
/// one line that shrinks instead of wrapping. So a row of tiles lines up.
class StatTile extends StatelessWidget {
  const StatTile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  static const _valueStyle = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const _labelStyle = TextStyle(fontSize: 12, height: 1.25, color: AppColors.textSecondary);

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final valueBox = scaler.scale(_valueStyle.fontSize!) * _valueStyle.height!;
    final labelBox = scaler.scale(_labelStyle.fontSize!) * _labelStyle.height! * 2;
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        borderRadius: 18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: valueBox,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, maxLines: 1, style: _valueStyle),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: labelBox,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
