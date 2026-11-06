// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'OSG — Слова каждый день';

  @override
  String get navHome => 'Главная';

  @override
  String get navSchedule => 'Расписание';

  @override
  String get navVocabulary => 'Словарь';

  @override
  String get navHistory => 'История';

  @override
  String get navSettings => 'Настройки';

  @override
  String get homeToday => 'Сегодня';

  @override
  String get statWordsLearned => 'Выучено слов';

  @override
  String get statTodaysDone => 'Сделано сегодня';

  @override
  String get statStreak => 'Серия';

  @override
  String streakValue(int days) {
    return '$days дн.';
  }

  @override
  String get homeUpcomingReminder => 'Ближайшее напоминание';

  @override
  String get homeNothingLeft => 'На сегодня больше ничего не запланировано.';

  @override
  String get homeTodaysSchedule => 'Расписание на сегодня';

  @override
  String get homeNoRemindersToday => 'Сегодня напоминаний нет.';

  @override
  String get homeWordRightNow => 'Слово сейчас';

  @override
  String get homeNoVocabulary => 'Слова ещё не загружены.';

  @override
  String get homeTodaysWords => 'Слова на сегодня';

  @override
  String homeSince(String time) {
    return 'с $time';
  }

  @override
  String get homeFromYesterday => 'со вчера';

  @override
  String homeFromLastNight(String time) {
    return 'со вчера · следующее в $time';
  }

  @override
  String homeNoPeeking(String time) {
    return 'Это слово придёт в $time — не подглядывайте 🙂';
  }

  @override
  String homeSlotWord(String time) {
    return 'Слово в $time';
  }

  @override
  String homeOpenWord(String word) {
    return 'Открыть $word';
  }

  @override
  String homeWordArriving(String time) {
    return 'Слово придёт в $time';
  }

  @override
  String homeArrivesAt(String time) {
    return 'Придёт в $time';
  }

  @override
  String get homeNow => 'сейчас';

  @override
  String get scheduleTitle => 'Расписание';

  @override
  String get scheduleEmpty =>
      'Напоминаний пока нет. Нажмите +, чтобы добавить.';

  @override
  String get reminderEdit => 'Изменить напоминание';

  @override
  String get reminderNew => 'Новое напоминание';

  @override
  String get reminderTitleLabel => 'Название';

  @override
  String get reminderDescLabel => 'Описание (необязательно)';

  @override
  String get reminderTime => 'Время';

  @override
  String get reminderRepeat => 'Повтор';

  @override
  String get reminderDate => 'Дата';

  @override
  String get reminderDayOfMonth => 'День месяца:';

  @override
  String get reminderSave => 'Сохранить изменения';

  @override
  String get reminderCreate => 'Создать напоминание';

  @override
  String get reminderDelete => 'Удалить';

  @override
  String get repeatOnce => 'Один раз';

  @override
  String get repeatDaily => 'Ежедневно';

  @override
  String get repeatWeekdays => 'По будням';

  @override
  String get repeatWeekly => 'Еженедельно';

  @override
  String get repeatMonthly => 'Ежемесячно';

  @override
  String get vocabTitle => 'Словарь';

  @override
  String get tabToday => 'Сегодня';

  @override
  String get tabYesterday => 'Вчера';

  @override
  String get tabFavorites => 'Избранное';

  @override
  String get vocabNoToday => 'На сегодня слов пока нет.';

  @override
  String get vocabNoYesterday => 'Вчера слов не было.';

  @override
  String get vocabNoFavorites =>
      'В избранном пока пусто — нажмите звёздочку у слова.';

  @override
  String get historyTitle => 'История';

  @override
  String get historyCurrentStreak => 'Текущая серия';

  @override
  String get historyEmpty =>
      'Пока нет активности — история появится, когда начнут приходить напоминания и слова.';

  @override
  String get historyVocabulary => 'Словарь';

  @override
  String get historyReminder => 'Напоминание';

  @override
  String get historyWord => 'слово';

  @override
  String get dayToday => 'Сегодня';

  @override
  String get dayYesterday => 'Вчера';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsTelemetryTitle => 'Отправлять анонимную статистику';

  @override
  String get settingsTelemetrySubtitle =>
      'Только модель устройства, версия ОС, языковая пара и открытия приложения — без аккаунта и личных данных.';

  @override
  String get settingsNotificationsTitle => 'Уведомления';

  @override
  String get settingsNotificationsSubtitle =>
      'Слова и напоминания приходят локальными уведомлениями, которые планируются прямо на этом устройстве.';

  @override
  String get settingsFixPermissions => 'Исправить разрешения уведомлений';

  @override
  String get settingsPermissionsDone =>
      'Разрешения запрошены, уведомления перепланированы.';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String settingsAboutVersion(String version) {
    return 'OSG — фокус и слова — v$version';
  }

  @override
  String get settingsLanguages => 'Языки';

  @override
  String get settingsISpeak => 'Я говорю';

  @override
  String get settingsILearn => 'Я учу';

  @override
  String get settingsPairChanged => 'Языки обновлены.';

  @override
  String get settingsPairFailed =>
      'Не удалось загрузить слова для этого языка. Проверьте подключение и попробуйте снова.';

  @override
  String get settingsNoOtherTargets => 'Сейчас другие языки недоступны.';

  @override
  String get downloadingWords => 'Загружаем слова…';

  @override
  String get accountTitle => 'Аккаунт';

  @override
  String get accountIntro =>
      'Необязательно. Сохраните прогресс при смене телефона — нужен только email.';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountSendCode => 'Отправить код';

  @override
  String accountCodeSent(String email) {
    return 'Мы отправили 6-значный код на $email.';
  }

  @override
  String get accountCodeLabel => '6-значный код';

  @override
  String get accountVerify => 'Подтвердить';

  @override
  String get accountOtherEmail => 'Другой email';

  @override
  String accountSignedInAs(String email) {
    return 'Вы вошли как $email';
  }

  @override
  String get accountSignOut => 'Выйти';

  @override
  String get accountDelete => 'Удалить аккаунт';

  @override
  String get accountDeleteConfirmTitle => 'Удалить аккаунт?';

  @override
  String get accountDeleteConfirmBody =>
      'Аккаунт и связанные с ним данные на сервере будут удалены. Слова и напоминания на телефоне останутся.';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get accountDeleted => 'Аккаунт удалён.';

  @override
  String get accountSignedOut => 'Вы вышли из аккаунта.';

  @override
  String get accountInvalidEmail => 'Введите корректный email.';

  @override
  String get accountWrongCode =>
      'Код не подошёл. Проверьте и попробуйте снова.';

  @override
  String get accountTooMany =>
      'Слишком много попыток. Подождите несколько минут.';

  @override
  String get accountCodeExpired => 'Срок действия кода истёк. Запросите новый.';

  @override
  String get networkError =>
      'Нет подключения. Попробуйте снова, когда будете онлайн.';

  @override
  String get genericError => 'Что-то пошло не так. Попробуйте снова.';

  @override
  String get reportTitle => 'Сообщить об ошибке';

  @override
  String get reportKindTranslation => 'Неверный перевод';

  @override
  String get reportKindArticle => 'Неверный артикль';

  @override
  String get reportKindExample => 'Неверный пример';

  @override
  String get reportKindOther => 'Другое';

  @override
  String get reportNoteHint => 'Комментарий (необязательно)';

  @override
  String get reportSend => 'Отправить';

  @override
  String get reportThanks => 'Спасибо! Мы проверим это слово.';

  @override
  String get reportOffline => 'Нет подключения — попробуйте позже.';

  @override
  String get reportTooMany =>
      'Сегодня вы отправили много сообщений. Попробуйте завтра.';

  @override
  String get notifTodaysGoal => 'Цель на сегодня:';

  @override
  String get notifReminder => 'Напоминание';

  @override
  String get notifTodaysWord => 'Слово дня:';

  @override
  String get notifNudgeTitle => 'Новые слова уже ждут';

  @override
  String get notifNudgeBody =>
      'Откройте OSG, чтобы слова и напоминания продолжали приходить.';

  @override
  String get notifChannelName => 'Напоминания и слова';

  @override
  String get notifChannelDescription => 'Слова и напоминания о задачах';

  @override
  String get onbISpeak => 'Я говорю';

  @override
  String get onbIWantToLearn => 'Я хочу учить';

  @override
  String get onbHowItWorks => 'Как это работает';

  @override
  String get onbContinue => 'Продолжить';

  @override
  String get onbBack => 'Назад';

  @override
  String get onbStart => 'Начать';

  @override
  String onbWordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String get onbOfflineNote =>
      'Нет подключения — другие языки появятся, когда вы будете онлайн.';

  @override
  String get onbOfflineOnlyBuiltIn =>
      'Нет подключения: пока доступен только немецкий с английскими переводами. Когда появится интернет, слова на вашем языке загрузятся автоматически.';

  @override
  String get onbPreviewIntro =>
      'Три слова в день приходят уведомлениями — в 08:00, 12:00 и 18:00 — и появляются в виджете на экране.';

  @override
  String get onbNotificationLabel => 'Уведомление';

  @override
  String get onbWidgetLabel => 'Виджет';

  @override
  String get onbPermissionWhy =>
      'Разрешите уведомления, чтобы слова и напоминания доходили до вас.';

  @override
  String get onbAllow => 'Разрешить уведомления';

  @override
  String get onbAllowed => 'Уведомления разрешены';

  @override
  String onbDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова готовы',
      many: '$count слов готово',
      few: '$count слова готовы',
      one: '$count слово готово',
    );
    return '$_temp0';
  }

  @override
  String get onbDownloadFailed =>
      'Не удалось загрузить этот язык — пока начнём с английских переводов. Приложение само попробует ещё раз позже.';

  @override
  String get onbLoadingPairs => 'Загружаем языки…';

  @override
  String get showMeaning => 'Показать значение';

  @override
  String get catDailyLife => 'Повседневная жизнь';

  @override
  String get catWork => 'Работа';

  @override
  String get catFood => 'Еда';

  @override
  String get catCommonVerbs => 'Основные глаголы';

  @override
  String get catTravel => 'Путешествия';

  @override
  String get catEmotions => 'Эмоции';

  @override
  String get catAdjectives => 'Прилагательные';

  @override
  String get catTime => 'Время';

  @override
  String get catMoney => 'Деньги';

  @override
  String get catHealth => 'Здоровье';

  @override
  String get catWeather => 'Погода';

  @override
  String get catSocial => 'Общение';

  @override
  String get catHome => 'Дом';

  @override
  String get catFamily => 'Семья';

  @override
  String get catEducation => 'Образование';

  @override
  String get catShopping => 'Покупки';

  @override
  String get catNature => 'Природа';

  @override
  String get refreshUpdated => 'Слова обновлены';

  @override
  String get refreshUpToDate => 'Слова актуальны';

  @override
  String get refreshFailed =>
      'Не удалось проверить новые слова. Проверьте подключение.';

  @override
  String get levelA1 => 'Начальный';

  @override
  String get levelA1Desc => 'Знаю всего несколько слов';

  @override
  String get levelA2 => 'Элементарный';

  @override
  String get levelA2Desc => 'Справляюсь в простых бытовых ситуациях';

  @override
  String get levelB1 => 'Средний';

  @override
  String get levelB1Desc => 'Могу говорить на знакомые темы';

  @override
  String get levelB2 => 'Выше среднего';

  @override
  String get levelB2Desc => 'Говорю довольно свободно';

  @override
  String get levelC1 => 'Продвинутый';

  @override
  String get levelC1Desc => 'Понимаю почти всё';

  @override
  String get topicRetail => 'Торговля и продажи';

  @override
  String get topicIt => 'IT';

  @override
  String get topicMedicine => 'Медицина';

  @override
  String get topicHospitality => 'Отели и рестораны';

  @override
  String get topicConstruction => 'Строительство';

  @override
  String get topicLogistics => 'Логистика и вождение';

  @override
  String get topicOffice => 'Офис и бизнес';

  @override
  String get topicCare => 'Уход за людьми';

  @override
  String get settingsLearning => 'ОБУЧЕНИЕ';

  @override
  String get settingsLevel => 'Мой уровень';

  @override
  String get settingsTopics => 'Сферы работы';

  @override
  String get settingsTopicsNone => 'Не выбрано';

  @override
  String get settingsLearningChanged =>
      'Сохранено. Слова на сегодня обновлены.';

  @override
  String get onbYourLevel => 'Ваш уровень';

  @override
  String get onbYourLevelHint =>
      'Вы будете получать слова этого уровня и чуть выше.';

  @override
  String get onbYourWork => 'Ваша работа';

  @override
  String get onbYourWorkHint =>
      'Выберите подходящее — добавим слова для вашей работы. Можно пропустить.';

  @override
  String get done => 'Готово';

  @override
  String get skip => 'Пропустить';

  @override
  String get tourRefreshTitle => 'Потяните вниз, чтобы обновить';

  @override
  String get tourRefreshBody =>
      'Потяните здесь вниз — новые и исправленные слова придут сразу.';

  @override
  String get tourWordTitle => 'Ваше слово сейчас';

  @override
  String get tourWordBody =>
      '3 слова в день в уведомлениях: 08:00, 12:00 и 18:00. Нашли ошибку — нажмите ⚑ на карточке.';

  @override
  String get tourVocabTitle => 'Все ваши слова';

  @override
  String get tourVocabBody => 'Слова за сегодня и вчера и ваше избранное.';

  @override
  String get tourScheduleTitle => 'Ваши напоминания';

  @override
  String get tourScheduleBody =>
      'Добавьте свои напоминания — они приходят вместе со словами.';

  @override
  String get tourSettingsTitle => 'Настройте под себя';

  @override
  String get tourSettingsBody =>
      'Меняйте уровень, сферы работы и языки в любое время.';

  @override
  String get tourNext => 'Далее';

  @override
  String get tourGotIt => 'Понятно';

  @override
  String get widgetTitle => 'Добавьте виджет OSG';

  @override
  String get widgetBody =>
      'Видьте своё слово на экране, не открывая приложение.';

  @override
  String get widgetAddButton => 'Добавить виджет';

  @override
  String get widgetLater => 'Позже';

  @override
  String get widgetIosStep1 =>
      'Нажмите и удерживайте пустое место на экране «Домой»';

  @override
  String get widgetIosStep2 => 'Нажмите + в верхнем углу';

  @override
  String get widgetIosStep3 => 'Найдите OSG и нажмите «Добавить виджет»';

  @override
  String get widgetIosLock =>
      'Экран блокировки: нажмите и удерживайте его, выберите «Настроить» и добавьте OSG.';

  @override
  String get widgetAndroidManual =>
      'Нажмите и удерживайте пустое место на экране, выберите «Виджеты» и найдите OSG.';

  @override
  String get settingsHelp => 'ПОМОЩЬ';

  @override
  String get settingsShowGuide => 'Показать руководство ещё раз';

  @override
  String get settingsAddWidget => 'Добавить виджет';

  @override
  String get widgetAndroidMove =>
      'Некоторые телефоны (например, Xiaomi) ставят его на дальнюю страницу. Чтобы поставить точно куда нужно: нажмите и удерживайте пустое место на главном экране → Виджеты → OSG и перетащите его туда.';
}
