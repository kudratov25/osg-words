import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../guide/add_widget_sheet.dart';
import '../guide/coach_tour.dart';
import '../guide/guide_controller.dart';
import '../l10n/l10n.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/vocabulary_screen.dart';
import '../services/language_settings.dart';
import '../theme/glass_theme.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  GuideController? _guide;

  @override
  void initState() {
    super.initState();
    _guide = context.read<GuideController?>();
    _guide?.onShowHome = () {
      if (mounted) setState(() => _index = 0);
    };
    // Let Home load its words first, so the tour can point at them.
    if (_guide?.enabled ?? false) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _guide?.startIfPending();
      });
    }
  }

  @override
  void dispose() {
    _guide?.onShowHome = null;
    super.dispose();
  }

  Future<void> _tourFinished() async {
    await _guide?.finish();
    if (mounted) await showAddWidgetSheet(context);
  }

  List<TourStep> _steps(BuildContext context) {
    final l = context.l10n;
    return [
      TourStep(
        target: () => rectOf(GuideKeys.homeHeader),
        reveal: () => revealKey(GuideKeys.homeHeader),
        title: l.tourRefreshTitle,
        body: l.tourRefreshBody,
        gesture: TourGesture.pullDown,
      ),
      TourStep(
        target: () => rectOf(GuideKeys.wordCard),
        reveal: () => revealKey(GuideKeys.wordCard),
        title: l.tourWordTitle,
        body: l.tourWordBody,
      ),
      TourStep(target: () => navItemRect(2), title: l.tourVocabTitle, body: l.tourVocabBody, gesture: TourGesture.tap),
      TourStep(target: () => navItemRect(1), title: l.tourScheduleTitle, body: l.tourScheduleBody, gesture: TourGesture.tap),
      TourStep(target: () => navItemRect(4), title: l.tourSettingsTitle, body: l.tourSettingsBody, gesture: TourGesture.tap),
    ];
  }

  static const _screens = [
    HomeScreen(),
    ScheduleScreen(),
    VocabularyScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final touring = context.select<GuideController?, bool>((g) => g?.active ?? false);
    final scaffold = AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        // Keyed by the pair: when it changes (Settings, or the offline
        // fallback switching once online) the open screen reloads its words.
        body: SafeArea(
          child: KeyedSubtree(
            key: ValueKey(context.select<LanguageSettings, String>((s) => s.pair.key)),
            child: _screens[_index],
          ),
        ),
        // No BackdropFilter: a live blur here is re-rendered on every scroll
        // frame. A near-opaque bar looks the same over the dark background.
        bottomNavigationBar: NavigationBar(
          key: GuideKeys.navBar,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: AppColors.background.withValues(alpha: 0.88),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_rounded), label: l.navHome),
            NavigationDestination(icon: const Icon(Icons.event_note_rounded), label: l.navSchedule),
            NavigationDestination(icon: const Icon(Icons.menu_book_rounded), label: l.navVocabulary),
            NavigationDestination(icon: const Icon(Icons.history_rounded), label: l.navHistory),
            NavigationDestination(icon: const Icon(Icons.settings_rounded), label: l.navSettings),
          ],
        ),
      ),
    );
    if (!touring) return scaffold;
    return Stack(children: [scaffold, Positioned.fill(child: CoachTour(steps: _steps(context), onFinished: _tourFinished))]);
  }
}
