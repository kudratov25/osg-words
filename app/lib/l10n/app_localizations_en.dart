// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OSG — Words every day';

  @override
  String get navHome => 'Home';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navVocabulary => 'Vocabulary';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeToday => 'Today';

  @override
  String get statWordsLearned => 'Words learned';

  @override
  String get statTodaysDone => 'Today\'s done';

  @override
  String get statStreak => 'Streak';

  @override
  String streakValue(int days) {
    return '${days}d';
  }

  @override
  String get homeUpcomingReminder => 'Upcoming reminder';

  @override
  String get homeNothingLeft => 'Nothing left scheduled today.';

  @override
  String get homeTodaysSchedule => 'Today\'s schedule';

  @override
  String get homeNoRemindersToday => 'No reminders today.';

  @override
  String get homeWordRightNow => 'Word right now';

  @override
  String get homeNoVocabulary => 'No vocabulary loaded yet.';

  @override
  String get homeTodaysWords => 'Today\'s words';

  @override
  String homeSince(String time) {
    return 'since $time';
  }

  @override
  String get homeFromYesterday => 'from yesterday';

  @override
  String homeFromLastNight(String time) {
    return 'from last night · next at $time';
  }

  @override
  String homeNoPeeking(String time) {
    return 'This word arrives at $time — no peeking 🙂';
  }

  @override
  String homeSlotWord(String time) {
    return '$time word';
  }

  @override
  String homeOpenWord(String word) {
    return 'Open $word';
  }

  @override
  String homeWordArriving(String time) {
    return 'Word arriving at $time';
  }

  @override
  String homeArrivesAt(String time) {
    return 'Arrives at $time';
  }

  @override
  String get homeNow => 'now';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get scheduleEmpty => 'No reminders yet. Tap + to add one.';

  @override
  String get reminderEdit => 'Edit Reminder';

  @override
  String get reminderNew => 'New Reminder';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get reminderDescLabel => 'Description (optional)';

  @override
  String get reminderTime => 'Time';

  @override
  String get reminderRepeat => 'Repeat';

  @override
  String get reminderDate => 'Date';

  @override
  String get reminderDayOfMonth => 'Day of month:';

  @override
  String get reminderSave => 'Save changes';

  @override
  String get reminderCreate => 'Create reminder';

  @override
  String get reminderDelete => 'Delete';

  @override
  String get repeatOnce => 'Once';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekdays => 'Weekdays';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get vocabTitle => 'Vocabulary';

  @override
  String get tabToday => 'Today';

  @override
  String get tabYesterday => 'Yesterday';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get vocabNoToday => 'No words assigned yet today.';

  @override
  String get vocabNoYesterday => 'No words shown yesterday.';

  @override
  String get vocabNoFavorites => 'No favorites yet — tap the star on a word.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyCurrentStreak => 'Current streak';

  @override
  String get historyEmpty =>
      'No activity yet — history fills in once reminders and words start being delivered.';

  @override
  String get historyVocabulary => 'Vocabulary';

  @override
  String get historyReminder => 'Reminder';

  @override
  String get historyWord => 'word';

  @override
  String get dayToday => 'Today';

  @override
  String get dayYesterday => 'Yesterday';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTelemetryTitle => 'Share anonymous usage data';

  @override
  String get settingsTelemetrySubtitle =>
      'Device model, OS version, language pair and app-open activity only — no account, no personal data.';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Vocabulary words and reminders are delivered via local notifications, scheduled entirely on this device.';

  @override
  String get settingsFixPermissions => 'Fix notification permissions';

  @override
  String get settingsPermissionsDone =>
      'Permissions requested and notifications rescheduled.';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'OSG — focus & vocabulary — v$version';
  }

  @override
  String get settingsLanguages => 'Languages';

  @override
  String get settingsISpeak => 'I speak';

  @override
  String get settingsILearn => 'I\'m learning';

  @override
  String get settingsPairChanged => 'Languages updated.';

  @override
  String get settingsPairFailed =>
      'Couldn\'t download the words for this language. Check your connection and try again.';

  @override
  String get settingsNoOtherTargets =>
      'No other languages are available for this right now.';

  @override
  String get downloadingWords => 'Downloading words…';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountIntro =>
      'Optional. Keep your progress if you change phones — we only need your email.';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountSendCode => 'Send code';

  @override
  String accountCodeSent(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String get accountCodeLabel => '6-digit code';

  @override
  String get accountVerify => 'Verify';

  @override
  String get accountOtherEmail => 'Use a different email';

  @override
  String accountSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteConfirmTitle => 'Delete account?';

  @override
  String get accountDeleteConfirmBody =>
      'This deletes your account and the data linked to it on our server. Words and reminders on this phone stay.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get accountDeleted => 'Account deleted.';

  @override
  String get accountSignedOut => 'Signed out.';

  @override
  String get accountInvalidEmail => 'Please enter a valid email address.';

  @override
  String get accountWrongCode =>
      'That code didn\'t work. Check it and try again.';

  @override
  String get accountTooMany =>
      'Too many attempts. Please wait a few minutes and try again.';

  @override
  String get accountCodeExpired => 'That code has expired. Request a new one.';

  @override
  String get networkError =>
      'No connection. Please try again when you\'re online.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get reportTitle => 'Report a mistake';

  @override
  String get reportKindTranslation => 'Wrong translation';

  @override
  String get reportKindArticle => 'Wrong article';

  @override
  String get reportKindExample => 'Wrong example';

  @override
  String get reportKindOther => 'Something else';

  @override
  String get reportNoteHint => 'Add a note (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportThanks => 'Thanks! We\'ll check this word.';

  @override
  String get reportOffline => 'You\'re offline — please try again later.';

  @override
  String get reportTooMany =>
      'You\'ve sent a lot of reports today. Please try again tomorrow.';

  @override
  String get notifTodaysGoal => 'Today\'s goal:';

  @override
  String get notifReminder => 'Reminder';

  @override
  String get notifTodaysWord => 'Today\'s word:';

  @override
  String get notifNudgeTitle => 'Your next words are waiting';

  @override
  String get notifNudgeBody =>
      'Open OSG to keep your daily words and reminders coming.';

  @override
  String get notifChannelName => 'Reminders & Vocabulary';

  @override
  String get notifChannelDescription => 'Vocabulary words and task reminders';

  @override
  String get onbISpeak => 'I speak';

  @override
  String get onbIWantToLearn => 'I want to learn';

  @override
  String get onbHowItWorks => 'Here\'s how it works';

  @override
  String get onbContinue => 'Continue';

  @override
  String get onbBack => 'Back';

  @override
  String get onbStart => 'Start';

  @override
  String onbWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get onbOfflineNote =>
      'You\'re offline — more languages appear once you\'re connected.';

  @override
  String get onbOfflineOnlyBuiltIn =>
      'Offline: for now only German with English translations. Your language\'s words download automatically once you\'re online.';

  @override
  String get onbPreviewIntro =>
      'Three words a day arrive as notifications — at 08:00, 12:00 and 18:00 — and on your home-screen widget.';

  @override
  String get onbNotificationLabel => 'Notification';

  @override
  String get onbWidgetLabel => 'Widget';

  @override
  String get onbPermissionWhy =>
      'Allow notifications so your words and reminders can reach you.';

  @override
  String get onbAllow => 'Allow notifications';

  @override
  String get onbAllowed => 'Notifications allowed';

  @override
  String onbDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words ready',
      one: '1 word ready',
    );
    return '$_temp0';
  }

  @override
  String get onbDownloadFailed =>
      'Couldn\'t download this language — starting with English translations for now. OSG will try again automatically.';

  @override
  String get onbLoadingPairs => 'Loading languages…';

  @override
  String get showMeaning => 'Show meaning';

  @override
  String get catDailyLife => 'Daily Life';

  @override
  String get catWork => 'Work';

  @override
  String get catFood => 'Food';

  @override
  String get catCommonVerbs => 'Common Verbs';

  @override
  String get catTravel => 'Travel';

  @override
  String get catEmotions => 'Emotions';

  @override
  String get catAdjectives => 'Adjectives';

  @override
  String get catTime => 'Time';

  @override
  String get catMoney => 'Money';

  @override
  String get catHealth => 'Health';

  @override
  String get catWeather => 'Weather';

  @override
  String get catSocial => 'Social';

  @override
  String get catHome => 'Home';

  @override
  String get catFamily => 'Family';

  @override
  String get catEducation => 'Education';

  @override
  String get catShopping => 'Shopping';

  @override
  String get catNature => 'Nature';

  @override
  String get refreshUpdated => 'Words updated';

  @override
  String get refreshUpToDate => 'Words are up to date';

  @override
  String get refreshFailed =>
      'Couldn\'t check for new words. Check your connection.';

  @override
  String get levelA1 => 'Beginner';

  @override
  String get levelA1Desc => 'I know only a few words';

  @override
  String get levelA2 => 'Elementary';

  @override
  String get levelA2Desc => 'I manage simple everyday situations';

  @override
  String get levelB1 => 'Intermediate';

  @override
  String get levelB1Desc => 'I can talk about familiar topics';

  @override
  String get levelB2 => 'Upper intermediate';

  @override
  String get levelB2Desc => 'I speak fairly fluently';

  @override
  String get levelC1 => 'Advanced';

  @override
  String get levelC1Desc => 'I understand almost everything';

  @override
  String get topicRetail => 'Retail & sales';

  @override
  String get topicIt => 'IT';

  @override
  String get topicMedicine => 'Medicine';

  @override
  String get topicHospitality => 'Hotels & restaurants';

  @override
  String get topicConstruction => 'Construction';

  @override
  String get topicLogistics => 'Logistics & driving';

  @override
  String get topicOffice => 'Office & business';

  @override
  String get topicCare => 'Care work';

  @override
  String get settingsLearning => 'LEARNING';

  @override
  String get settingsLevel => 'My level';

  @override
  String get settingsTopics => 'Work areas';

  @override
  String get settingsTopicsNone => 'None';

  @override
  String get settingsLearningChanged => 'Saved. Today\'s words were updated.';

  @override
  String get onbYourLevel => 'Your level';

  @override
  String get onbYourLevelHint =>
      'You\'ll get words of this level and a little above.';

  @override
  String get onbYourWork => 'Your work';

  @override
  String get onbYourWorkHint =>
      'Pick any that fit — we\'ll add words for your job. You can skip this.';

  @override
  String get done => 'Done';

  @override
  String get skip => 'Skip';

  @override
  String get tourRefreshTitle => 'Pull down to update';

  @override
  String get tourRefreshBody =>
      'New and corrected words arrive right away when you pull down here.';

  @override
  String get tourWordTitle => 'Your word right now';

  @override
  String get tourWordBody =>
      '3 words a day as notifications: 08:00, 12:00 and 18:00. Tap ⚑ on a card to report a mistake.';

  @override
  String get tourVocabTitle => 'All your words';

  @override
  String get tourVocabBody =>
      'Today\'s and yesterday\'s words and your favourites.';

  @override
  String get tourScheduleTitle => 'Your reminders';

  @override
  String get tourScheduleBody =>
      'Add your own reminders — they come together with your words.';

  @override
  String get tourSettingsTitle => 'Make it yours';

  @override
  String get tourSettingsBody =>
      'Change your level, work areas and languages any time.';

  @override
  String get tourNext => 'Next';

  @override
  String get tourGotIt => 'Got it';

  @override
  String get widgetTitle => 'Add the OSG widget';

  @override
  String get widgetBody =>
      'See your word on the Home Screen without opening the app.';

  @override
  String get widgetAddButton => 'Add widget';

  @override
  String get widgetLater => 'Later';

  @override
  String get widgetIosStep1 =>
      'Touch and hold an empty spot on the Home Screen';

  @override
  String get widgetIosStep2 => 'Tap + in the top corner';

  @override
  String get widgetIosStep3 => 'Find OSG and tap Add Widget';

  @override
  String get widgetIosLock =>
      'Lock Screen: touch and hold it, tap Customize, then add OSG.';

  @override
  String get widgetAndroidManual =>
      'Touch and hold an empty spot on the Home Screen, tap Widgets, then find OSG.';

  @override
  String get settingsHelp => 'HELP';

  @override
  String get settingsShowGuide => 'Show the app guide again';

  @override
  String get settingsAddWidget => 'Add the widget';

  @override
  String get widgetAndroidMove =>
      'Some phones (e.g. Xiaomi) put it on a later page. To place it exactly where you want: touch and hold an empty spot on your main screen → Widgets → OSG, and drag it there.';
}
