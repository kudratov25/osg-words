import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'data/db/app_database.dart';
import 'data/repository.dart';
import 'l10n/l10n.dart';
import 'notifications/notification_service.dart';
import 'notifications/scheduler.dart';
import 'notifications/widget_sync.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_config.dart';
import 'services/auth_service.dart';
import 'services/content_sync.dart';
import 'services/feedback_api.dart';
import 'services/language_settings.dart';
import 'services/learning_prefs.dart';
import 'guide/guide_controller.dart';
import 'services/telemetry.dart';
import 'theme/glass_theme.dart';
import 'widgets/root_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OsgApp());
}

class OsgApp extends StatefulWidget {
  const OsgApp({
    super.key,
    this.database,
    this.enableNotifications = true,
    this.enableNetwork = true,
    this.httpClient,
    this.apiBaseUrl,
    this.tokenStore,
    this.systemLanguage,
    this.enableGuide = true,
  });

  /// First-run guide (coach marks + widget prompt). Off in widget tests:
  /// its looping animations never let pumpAndSettle settle.
  final bool enableGuide;

  /// Overridable for widget tests, which pass an in-memory database.
  final AppDatabase? database;

  /// Widget tests run with no platform channels, so real notification
  /// scheduling (which talks to Android/iOS) is skipped there.
  final bool enableNotifications;

  /// Content sync, telemetry, reports, accounts. Off in most widget tests.
  final bool enableNetwork;

  /// Tests: fake backend + its address (defaults: real client, [apiBaseUrl]).
  final http.Client? httpClient;
  final String? apiBaseUrl;

  /// Tests: in-memory account token store instead of the Keychain/Keystore.
  final TokenStore? tokenStore;

  /// Tests: the phone's language (defaults to the real system language).
  final String? systemLanguage;

  @override
  State<OsgApp> createState() => _OsgAppState();
}

class _OsgAppState extends State<OsgApp> with WidgetsBindingObserver {
  late final AppDatabase _database;
  late final Repository _repository;
  late final NotificationScheduler _scheduler;
  late final Telemetry _telemetry;
  late final ContentSync _contentSync;
  late final FeedbackApi _feedback;
  late final AuthService _auth;
  late final LanguageSettings _settings;
  late final LearningPrefs _learning;
  late final GuideController _guide = GuideController(enabled: widget.enableGuide);
  late final Future<void> _initFuture;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final baseUrl = widget.enableNetwork ? (widget.apiBaseUrl ?? apiBaseUrl) : '';
    final client = widget.httpClient ?? http.Client();
    _database = widget.database ?? AppDatabase();
    _repository = Repository(_database);
    _scheduler = NotificationScheduler(_repository, NotificationService.instance);
    _telemetry = Telemetry(client: client, baseUrl: baseUrl);
    _contentSync = ContentSync(_repository, client: client, baseUrl: baseUrl)..addListener(_onContentMerged);
    _feedback = FeedbackApi(client: client, baseUrl: baseUrl);
    _auth = AuthService(client: client, baseUrl: baseUrl, store: widget.tokenStore);
    _settings = LanguageSettings(_repository, _contentSync, onPairApplied: _onPairApplied)
      ..addListener(_onSettingsChanged);
    _learning = LearningPrefs(_repository, onChanged: _onPairApplied);
    _initFuture = _init();
  }

  /// Network work runs in the background so it never delays app start.
  void _onAppOpened() {
    if (!widget.enableNetwork) return;
    _telemetry.send(TelemetryEvent.appOpen);
    if (_settings.wantedSource != null) {
      // Onboarding was offline: now try the language pair the user picked.
      // On success changePair reschedules everything (onPairApplied).
      _settings.retryWantedPair();
      return;
    }
    _contentSync.syncIfDue();
  }

  /// New/fixed words arrived (background check or pull-to-refresh): rebuild
  /// notifications and the widget so they show the new text right away.
  void _onContentMerged() {
    if (widget.enableNotifications && _running) _scheduler.refreshAll();
  }

  Future<void> _init() async {
    await _settings.load();
    await _learning.load();
    await _repository.seedWordsIfEmpty();
    // Not awaited: only Settings -> Account needs it, and it notifies.
    _auth.load();
    if (_settings.onboardingDone) await _startRunning();
  }

  /// Notifications, widget and syncing - once onboarding is done.
  Future<void> _startRunning() async {
    if (_running) return;
    _running = true;
    if (!widget.enableNotifications) return;

    await WidgetSync.init();
    await NotificationService.instance.init(
      onTap: widget.enableNetwork ? () => _telemetry.send(TelemetryEvent.notifTapped) : null,
    );
    await _updateChannelTexts();
    await NotificationService.instance.requestPermissions();
    await _scheduler.refreshAll();
    _onAppOpened();
  }

  Future<void> _updateChannelTexts() {
    final l = stringsFor(_settings.uiLanguage);
    return NotificationService.instance.setChannelTexts(name: l.notifChannelName, description: l.notifChannelDescription);
  }

  void _onSettingsChanged() {
    if (_settings.onboardingDone && !_running) _startRunning();
  }

  /// Pair changed in Settings: new words/strings everywhere.
  Future<void> _onPairApplied() async {
    if (!widget.enableNotifications || !_running) return;
    await _updateChannelTexts();
    await _scheduler.refreshAll();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enableNotifications && _running) {
      _scheduler.refreshAll();
      _onAppOpened();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    _contentSync.removeListener(_onContentMerged);
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MultiProvider(
          providers: [
            Provider<Repository>.value(value: _repository),
            Provider<NotificationScheduler>.value(value: _scheduler),
            ChangeNotifierProvider<ContentSync>.value(value: _contentSync),
            Provider<FeedbackApi>.value(value: _feedback),
            ChangeNotifierProvider<AuthService>.value(value: _auth),
            ChangeNotifierProvider<LanguageSettings>.value(value: _settings),
            ChangeNotifierProvider<LearningPrefs>.value(value: _learning),
            ChangeNotifierProvider<GuideController?>.value(value: _guide),
          ],
          child: ListenableBuilder(
            listenable: _settings,
            builder: (context, _) => MaterialApp(
              onGenerateTitle: (context) => context.l10n.appTitle,
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              locale: _settings.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: _settings.onboardingDone
                  ? const RootScaffold()
                  : OnboardingScreen(
                      systemLanguage:
                          widget.systemLanguage ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode,
                      requestPermission: widget.enableNotifications ? _requestPermissionFromOnboarding : null,
                    ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _requestPermissionFromOnboarding() async {
    await NotificationService.instance.init(
      onTap: widget.enableNetwork ? () => _telemetry.send(TelemetryEvent.notifTapped) : null,
    );
    return NotificationService.instance.requestPermissions();
  }
}
