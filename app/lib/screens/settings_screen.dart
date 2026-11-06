import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/languages.dart';
import '../data/levels.dart';
import '../l10n/l10n.dart';
import '../notifications/notification_service.dart';
import '../notifications/scheduler.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';
import '../services/language_settings.dart';
import '../services/learning_prefs.dart';
import '../services/telemetry.dart' show telemetryPrefKey;
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/language_card.dart';
import '../widgets/learning_pickers.dart';
import '../guide/add_widget_sheet.dart';
import '../guide/guide_controller.dart';
import '../widgets/report_sheet.dart' show showGlassSheet;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _telemetryEnabled = true;
  bool _loaded = false;
  bool _accountsEnabled = false;
  bool _changingPair = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _telemetryEnabled = prefs.getBool(telemetryPrefKey) ?? true;
      _loaded = true;
    });
    final enabled = await auth.isEnabled();
    if (mounted) setState(() => _accountsEnabled = enabled);
  }

  Future<void> _setTelemetry(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(telemetryPrefKey, value);
    setState(() => _telemetryEnabled = value);
  }

  Future<void> _fixNotificationReliability(BuildContext context) async {
    final l = context.l10n;
    await NotificationService.instance.requestPermissions();
    // MIUI (and other OEM skins) aggressively kill background alarms
    // unless the app is exempted from battery optimization - without it,
    // scheduled notifications can silently stop after a while. The direct
    // exemption prompt needs REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, which
    // Google Play restricts, so open the app's settings page instead
    // (Battery -> No restrictions). Checking the status needs no permission.
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await openAppSettings();
    }
    if (context.mounted) {
      await context.read<NotificationScheduler>().refreshAll();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.settingsPermissionsDone)));
    }
  }

  // --- Languages ---------------------------------------------------------

  Future<void> _pickSource() async {
    final settings = context.read<LanguageSettings>();
    final current = settings.pair;
    final picked = await showGlassSheet<String>(
      context,
      (sheetContext) => _LanguagePicker(
        title: sheetContext.l10n.settingsISpeak,
        options: [for (final code in sourceLanguages) (code: code, subtitle: null)],
        selected: current.source,
      ),
    );
    if (picked == null || picked == current.source) return;
    // Keep the target if that pair exists, else the first one for the new source.
    final available = await settings.availablePairs();
    final targets = available.pairs.where((p) => p.pair.source == picked).map((p) => p.pair.target).toList();
    if (!mounted) return;
    if (targets.isEmpty) {
      _snack(available.offline ? context.l10n.networkError : context.l10n.settingsPairFailed);
      return;
    }
    final target = targets.contains(current.target) ? current.target : targets.first;
    await _change(LanguagePair(picked, target));
  }

  Future<void> _pickTarget() async {
    final settings = context.read<LanguageSettings>();
    final current = settings.pair;
    final available = await settings.availablePairs();
    if (!mounted) return;
    final options = available.pairs.where((p) => p.pair.source == current.source).toList();
    if (options.length <= 1) {
      _snack(available.offline ? context.l10n.networkError : context.l10n.settingsNoOtherTargets);
      if (options.isEmpty) return;
    }
    final picked = await showGlassSheet<String>(
      context,
      (sheetContext) => _LanguagePicker(
        title: sheetContext.l10n.settingsILearn,
        options: [
          for (final p in options) (code: p.pair.target, subtitle: p.words > 0 ? sheetContext.l10n.onbWordCount(p.words) : null),
        ],
        selected: current.target,
      ),
    );
    if (picked == null || picked == current.target) return;
    await _change(LanguagePair(current.source, picked));
  }

  Future<void> _change(LanguagePair pair) async {
    final settings = context.read<LanguageSettings>();
    setState(() => _changingPair = true);
    final ok = await settings.changePair(pair);
    if (!mounted) return;
    setState(() => _changingPair = false);
    // The interface may have just switched language; this context still
    // has the old strings until the next frame, so use the new pair's.
    final l = stringsFor(settings.uiLanguage);
    _snack(ok ? l.settingsPairChanged : l.settingsPairFailed);
  }

  // --- Learning (level + work areas) --------------------------------------

  Future<void> _pickLevel() async {
    final prefs = context.read<LearningPrefs>();
    final picked = await showGlassSheet<String>(
      context,
      (sheetContext) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetTitle(sheetContext.l10n.settingsLevel),
            LevelPicker(selected: prefs.level, onChanged: (v) => Navigator.of(sheetContext).pop(v)),
          ],
        ),
      ),
    );
    if (picked == null || picked == prefs.level || !mounted) return;
    await prefs.update(level: picked);
    if (mounted) _snack(context.l10n.settingsLearningChanged);
  }

  Future<void> _pickTopics() async {
    final prefs = context.read<LearningPrefs>();
    var current = {...prefs.topics};
    final picked = await showGlassSheet<Set<String>>(
      context,
      (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetTitle(sheetContext.l10n.settingsTopics),
              TopicPicker(selected: current, onChanged: (v) => setSheet(() => current = v)),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('topics-done'),
                onPressed: () => Navigator.of(sheetContext).pop(current),
                child: Text(sheetContext.l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final changed = !(picked.length == prefs.topics.length && picked.containsAll(prefs.topics));
    await prefs.update(topics: picked);
    if (changed && mounted) _snack(context.l10n.settingsLearningChanged);
  }

  void _snack(String text) {
    if (!mounted || text.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final l = context.l10n;
    final pair = context.watch<LanguageSettings>().pair;
    final auth = context.watch<AuthService>();
    final learning = context.watch<LearningPrefs>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text(
          l.settingsTitle,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 24),
        _SectionHeader(l.settingsLanguages),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _LanguageRow(
                key: const Key('settings-source'),
                label: l.settingsISpeak,
                language: languageOf(pair.source),
                onTap: _changingPair ? null : _pickSource,
              ),
              const Divider(height: 1, color: AppColors.glassBorder),
              _LanguageRow(
                key: const Key('settings-target'),
                label: l.settingsILearn,
                language: languageOf(pair.target),
                onTap: _changingPair ? null : _pickTarget,
              ),
              if (_changingPair)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l.downloadingWords, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(l.settingsLearning),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              _ValueRow(
                key: const Key('settings-level'),
                label: l.settingsLevel,
                value: '${learning.level} · ${levelName(l, learning.level)}',
                onTap: _pickLevel,
              ),
              const Divider(height: 1, color: AppColors.glassBorder),
              _ValueRow(
                key: const Key('settings-topics'),
                label: l.settingsTopics,
                value: learning.topics.isEmpty
                    ? l.settingsTopicsNone
                    : [for (final t in jobTopics) if (learning.topics.contains(t)) topicEmoji[t]].join(' '),
                onTap: _pickTopics,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_accountsEnabled || auth.signedIn) ...[
          _SectionHeader(l.accountTitle),
          const _AccountSection(),
          const SizedBox(height: 16),
        ],
        GlassContainer(
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _telemetryEnabled,
            onChanged: _setTelemetry,
            activeThumbColor: AppColors.accent,
            title: Text(l.settingsTelemetryTitle, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(
              l.settingsTelemetrySubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.settingsNotificationsTitle, style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: Text(
                  l.settingsNotificationsSubtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _fixNotificationReliability(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
                child: Text(l.settingsFixPermissions),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(l.settingsHelp),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Column(
            children: [
              ListTile(
                key: const Key('settings-guide'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.school_rounded, color: AppColors.accent),
                title: Text(l.settingsShowGuide, style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () => context.read<GuideController?>()?.start(),
              ),
              const Divider(height: 1, color: AppColors.glassBorder),
              ListTile(
                key: const Key('settings-widget'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.widgets_rounded, color: AppColors.accent),
                title: Text(l.settingsAddWidget, style: const TextStyle(color: AppColors.textPrimary)),
                onTap: () => showAddWidgetSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.settingsAbout, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(l.settingsAboutVersion(appVersion),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      );
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value, required this.onTap, super.key});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.label, required this.language, required this.onTap, super.key});

  final String label;
  final Language language;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${language.flag}  ${language.nativeName}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

/// Same big cards as onboarding; pops with the picked language code.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.title, required this.options, required this.selected});

  final String title;
  final List<({String code, String? subtitle})> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LanguageCard(
                key: Key('pick-${o.code}'),
                language: languageOf(o.code),
                subtitle: o.subtitle,
                selected: o.code == selected,
                onTap: () => Navigator.of(context).pop(o.code),
              ),
            ),
        ],
      ),
    );
  }
}

/// Email -> 6-digit code -> signed in. Nothing else is asked.
class _AccountSection extends StatefulWidget {
  const _AccountSection();

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _codeSentTo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  String _message(AppLocalizations l, AuthError e) => switch (e) {
        AuthError.invalidEmail => l.accountInvalidEmail,
        AuthError.wrongCode => l.accountWrongCode,
        AuthError.codeExpired => l.accountCodeExpired,
        AuthError.tooManyAttempts => l.accountTooMany,
        AuthError.network => l.networkError,
        AuthError.unavailable || AuthError.unknown => l.genericError,
      };

  Future<void> _run(Future<void> Function() action) async {
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _message(l, e.error));
    } catch (_) {
      if (mounted) setState(() => _error = l.genericError);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendCode() => _run(() async {
        final email = _email.text.trim();
        await context.read<AuthService>().startEmail(email);
        if (mounted) setState(() => _codeSentTo = email);
      });

  Future<void> _verify() => _run(() async {
        await context.read<AuthService>().verifyCode(_codeSentTo!, _code.text);
        if (mounted) {
          setState(() => _codeSentTo = null);
          _code.clear();
        }
      });

  Future<void> _signOut() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await _run(() => context.read<AuthService>().signOut());
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.accountSignedOut)));
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundGradientEnd,
        title: Text(l.accountDeleteConfirmTitle),
        content: Text(l.accountDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l.cancel)),
          TextButton(
            key: const Key('account-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8FA8)),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var ok = false;
    await _run(() async {
      await context.read<AuthService>().deleteAccount();
      ok = true;
    });
    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.accountDeleted)));
    }
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final auth = context.watch<AuthService>();
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.background,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final children = <Widget>[];

    if (auth.signedIn) {
      children.addAll([
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.accountSignedInAs(auth.email ?? ''),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const Key('account-signout'),
          onPressed: _busy ? null : _signOut,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          child: Text(l.accountSignOut),
        ),
        TextButton(
          key: const Key('account-delete'),
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8FA8)),
          child: Text(l.accountDelete),
        ),
      ]);
    } else if (_codeSentTo == null) {
      children.addAll([
        Text(l.accountIntro, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          key: const Key('account-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _field(l.accountEmailLabel),
          onSubmitted: (_) => _sendCode(),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('account-send'),
          onPressed: _busy ? null : _sendCode,
          style: buttonStyle,
          child: Text(l.accountSendCode),
        ),
      ]);
    } else {
      children.addAll([
        Text(l.accountCodeSent(_codeSentTo!), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        TextField(
          key: const Key('account-code'),
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, letterSpacing: 6),
          decoration: _field(l.accountCodeLabel).copyWith(counterText: ''),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const Key('account-verify'),
          onPressed: _busy ? null : _verify,
          style: buttonStyle,
          child: Text(l.accountVerify),
        ),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _codeSentTo = null;
                    _error = null;
                    _code.clear();
                  }),
          child: Text(l.accountOtherEmail),
        ),
      ]);
    }

    if (_error != null) {
      children.addAll([
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: Color(0xFFFF8FA8), fontSize: 13)),
      ]);
    }
    return GlassContainer(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
  }
}
