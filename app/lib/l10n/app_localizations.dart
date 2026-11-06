import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OSG — Words every day'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// No description provided for @navVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get navVocabulary;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @statWordsLearned.
  ///
  /// In en, this message translates to:
  /// **'Words learned'**
  String get statWordsLearned;

  /// No description provided for @statTodaysDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s done'**
  String get statTodaysDone;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @streakValue.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String streakValue(int days);

  /// No description provided for @homeUpcomingReminder.
  ///
  /// In en, this message translates to:
  /// **'Upcoming reminder'**
  String get homeUpcomingReminder;

  /// No description provided for @homeNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left scheduled today.'**
  String get homeNothingLeft;

  /// No description provided for @homeTodaysSchedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get homeTodaysSchedule;

  /// No description provided for @homeNoRemindersToday.
  ///
  /// In en, this message translates to:
  /// **'No reminders today.'**
  String get homeNoRemindersToday;

  /// No description provided for @homeWordRightNow.
  ///
  /// In en, this message translates to:
  /// **'Word right now'**
  String get homeWordRightNow;

  /// No description provided for @homeNoVocabulary.
  ///
  /// In en, this message translates to:
  /// **'No vocabulary loaded yet.'**
  String get homeNoVocabulary;

  /// No description provided for @homeTodaysWords.
  ///
  /// In en, this message translates to:
  /// **'Today\'s words'**
  String get homeTodaysWords;

  /// No description provided for @homeSince.
  ///
  /// In en, this message translates to:
  /// **'since {time}'**
  String homeSince(String time);

  /// No description provided for @homeFromYesterday.
  ///
  /// In en, this message translates to:
  /// **'from yesterday'**
  String get homeFromYesterday;

  /// No description provided for @homeFromLastNight.
  ///
  /// In en, this message translates to:
  /// **'from last night · next at {time}'**
  String homeFromLastNight(String time);

  /// No description provided for @homeNoPeeking.
  ///
  /// In en, this message translates to:
  /// **'This word arrives at {time} — no peeking 🙂'**
  String homeNoPeeking(String time);

  /// No description provided for @homeSlotWord.
  ///
  /// In en, this message translates to:
  /// **'{time} word'**
  String homeSlotWord(String time);

  /// No description provided for @homeOpenWord.
  ///
  /// In en, this message translates to:
  /// **'Open {word}'**
  String homeOpenWord(String word);

  /// No description provided for @homeWordArriving.
  ///
  /// In en, this message translates to:
  /// **'Word arriving at {time}'**
  String homeWordArriving(String time);

  /// No description provided for @homeArrivesAt.
  ///
  /// In en, this message translates to:
  /// **'Arrives at {time}'**
  String homeArrivesAt(String time);

  /// No description provided for @homeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get homeNow;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// No description provided for @scheduleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Tap + to add one.'**
  String get scheduleEmpty;

  /// No description provided for @reminderEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get reminderEdit;

  /// No description provided for @reminderNew.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get reminderNew;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleLabel;

  /// No description provided for @reminderDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get reminderDescLabel;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get reminderTime;

  /// No description provided for @reminderRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get reminderRepeat;

  /// No description provided for @reminderDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reminderDate;

  /// No description provided for @reminderDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month:'**
  String get reminderDayOfMonth;

  /// No description provided for @reminderSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get reminderSave;

  /// No description provided for @reminderCreate.
  ///
  /// In en, this message translates to:
  /// **'Create reminder'**
  String get reminderCreate;

  /// No description provided for @reminderDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get reminderDelete;

  /// No description provided for @repeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get repeatOnce;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @vocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabTitle;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get tabYesterday;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @vocabNoToday.
  ///
  /// In en, this message translates to:
  /// **'No words assigned yet today.'**
  String get vocabNoToday;

  /// No description provided for @vocabNoYesterday.
  ///
  /// In en, this message translates to:
  /// **'No words shown yesterday.'**
  String get vocabNoYesterday;

  /// No description provided for @vocabNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet — tap the star on a word.'**
  String get vocabNoFavorites;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get historyCurrentStreak;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet — history fills in once reminders and words start being delivered.'**
  String get historyEmpty;

  /// No description provided for @historyVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get historyVocabulary;

  /// No description provided for @historyReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get historyReminder;

  /// No description provided for @historyWord.
  ///
  /// In en, this message translates to:
  /// **'word'**
  String get historyWord;

  /// No description provided for @dayToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayYesterday;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTelemetryTitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous usage data'**
  String get settingsTelemetryTitle;

  /// No description provided for @settingsTelemetrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Device model, OS version, language pair and app-open activity only — no account, no personal data.'**
  String get settingsTelemetrySubtitle;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary words and reminders are delivered via local notifications, scheduled entirely on this device.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsFixPermissions.
  ///
  /// In en, this message translates to:
  /// **'Fix notification permissions'**
  String get settingsFixPermissions;

  /// No description provided for @settingsPermissionsDone.
  ///
  /// In en, this message translates to:
  /// **'Permissions requested and notifications rescheduled.'**
  String get settingsPermissionsDone;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In en, this message translates to:
  /// **'OSG — focus & vocabulary — v{version}'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get settingsLanguages;

  /// No description provided for @settingsISpeak.
  ///
  /// In en, this message translates to:
  /// **'I speak'**
  String get settingsISpeak;

  /// No description provided for @settingsILearn.
  ///
  /// In en, this message translates to:
  /// **'I\'m learning'**
  String get settingsILearn;

  /// No description provided for @settingsPairChanged.
  ///
  /// In en, this message translates to:
  /// **'Languages updated.'**
  String get settingsPairChanged;

  /// No description provided for @settingsPairFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the words for this language. Check your connection and try again.'**
  String get settingsPairFailed;

  /// No description provided for @settingsNoOtherTargets.
  ///
  /// In en, this message translates to:
  /// **'No other languages are available for this right now.'**
  String get settingsNoOtherTargets;

  /// No description provided for @downloadingWords.
  ///
  /// In en, this message translates to:
  /// **'Downloading words…'**
  String get downloadingWords;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountIntro.
  ///
  /// In en, this message translates to:
  /// **'Optional. Keep your progress if you change phones — we only need your email.'**
  String get accountIntro;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// No description provided for @accountSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get accountSendCode;

  /// No description provided for @accountCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String accountCodeSent(String email);

  /// No description provided for @accountCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get accountCodeLabel;

  /// No description provided for @accountVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get accountVerify;

  /// No description provided for @accountOtherEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get accountOtherEmail;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String accountSignedInAs(String email);

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDelete;

  /// No description provided for @accountDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get accountDeleteConfirmTitle;

  /// No description provided for @accountDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account and the data linked to it on our server. Words and reminders on this phone stay.'**
  String get accountDeleteConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted.'**
  String get accountDeleted;

  /// No description provided for @accountSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out.'**
  String get accountSignedOut;

  /// No description provided for @accountInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get accountInvalidEmail;

  /// No description provided for @accountWrongCode.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t work. Check it and try again.'**
  String get accountWrongCode;

  /// No description provided for @accountTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a few minutes and try again.'**
  String get accountTooMany;

  /// No description provided for @accountCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Request a new one.'**
  String get accountCodeExpired;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please try again when you\'re online.'**
  String get networkError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a mistake'**
  String get reportTitle;

  /// No description provided for @reportKindTranslation.
  ///
  /// In en, this message translates to:
  /// **'Wrong translation'**
  String get reportKindTranslation;

  /// No description provided for @reportKindArticle.
  ///
  /// In en, this message translates to:
  /// **'Wrong article'**
  String get reportKindArticle;

  /// No description provided for @reportKindExample.
  ///
  /// In en, this message translates to:
  /// **'Wrong example'**
  String get reportKindExample;

  /// No description provided for @reportKindOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportKindOther;

  /// No description provided for @reportNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get reportNoteHint;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get reportSend;

  /// No description provided for @reportThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We\'ll check this word.'**
  String get reportThanks;

  /// No description provided for @reportOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — please try again later.'**
  String get reportOffline;

  /// No description provided for @reportTooMany.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent a lot of reports today. Please try again tomorrow.'**
  String get reportTooMany;

  /// No description provided for @notifTodaysGoal.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal:'**
  String get notifTodaysGoal;

  /// No description provided for @notifReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notifReminder;

  /// No description provided for @notifTodaysWord.
  ///
  /// In en, this message translates to:
  /// **'Today\'s word:'**
  String get notifTodaysWord;

  /// No description provided for @notifNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next words are waiting'**
  String get notifNudgeTitle;

  /// No description provided for @notifNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Open OSG to keep your daily words and reminders coming.'**
  String get notifNudgeBody;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Reminders & Vocabulary'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary words and task reminders'**
  String get notifChannelDescription;

  /// No description provided for @onbISpeak.
  ///
  /// In en, this message translates to:
  /// **'I speak'**
  String get onbISpeak;

  /// No description provided for @onbIWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'I want to learn'**
  String get onbIWantToLearn;

  /// No description provided for @onbHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Here\'s how it works'**
  String get onbHowItWorks;

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onbContinue;

  /// No description provided for @onbBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onbBack;

  /// No description provided for @onbStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onbStart;

  /// No description provided for @onbWordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String onbWordCount(int count);

  /// No description provided for @onbOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — more languages appear once you\'re connected.'**
  String get onbOfflineNote;

  /// No description provided for @onbOfflineOnlyBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Offline: for now only German with English translations. Your language\'s words download automatically once you\'re online.'**
  String get onbOfflineOnlyBuiltIn;

  /// No description provided for @onbPreviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Three words a day arrive as notifications — at 08:00, 12:00 and 18:00 — and on your home-screen widget.'**
  String get onbPreviewIntro;

  /// No description provided for @onbNotificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get onbNotificationLabel;

  /// No description provided for @onbWidgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Widget'**
  String get onbWidgetLabel;

  /// No description provided for @onbPermissionWhy.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so your words and reminders can reach you.'**
  String get onbPermissionWhy;

  /// No description provided for @onbAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get onbAllow;

  /// No description provided for @onbAllowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get onbAllowed;

  /// No description provided for @onbDownloaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word ready} other{{count} words ready}}'**
  String onbDownloaded(int count);

  /// No description provided for @onbDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download this language — starting with English translations for now. OSG will try again automatically.'**
  String get onbDownloadFailed;

  /// No description provided for @onbLoadingPairs.
  ///
  /// In en, this message translates to:
  /// **'Loading languages…'**
  String get onbLoadingPairs;

  /// No description provided for @showMeaning.
  ///
  /// In en, this message translates to:
  /// **'Show meaning'**
  String get showMeaning;

  /// No description provided for @catDailyLife.
  ///
  /// In en, this message translates to:
  /// **'Daily Life'**
  String get catDailyLife;

  /// No description provided for @catWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get catWork;

  /// No description provided for @catFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get catFood;

  /// No description provided for @catCommonVerbs.
  ///
  /// In en, this message translates to:
  /// **'Common Verbs'**
  String get catCommonVerbs;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catEmotions.
  ///
  /// In en, this message translates to:
  /// **'Emotions'**
  String get catEmotions;

  /// No description provided for @catAdjectives.
  ///
  /// In en, this message translates to:
  /// **'Adjectives'**
  String get catAdjectives;

  /// No description provided for @catTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get catTime;

  /// No description provided for @catMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get catMoney;

  /// No description provided for @catHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealth;

  /// No description provided for @catWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get catWeather;

  /// No description provided for @catSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get catSocial;

  /// No description provided for @catHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get catHome;

  /// No description provided for @catFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get catFamily;

  /// No description provided for @catEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducation;

  /// No description provided for @catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get catShopping;

  /// No description provided for @catNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get catNature;

  /// No description provided for @refreshUpdated.
  ///
  /// In en, this message translates to:
  /// **'Words updated'**
  String get refreshUpdated;

  /// No description provided for @refreshUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Words are up to date'**
  String get refreshUpToDate;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for new words. Check your connection.'**
  String get refreshFailed;

  /// No description provided for @levelA1.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelA1;

  /// No description provided for @levelA1Desc.
  ///
  /// In en, this message translates to:
  /// **'I know only a few words'**
  String get levelA1Desc;

  /// No description provided for @levelA2.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get levelA2;

  /// No description provided for @levelA2Desc.
  ///
  /// In en, this message translates to:
  /// **'I manage simple everyday situations'**
  String get levelA2Desc;

  /// No description provided for @levelB1.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelB1;

  /// No description provided for @levelB1Desc.
  ///
  /// In en, this message translates to:
  /// **'I can talk about familiar topics'**
  String get levelB1Desc;

  /// No description provided for @levelB2.
  ///
  /// In en, this message translates to:
  /// **'Upper intermediate'**
  String get levelB2;

  /// No description provided for @levelB2Desc.
  ///
  /// In en, this message translates to:
  /// **'I speak fairly fluently'**
  String get levelB2Desc;

  /// No description provided for @levelC1.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelC1;

  /// No description provided for @levelC1Desc.
  ///
  /// In en, this message translates to:
  /// **'I understand almost everything'**
  String get levelC1Desc;

  /// No description provided for @topicRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail & sales'**
  String get topicRetail;

  /// No description provided for @topicIt.
  ///
  /// In en, this message translates to:
  /// **'IT'**
  String get topicIt;

  /// No description provided for @topicMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get topicMedicine;

  /// No description provided for @topicHospitality.
  ///
  /// In en, this message translates to:
  /// **'Hotels & restaurants'**
  String get topicHospitality;

  /// No description provided for @topicConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get topicConstruction;

  /// No description provided for @topicLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics & driving'**
  String get topicLogistics;

  /// No description provided for @topicOffice.
  ///
  /// In en, this message translates to:
  /// **'Office & business'**
  String get topicOffice;

  /// No description provided for @topicCare.
  ///
  /// In en, this message translates to:
  /// **'Care work'**
  String get topicCare;

  /// No description provided for @settingsLearning.
  ///
  /// In en, this message translates to:
  /// **'LEARNING'**
  String get settingsLearning;

  /// No description provided for @settingsLevel.
  ///
  /// In en, this message translates to:
  /// **'My level'**
  String get settingsLevel;

  /// No description provided for @settingsTopics.
  ///
  /// In en, this message translates to:
  /// **'Work areas'**
  String get settingsTopics;

  /// No description provided for @settingsTopicsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsTopicsNone;

  /// No description provided for @settingsLearningChanged.
  ///
  /// In en, this message translates to:
  /// **'Saved. Today\'s words were updated.'**
  String get settingsLearningChanged;

  /// No description provided for @onbYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Your level'**
  String get onbYourLevel;

  /// No description provided for @onbYourLevelHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get words of this level and a little above.'**
  String get onbYourLevelHint;

  /// No description provided for @onbYourWork.
  ///
  /// In en, this message translates to:
  /// **'Your work'**
  String get onbYourWork;

  /// No description provided for @onbYourWorkHint.
  ///
  /// In en, this message translates to:
  /// **'Pick any that fit — we\'ll add words for your job. You can skip this.'**
  String get onbYourWorkHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @tourRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Pull down to update'**
  String get tourRefreshTitle;

  /// No description provided for @tourRefreshBody.
  ///
  /// In en, this message translates to:
  /// **'New and corrected words arrive right away when you pull down here.'**
  String get tourRefreshBody;

  /// No description provided for @tourWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Your word right now'**
  String get tourWordTitle;

  /// No description provided for @tourWordBody.
  ///
  /// In en, this message translates to:
  /// **'3 words a day as notifications: 08:00, 12:00 and 18:00. Tap ⚑ on a card to report a mistake.'**
  String get tourWordBody;

  /// No description provided for @tourVocabTitle.
  ///
  /// In en, this message translates to:
  /// **'All your words'**
  String get tourVocabTitle;

  /// No description provided for @tourVocabBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s and yesterday\'s words and your favourites.'**
  String get tourVocabBody;

  /// No description provided for @tourScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reminders'**
  String get tourScheduleTitle;

  /// No description provided for @tourScheduleBody.
  ///
  /// In en, this message translates to:
  /// **'Add your own reminders — they come together with your words.'**
  String get tourScheduleBody;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it yours'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Change your level, work areas and languages any time.'**
  String get tourSettingsBody;

  /// No description provided for @tourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// No description provided for @tourGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get tourGotIt;

  /// No description provided for @widgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add the OSG widget'**
  String get widgetTitle;

  /// No description provided for @widgetBody.
  ///
  /// In en, this message translates to:
  /// **'See your word on the Home Screen without opening the app.'**
  String get widgetBody;

  /// No description provided for @widgetAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get widgetAddButton;

  /// No description provided for @widgetLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get widgetLater;

  /// No description provided for @widgetIosStep1.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the Home Screen'**
  String get widgetIosStep1;

  /// No description provided for @widgetIosStep2.
  ///
  /// In en, this message translates to:
  /// **'Tap + in the top corner'**
  String get widgetIosStep2;

  /// No description provided for @widgetIosStep3.
  ///
  /// In en, this message translates to:
  /// **'Find OSG and tap Add Widget'**
  String get widgetIosStep3;

  /// No description provided for @widgetIosLock.
  ///
  /// In en, this message translates to:
  /// **'Lock Screen: touch and hold it, tap Customize, then add OSG.'**
  String get widgetIosLock;

  /// No description provided for @widgetAndroidManual.
  ///
  /// In en, this message translates to:
  /// **'Touch and hold an empty spot on the Home Screen, tap Widgets, then find OSG.'**
  String get widgetAndroidManual;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get settingsHelp;

  /// No description provided for @settingsShowGuide.
  ///
  /// In en, this message translates to:
  /// **'Show the app guide again'**
  String get settingsShowGuide;

  /// No description provided for @settingsAddWidget.
  ///
  /// In en, this message translates to:
  /// **'Add the widget'**
  String get settingsAddWidget;

  /// No description provided for @widgetAndroidMove.
  ///
  /// In en, this message translates to:
  /// **'Some phones (e.g. Xiaomi) put it on a later page. To place it exactly where you want: touch and hold an empty spot on your main screen → Widgets → OSG, and drag it there.'**
  String get widgetAndroidMove;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
