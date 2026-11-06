import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/l10n.dart';
import '../notifications/widget_sync.dart' show androidWidgetProvider;
import '../theme/glass_theme.dart';
import '../widgets/report_sheet.dart' show showGlassSheet;

/// "Add the OSG widget": Android opens the system "add widget" dialog
/// (launcher permitting); iOS can't do that from an app, so it shows an
/// animated step-by-step guide instead.
Future<void> showAddWidgetSheet(BuildContext context) async {
  final android = !kIsWeb && Platform.isAndroid;
  var canPin = false;
  if (android) {
    try {
      canPin = await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      canPin = false;
    }
  }
  if (!context.mounted) return;
  await showGlassSheet<void>(context, (sheetContext) => _AddWidgetSheet(android: android, canPin: canPin));
}

class _AddWidgetSheet extends StatelessWidget {
  const _AddWidgetSheet({required this.android, required this.canPin});
  final bool android;
  final bool canPin;

  Future<void> _pin(BuildContext context) async {
    try {
      await HomeWidget.requestPinWidget(qualifiedAndroidName: androidWidgetProvider);
    } catch (e) {
      debugPrint('requestPinWidget failed: $e');
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.widgetTitle,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(l.widgetBody, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          if (android && canPin) ...[
            const _WidgetPreview(),
            const SizedBox(height: 18),
            FilledButton.icon(
              key: const Key('widget-add'),
              onPressed: () => _pin(context),
              icon: const Icon(Icons.add_to_home_screen_rounded),
              label: Text(l.widgetAddButton),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.background,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pan_tool_alt_rounded, color: AppColors.accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.widgetAndroidMove,
                        style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.textPrimary)),
                  ),
                ],
              ),
            ),
          ] else if (android) ...[
            const _WidgetPreview(),
            const SizedBox(height: 14),
            Text(l.widgetAndroidManual, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
          ] else ...[
            _IosGuide(steps: [l.widgetIosStep1, l.widgetIosStep2, l.widgetIosStep3]),
            const SizedBox(height: 12),
            Text(l.widgetIosLock, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 8),
          TextButton(
            key: const Key('widget-later'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.widgetLater, style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// A small mock of the widget (word + translation).
class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OSG', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
            SizedBox(height: 6),
            Text('🇩🇪 der Schlüssel',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            SizedBox(height: 2),
            Text('key', style: TextStyle(fontSize: 14, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}

/// Plays the three iOS steps on a mini phone, one after another, in a loop.
class _IosGuide extends StatefulWidget {
  const _IosGuide({required this.steps});
  final List<String> steps;

  @override
  State<_IosGuide> createState() => _IosGuideState();
}

class _IosGuideState extends State<_IosGuide> with SingleTickerProviderStateMixin {
  int _step = 0;
  Timer? _timer;
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _step = (_step + 1) % widget.steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 150,
            height: 230,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.glassBorder, width: 3),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: KeyedSubtree(key: ValueKey(_step), child: _phoneScreen(_step)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < widget.steps.length; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: i == _step ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _step ? AppColors.accent : AppColors.glassFill,
                    ),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: i == _step ? AppColors.background : AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.steps[i],
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.3)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _phoneScreen(int step) {
    Widget icons({bool jiggle = false}) => Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < 8; i++)
              AnimatedBuilder(
                animation: _press,
                builder: (_, child) => Transform.rotate(
                  angle: jiggle ? (i.isEven ? 1 : -1) * 0.06 * (_press.value - 0.5) : 0,
                  child: child,
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(7)),
                ),
              ),
          ],
        );
    final finger = AnimatedBuilder(
      animation: _press,
      builder: (_, child) => Transform.scale(scale: 1 - 0.15 * _press.value, child: child),
      child: const Icon(Icons.touch_app_rounded, color: Colors.white, size: 30),
    );
    return Padding(
      padding: const EdgeInsets.all(14),
      child: switch (step) {
        0 => Stack(children: [icons(), Positioned(left: 45, top: 120, child: finger)]),
        1 => Stack(children: [
            icons(jiggle: true),
            const Positioned(left: 0, top: 0, child: Icon(Icons.add_circle, color: AppColors.accent, size: 26)),
            Positioned(left: 10, top: 14, child: finger),
          ]),
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.glassFill, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🇩🇪 Schlüssel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Text('key', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: const Text('+ OSG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.background)),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.center, child: finger),
            ],
          ),
      },
    );
  }
}
