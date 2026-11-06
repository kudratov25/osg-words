// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'OSG — Har kuni so\'zlar';

  @override
  String get navHome => 'Asosiy';

  @override
  String get navSchedule => 'Jadval';

  @override
  String get navVocabulary => 'Lug\'at';

  @override
  String get navHistory => 'Tarix';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get homeToday => 'Bugun';

  @override
  String get statWordsLearned => 'O\'rganilgan so\'zlar';

  @override
  String get statTodaysDone => 'Bugun bajarildi';

  @override
  String get statStreak => 'Ketma-ketlik';

  @override
  String streakValue(int days) {
    return '$days kun';
  }

  @override
  String get homeUpcomingReminder => 'Keyingi eslatma';

  @override
  String get homeNothingLeft => 'Bugunga boshqa reja yo\'q.';

  @override
  String get homeTodaysSchedule => 'Bugungi jadval';

  @override
  String get homeNoRemindersToday => 'Bugun eslatmalar yo\'q.';

  @override
  String get homeWordRightNow => 'Hozirgi so\'z';

  @override
  String get homeNoVocabulary => 'Hali so\'zlar yuklanmagan.';

  @override
  String get homeTodaysWords => 'Bugungi so\'zlar';

  @override
  String homeSince(String time) {
    return '$time dan beri';
  }

  @override
  String get homeFromYesterday => 'kechagi';

  @override
  String homeFromLastNight(String time) {
    return 'kechagi · keyingisi $time da';
  }

  @override
  String homeNoPeeking(String time) {
    return 'Bu so\'z $time da keladi — oldindan qaramang 🙂';
  }

  @override
  String homeSlotWord(String time) {
    return '$time so\'zi';
  }

  @override
  String homeOpenWord(String word) {
    return '$word ni ochish';
  }

  @override
  String homeWordArriving(String time) {
    return 'So\'z $time da keladi';
  }

  @override
  String homeArrivesAt(String time) {
    return '$time da keladi';
  }

  @override
  String get homeNow => 'hozir';

  @override
  String get scheduleTitle => 'Jadval';

  @override
  String get scheduleEmpty =>
      'Hali eslatmalar yo\'q. Qo\'shish uchun + ni bosing.';

  @override
  String get reminderEdit => 'Eslatmani tahrirlash';

  @override
  String get reminderNew => 'Yangi eslatma';

  @override
  String get reminderTitleLabel => 'Nomi';

  @override
  String get reminderDescLabel => 'Tavsif (ixtiyoriy)';

  @override
  String get reminderTime => 'Vaqt';

  @override
  String get reminderRepeat => 'Takrorlash';

  @override
  String get reminderDate => 'Sana';

  @override
  String get reminderDayOfMonth => 'Oy kuni:';

  @override
  String get reminderSave => 'O\'zgarishlarni saqlash';

  @override
  String get reminderCreate => 'Eslatma yaratish';

  @override
  String get reminderDelete => 'O\'chirish';

  @override
  String get repeatOnce => 'Bir marta';

  @override
  String get repeatDaily => 'Har kuni';

  @override
  String get repeatWeekdays => 'Ish kunlari';

  @override
  String get repeatWeekly => 'Har hafta';

  @override
  String get repeatMonthly => 'Har oy';

  @override
  String get vocabTitle => 'Lug\'at';

  @override
  String get tabToday => 'Bugun';

  @override
  String get tabYesterday => 'Kecha';

  @override
  String get tabFavorites => 'Sevimlilar';

  @override
  String get vocabNoToday => 'Bugun hali so\'zlar belgilanmagan.';

  @override
  String get vocabNoYesterday => 'Kecha so\'zlar ko\'rsatilmagan.';

  @override
  String get vocabNoFavorites =>
      'Hali sevimlilar yo\'q — so\'zdagi yulduzchani bosing.';

  @override
  String get historyTitle => 'Tarix';

  @override
  String get historyCurrentStreak => 'Joriy ketma-ketlik';

  @override
  String get historyEmpty =>
      'Hali faollik yo\'q — eslatmalar va so\'zlar kela boshlagach, tarix to\'ladi.';

  @override
  String get historyVocabulary => 'Lug\'at';

  @override
  String get historyReminder => 'Eslatma';

  @override
  String get historyWord => 'so\'z';

  @override
  String get dayToday => 'Bugun';

  @override
  String get dayYesterday => 'Kecha';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsTelemetryTitle =>
      'Anonim foydalanish ma\'lumotlarini yuborish';

  @override
  String get settingsTelemetrySubtitle =>
      'Faqat qurilma modeli, OT versiyasi, til juftligi va ilova ochilishi — hisob yo\'q, shaxsiy ma\'lumot yo\'q.';

  @override
  String get settingsNotificationsTitle => 'Bildirishnomalar';

  @override
  String get settingsNotificationsSubtitle =>
      'So\'zlar va eslatmalar mahalliy bildirishnomalar orqali keladi, ular to\'liq shu qurilmada rejalashtiriladi.';

  @override
  String get settingsFixPermissions => 'Bildirishnoma ruxsatlarini tuzatish';

  @override
  String get settingsPermissionsDone =>
      'Ruxsatlar so\'raldi va bildirishnomalar qayta rejalashtirildi.';

  @override
  String get settingsAbout => 'Ilova haqida';

  @override
  String settingsAboutVersion(String version) {
    return 'OSG — diqqat va lug\'at — v$version';
  }

  @override
  String get settingsLanguages => 'Tillar';

  @override
  String get settingsISpeak => 'Men gapiraman';

  @override
  String get settingsILearn => 'Men o\'rganyapman';

  @override
  String get settingsPairChanged => 'Tillar yangilandi.';

  @override
  String get settingsPairFailed =>
      'Bu til uchun so\'zlarni yuklab bo\'lmadi. Internetni tekshirib, qayta urinib ko\'ring.';

  @override
  String get settingsNoOtherTargets => 'Hozircha boshqa tillar mavjud emas.';

  @override
  String get downloadingWords => 'So\'zlar yuklanmoqda…';

  @override
  String get accountTitle => 'Hisob';

  @override
  String get accountIntro =>
      'Ixtiyoriy. Telefon almashtirsangiz ham natijalaringiz saqlanadi — faqat emailingiz kerak.';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountSendCode => 'Kod yuborish';

  @override
  String accountCodeSent(String email) {
    return '$email manziliga 6 xonali kod yubordik.';
  }

  @override
  String get accountCodeLabel => '6 xonali kod';

  @override
  String get accountVerify => 'Tasdiqlash';

  @override
  String get accountOtherEmail => 'Boshqa email';

  @override
  String accountSignedInAs(String email) {
    return '$email sifatida kirdingiz';
  }

  @override
  String get accountSignOut => 'Chiqish';

  @override
  String get accountDelete => 'Hisobni o\'chirish';

  @override
  String get accountDeleteConfirmTitle => 'Hisob o\'chirilsinmi?';

  @override
  String get accountDeleteConfirmBody =>
      'Bu hisobingizni va serverdagi unga bog\'liq ma\'lumotlarni o\'chiradi. Telefondagi so\'zlar va eslatmalar qoladi.';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get delete => 'O\'chirish';

  @override
  String get accountDeleted => 'Hisob o\'chirildi.';

  @override
  String get accountSignedOut => 'Hisobdan chiqdingiz.';

  @override
  String get accountInvalidEmail => 'To\'g\'ri email manzilini kiriting.';

  @override
  String get accountWrongCode =>
      'Kod noto\'g\'ri. Tekshirib, qayta urinib ko\'ring.';

  @override
  String get accountTooMany =>
      'Juda ko\'p urinish. Bir necha daqiqadan so\'ng qayta urinib ko\'ring.';

  @override
  String get accountCodeExpired =>
      'Kodning muddati tugagan. Yangisini so\'rang.';

  @override
  String get networkError =>
      'Internet yo\'q. Ulanganingizda qayta urinib ko\'ring.';

  @override
  String get genericError => 'Nimadir xato ketdi. Qayta urinib ko\'ring.';

  @override
  String get reportTitle => 'Xato haqida xabar berish';

  @override
  String get reportKindTranslation => 'Tarjima noto\'g\'ri';

  @override
  String get reportKindArticle => 'Artikl noto\'g\'ri';

  @override
  String get reportKindExample => 'Misol noto\'g\'ri';

  @override
  String get reportKindOther => 'Boshqa narsa';

  @override
  String get reportNoteHint => 'Izoh qo\'shing (ixtiyoriy)';

  @override
  String get reportSend => 'Yuborish';

  @override
  String get reportThanks => 'Rahmat! Bu so\'zni tekshiramiz.';

  @override
  String get reportOffline =>
      'Internet yo\'q — keyinroq qayta urinib ko\'ring.';

  @override
  String get reportTooMany =>
      'Bugun ko\'p xabar yubordingiz. Ertaga qayta urinib ko\'ring.';

  @override
  String get notifTodaysGoal => 'Bugungi maqsad:';

  @override
  String get notifReminder => 'Eslatma';

  @override
  String get notifTodaysWord => 'Bugungi so\'z:';

  @override
  String get notifNudgeTitle => 'Keyingi so\'zlaringiz kutmoqda';

  @override
  String get notifNudgeBody =>
      'Kunlik so\'zlar va eslatmalar kelib turishi uchun OSG ni oching.';

  @override
  String get notifChannelName => 'Eslatmalar va so\'zlar';

  @override
  String get notifChannelDescription =>
      'Lug\'at so\'zlari va vazifa eslatmalari';

  @override
  String get onbISpeak => 'Men gapiraman';

  @override
  String get onbIWantToLearn => 'Men o\'rganmoqchiman';

  @override
  String get onbHowItWorks => 'Bu qanday ishlaydi';

  @override
  String get onbContinue => 'Davom etish';

  @override
  String get onbBack => 'Orqaga';

  @override
  String get onbStart => 'Boshlash';

  @override
  String onbWordCount(int count) {
    return '$count ta so\'z';
  }

  @override
  String get onbOfflineNote =>
      'Internet yo\'q — ulanganingizda ko\'proq tillar paydo bo\'ladi.';

  @override
  String get onbOfflineOnlyBuiltIn =>
      'Internet yo\'q: hozircha faqat inglizcha tarjimali nemis tili. Internet paydo bo\'lganda, sizning tilingizdagi so\'zlar avtomatik yuklanadi.';

  @override
  String get onbPreviewIntro =>
      'Kuniga uchta so\'z bildirishnoma sifatida keladi — 08:00, 12:00 va 18:00 da — va bosh ekrandagi vidjetda ko\'rinadi.';

  @override
  String get onbNotificationLabel => 'Bildirishnoma';

  @override
  String get onbWidgetLabel => 'Vidjet';

  @override
  String get onbPermissionWhy =>
      'So\'zlar va eslatmalar sizga yetib borishi uchun bildirishnomalarga ruxsat bering.';

  @override
  String get onbAllow => 'Bildirishnomalarga ruxsat berish';

  @override
  String get onbAllowed => 'Bildirishnomalarga ruxsat berildi';

  @override
  String onbDownloaded(int count) {
    return '$count ta so\'z tayyor';
  }

  @override
  String get onbDownloadFailed =>
      'Bu tilni yuklab bo\'lmadi — hozircha inglizcha tarjimalar bilan boshlaymiz. Ilova keyinroq avtomatik qayta urinadi.';

  @override
  String get onbLoadingPairs => 'Tillar yuklanmoqda…';

  @override
  String get showMeaning => 'Ma\'nosini ko\'rsatish';

  @override
  String get catDailyLife => 'Kundalik hayot';

  @override
  String get catWork => 'Ish';

  @override
  String get catFood => 'Ovqat';

  @override
  String get catCommonVerbs => 'Asosiy fe\'llar';

  @override
  String get catTravel => 'Sayohat';

  @override
  String get catEmotions => 'Hissiyotlar';

  @override
  String get catAdjectives => 'Sifatlar';

  @override
  String get catTime => 'Vaqt';

  @override
  String get catMoney => 'Pul';

  @override
  String get catHealth => 'Sog\'liq';

  @override
  String get catWeather => 'Ob-havo';

  @override
  String get catSocial => 'Muloqot';

  @override
  String get catHome => 'Uy';

  @override
  String get catFamily => 'Oila';

  @override
  String get catEducation => 'Ta\'lim';

  @override
  String get catShopping => 'Xarid';

  @override
  String get catNature => 'Tabiat';

  @override
  String get refreshUpdated => 'So\'zlar yangilandi';

  @override
  String get refreshUpToDate => 'So\'zlar eng so\'nggi holatda';

  @override
  String get refreshFailed =>
      'Yangi so\'zlarni tekshirib bo\'lmadi. Internetni tekshiring.';

  @override
  String get levelA1 => 'Boshlang\'ich';

  @override
  String get levelA1Desc => 'Faqat bir nechta so\'z bilaman';

  @override
  String get levelA2 => 'Elementar';

  @override
  String get levelA2Desc => 'Oddiy kundalik vaziyatlarda gaplasha olaman';

  @override
  String get levelB1 => 'O\'rta';

  @override
  String get levelB1Desc => 'Tanish mavzularda gaplasha olaman';

  @override
  String get levelB2 => 'O\'rtadan yuqori';

  @override
  String get levelB2Desc => 'Ancha erkin gapiraman';

  @override
  String get levelC1 => 'Yuqori';

  @override
  String get levelC1Desc => 'Deyarli hamma narsani tushunaman';

  @override
  String get topicRetail => 'Savdo va do\'kon';

  @override
  String get topicIt => 'IT';

  @override
  String get topicMedicine => 'Tibbiyot';

  @override
  String get topicHospitality => 'Mehmonxona va restoran';

  @override
  String get topicConstruction => 'Qurilish';

  @override
  String get topicLogistics => 'Logistika va haydovchilik';

  @override
  String get topicOffice => 'Ofis va biznes';

  @override
  String get topicCare => 'Parvarish ishi';

  @override
  String get settingsLearning => 'O\'RGANISH';

  @override
  String get settingsLevel => 'Mening darajam';

  @override
  String get settingsTopics => 'Ish sohalari';

  @override
  String get settingsTopicsNone => 'Tanlanmagan';

  @override
  String get settingsLearningChanged =>
      'Saqlandi. Bugungi so\'zlar yangilandi.';

  @override
  String get onbYourLevel => 'Darajangiz';

  @override
  String get onbYourLevelHint =>
      'Shu darajadagi va biroz yuqoriroq so\'zlarni olasiz.';

  @override
  String get onbYourWork => 'Ishingiz';

  @override
  String get onbYourWorkHint =>
      'Mosini tanlang — ishingizga oid so\'zlarni qo\'shamiz. O\'tkazib yuborishingiz mumkin.';

  @override
  String get done => 'Tayyor';

  @override
  String get skip => 'O\'tkazib yuborish';

  @override
  String get tourRefreshTitle => 'Yangilash uchun pastga torting';

  @override
  String get tourRefreshBody =>
      'Shu yerda pastga tortsangiz, yangi va tuzatilgan so\'zlar darhol keladi.';

  @override
  String get tourWordTitle => 'Hozirgi so\'zingiz';

  @override
  String get tourWordBody =>
      'Kuniga 3 ta so\'z bildirishnoma bo\'lib keladi: 08:00, 12:00 va 18:00. Xato topsangiz, kartadagi ⚑ ni bosing.';

  @override
  String get tourVocabTitle => 'Barcha so\'zlaringiz';

  @override
  String get tourVocabBody =>
      'Bugungi va kechagi so\'zlar hamda sevimlilaringiz.';

  @override
  String get tourScheduleTitle => 'Eslatmalaringiz';

  @override
  String get tourScheduleBody =>
      'O\'z eslatmalaringizni qo\'shing — ular so\'zlar bilan birga keladi.';

  @override
  String get tourSettingsTitle => 'O\'zingizga moslang';

  @override
  String get tourSettingsBody =>
      'Darajangiz, ish sohalaringiz va tillarni istalgan vaqtda o\'zgartiring.';

  @override
  String get tourNext => 'Keyingi';

  @override
  String get tourGotIt => 'Tushunarli';

  @override
  String get widgetTitle => 'OSG vidjetini qo\'shing';

  @override
  String get widgetBody => 'So\'zingizni ilovani ochmasdan ekranda ko\'ring.';

  @override
  String get widgetAddButton => 'Vidjet qo\'shish';

  @override
  String get widgetLater => 'Keyinroq';

  @override
  String get widgetIosStep1 => 'Ekrandagi bo\'sh joyni bosib turing';

  @override
  String get widgetIosStep2 => 'Yuqori burchakdagi + ni bosing';

  @override
  String get widgetIosStep3 => 'OSG ni toping va «Vidjet qo\'shish» ni bosing';

  @override
  String get widgetIosLock =>
      'Qulf ekrani: uni bosib turing, «Sozlash» ni bosing va OSG ni qo\'shing.';

  @override
  String get widgetAndroidManual =>
      'Ekrandagi bo\'sh joyni bosib turing, «Vidjetlar» ni bosing va OSG ni toping.';

  @override
  String get settingsHelp => 'YORDAM';

  @override
  String get settingsShowGuide => 'Ilova qo\'llanmasini qayta ko\'rsatish';

  @override
  String get settingsAddWidget => 'Vidjetni qo\'shish';

  @override
  String get widgetAndroidMove =>
      'Ba\'zi telefonlar (masalan, Xiaomi) uni keyingi sahifaga qo\'yadi. Aynan kerakli joyga qo\'yish uchun: asosiy ekrandagi bo\'sh joyni bosib turing → Vidjetlar → OSG va uni o\'sha joyga suring.';
}
