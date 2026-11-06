import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/languages.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../notifications/scheduler.dart' show wordTitle;
import '../services/content_sync.dart' show SyncStage;
import '../services/language_settings.dart';
import '../services/learning_prefs.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/language_card.dart';
import '../widgets/learning_pickers.dart';
import '../data/levels.dart';

/// First launch: I speak -> I want to learn -> my
/// level -> my work (optional) -> how it works (live preview + notification
/// permission) -> Start. The pair's words download in the background from
/// the level step on. Nothing to
/// type, no account. Finishing calls [LanguageSettings.completeOnboarding],
/// which swaps the app to the normal tabs.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.systemLanguage, this.requestPermission, super.key});

  /// The phone's language code; pre-selects "I speak".
  final String systemLanguage;

  /// Asks the OS for notification permission; null where that's not
  /// possible (tests).
  final Future<bool> Function()? requestPermission;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late String _source = sourceForSystemLanguage(widget.systemLanguage);

  /// Interface language: the phone's until "I speak" is confirmed.
  late String _uiSource = _source;

  List<AvailablePair>? _pairs;
  bool _offline = false;
  String? _target;

  // Steps 3 + 4
  String _level = defaultLevel;
  Set<String> _topics = {};

  // Step 5
  bool _preparing = false;
  SyncStage? _stage;
  LanguagePair? _preparedFor;
  bool _fellBack = false;
  int? _readyWords;
  Word? _previewWord;
  bool? _notificationsAllowed;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadPairs();
  }

  Future<void> _loadPairs() async {
    final result = await context.read<LanguageSettings>().availablePairs();
    if (!mounted) return;
    setState(() {
      _pairs = result.pairs;
      _offline = result.offline;
    });
  }

  /// Pairs for the chosen source; empty when that source has none (offline).
  List<AvailablePair> get _targetsForSource =>
      (_pairs ?? const <AvailablePair>[]).where((p) => p.pair.source == _source).toList();

  /// Offline (or nothing ready yet) for this source: only the built-in pair.
  bool get _onlyBuiltIn => _pairs != null && _targetsForSource.isEmpty;

  List<AvailablePair> get _targetChoices {
    if (_onlyBuiltIn) return [_pairs!.firstWhere((p) => p.pair.isBuiltIn)];
    return _targetsForSource;
  }

  LanguagePair get _chosenPair {
    if (_onlyBuiltIn || _target == null) return builtInPair;
    return LanguagePair(_source, _target!);
  }

  /// What will actually be saved: the built-in pair if the download failed.
  LanguagePair get _effectivePair => _fellBack ? builtInPair : _chosenPair;

  void _next() {
    switch (_step) {
      case 0:
        setState(() {
          _uiSource = _source;
          _step = 1;
          final choices = _targetChoices;
          if (choices.isNotEmpty && !choices.any((c) => c.pair.target == _target)) {
            _target = choices.first.pair.target;
          }
        });
      case 1:
        setState(() => _step = 2);
        _prepare();
      case 2 || 3:
        setState(() => _step++);
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  Future<void> _prepare() async {
    final pair = _chosenPair;
    if (_preparedFor == pair && !_fellBack) return;
    final settings = context.read<LanguageSettings>();
    final repo = context.read<Repository>();
    setState(() {
      _preparing = true;
      _fellBack = false;
      _stage = null;
      _readyWords = null;
      _previewWord = null;
    });
    final ok = await settings.prepareWords(pair, onStage: (s) {
      if (mounted) setState(() => _stage = s);
    });
    // Offline or not available after all: start with the built-in pair.
    if (!ok) await settings.prepareWords(builtInPair);
    final effective = ok ? pair : builtInPair;
    final fellBack = !ok;
    final count = await repo.wordCount(effective.target);
    final preview = await repo.firstWordOf(effective.target);
    if (!mounted) return;
    setState(() {
      _preparing = false;
      _preparedFor = pair;
      _fellBack = fellBack;
      _readyWords = count;
      _previewWord = preview;
    });
  }

  Future<void> _allowNotifications() async {
    final request = widget.requestPermission;
    final granted = request == null ? true : await request();
    if (mounted) setState(() => _notificationsAllowed = granted);
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final pair = _effectivePair;
    await context.read<LearningPrefs>().update(level: _level, topics: _topics);
    if (!mounted) return;
    await context.read<LanguageSettings>().completeOnboarding(
          pair,
          // Offline fallback to en-de: keep the language picked in step 1.
          wantedSource: _source != pair.source ? _source : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Localizations.override(
      context: context,
      locale: Locale(_uiSource),
      child: Builder(builder: (context) {
        final l = context.l10n;
        return PopScope(
          canPop: _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _back();
          },
          child: AppBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            if (_step > 0)
                              IconButton(
                                key: const Key('onb-back'),
                                tooltip: l.onbBack,
                                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                                onPressed: _back,
                              ),
                            const Spacer(),
                            _ProgressDots(step: _step),
                            const Spacer(),
                            if (_step > 0) const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        switch (_step) {
                          0 => l.onbISpeak,
                          1 => l.onbIWantToLearn,
                          2 => l.onbYourLevel,
                          3 => l.onbYourWork,
                          _ => l.onbHowItWorks,
                        },
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          // Short steps start at the top, under the title.
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: switch (_step) {
                              0 => _sourceStep(),
                              1 => _targetStep(l),
                              2 => _levelStep(l),
                              3 => _workStep(l),
                              _ => _howStep(l),
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _primaryButton(l),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _primaryButton(AppLocalizations l) {
    final isLast = _step == 4;
    final enabled = switch (_step) {
      0 || 2 || 3 => true,
      1 => _pairs != null && _targetChoices.isNotEmpty,
      _ => !_preparing && !_starting,
    };
    return FilledButton(
      key: Key(isLast ? 'onb-start' : 'onb-continue'),
      onPressed: enabled ? (isLast ? _start : _next) : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: Text(isLast ? l.onbStart : (_step == 3 && _topics.isEmpty ? l.skip : l.onbContinue)),
    );
  }

  Widget _sourceStep() {
    return _Scroll(children: [
        for (final code in sourceLanguages)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LanguageCard(
              key: Key('lang-$code'),
              language: languageOf(code),
              selected: _source == code,
              onTap: () => setState(() => _source = code),
            ),
          ),
      ],
    );
  }

  Widget _targetStep(AppLocalizations l) {
    if (_pairs == null) {
      return Column(
        children: [
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(l.onbLoadingPairs, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
    }
    final choices = _targetChoices;
    return _Scroll(children: [
        for (final p in choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LanguageCard(
              key: Key('lang-${p.pair.target}'),
              language: languageOf(p.pair.target),
              subtitle: p.words > 0 ? l.onbWordCount(p.words) : null,
              selected: _target == p.pair.target || choices.length == 1,
              onTap: () => setState(() => _target = p.pair.target),
            ),
          ),
        if (_onlyBuiltIn)
          _Note(l.onbOfflineOnlyBuiltIn)
        else if (_offline)
          _Note(l.onbOfflineNote),
      ],
    );
  }

  Widget _levelStep(AppLocalizations l) {
    return _Scroll(children: [
      _Hint(l.onbYourLevelHint),
      LevelPicker(selected: _level, onChanged: (v) => setState(() => _level = v)),
    ]);
  }

  Widget _workStep(AppLocalizations l) {
    return _Scroll(children: [
      _Hint(l.onbYourWorkHint),
      TopicPicker(selected: _topics, onChanged: (v) => setState(() => _topics = v)),
    ]);
  }

  Widget _howStep(AppLocalizations l) {
    final pair = _effectivePair;
    final sample = _previewWord != null && !_preparing ? _Preview.fromWord(_previewWord!) : _Preview.sample(pair);
    return _Scroll(children: [
        Text(l.onbPreviewIntro, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.35)),
        const SizedBox(height: 16),
        _Label(l.onbNotificationLabel),
        const SizedBox(height: 6),
        _NotificationPreview(preview: sample),
        const SizedBox(height: 14),
        _Label(l.onbWidgetLabel),
        const SizedBox(height: 6),
        _WidgetPreview(preview: sample),
        const SizedBox(height: 12),
        _progressLine(l),
        const SizedBox(height: 16),
        Text(l.onbPermissionWhy, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('onb-allow'),
          onPressed: _notificationsAllowed == true ? null : _allowNotifications,
          icon: Icon(_notificationsAllowed == true ? Icons.check_rounded : Icons.notifications_active_outlined),
          label: Text(_notificationsAllowed == true ? l.onbAllowed : l.onbAllow),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.glassBorder),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _progressLine(AppLocalizations l) {
    if (_preparing) {
      final progress = switch (_stage) {
        null => null,
        SyncStage.checking => 0.15,
        SyncStage.downloading => 0.5,
        SyncStage.saving => 0.85,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.downloadingWords, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              color: AppColors.accent,
              backgroundColor: AppColors.glassFill,
            ),
          ),
        ],
      );
    }
    if (_fellBack) return _Note(l.onbDownloadFailed);
    if (_readyWords != null && _readyWords! > 0) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(l.onbDownloaded(_readyWords!), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == step ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.accent : AppColors.glassBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 16),
        child: Text(text, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.35)),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ],
        ),
      );
}

/// What the preview shows: a real word once available, else a sample.
class _Preview {
  const _Preview({required this.title, required this.translation, required this.example});

  factory _Preview.fromWord(Word w) {
    final flag = flagOf(w.lang);
    return _Preview(title: '$flag ${wordTitle(w)}', translation: w.translation, example: w.example);
  }

  factory _Preview.sample(LanguagePair pair) {
    if (pair.target == 'en') {
      const tr = {'uz': 'olma', 'ru': 'яблоко'};
      return _Preview(title: '🇬🇧 apple', translation: tr[pair.source] ?? 'apple', example: 'I eat an apple every day.');
    }
    const tr = {'en': 'key', 'uz': 'kalit', 'ru': 'ключ'};
    return _Preview(title: '🇩🇪 der Schlüssel', translation: tr[pair.source] ?? 'key', example: 'Wo ist mein Schlüssel?');
  }

  final String title;
  final String translation;
  final String example;
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.preview});
  final _Preview preview;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('OSG',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OSG · 08:00', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(preview.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(preview.translation, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.preview});
  final _Preview preview;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 230,
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(preview.translation, style: const TextStyle(fontSize: 14, color: AppColors.accent)),
              const SizedBox(height: 2),
              Text(preview.example,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step content: a plain scroll view (only a few children, all built).
class _Scroll extends StatelessWidget {
  const _Scroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}
