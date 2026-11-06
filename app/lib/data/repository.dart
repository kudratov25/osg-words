import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'db/app_database.dart';
import 'db/tables.dart';
import 'languages.dart';
import 'levels.dart';

/// Number of vocabulary notifications/words shown per day.
const int wordsPerDay = 3;

/// A word isn't re-shown until at least this many days after it was last
/// shown, once the word bank has been fully cycled through once.
const int reviewCooldownDays = 7;

class Repository {
  Repository(this._db);

  final AppDatabase _db;
  AppDatabase get db => _db;

  // ---------------------------------------------------------------------
  // Language pair
  // ---------------------------------------------------------------------

  /// The pair currently being learned. Set at startup and on every pair
  /// change by [LanguageSettings]; the planner only uses words of
  /// [LanguagePair.target], notifications use the source's strings.
  LanguagePair pair = builtInPair;

  /// Interface language (notification texts). Normally [pair]'s source; see
  /// [LanguageSettings.uiLanguage].
  String uiLanguage = builtInPair.source;

  /// The user's CEFR level (see [LearningPrefs]): new words of this level
  /// and above are planned - two at the level and one a level higher a day.
  String level = defaultLevel;

  /// Job areas the user picked. Topic words of other areas are never
  /// planned; with any picked, one word a day prefers a topic word.
  Set<String> topics = const {};

  /// Words the planner may use for the current target, level and topics.
  bool _eligible(Word w) {
    final t = parseTopics(w.topics);
    return t.isEmpty || t.any(topics.contains);
  }

  /// True for installs from before language pairs existed (or any install
  /// that already learned/planned a word): they skip onboarding.
  Future<bool> hasLearningActivity() async {
    final learned = await (_db.select(_db.learnedWords)..limit(1)).get();
    if (learned.isNotEmpty) return true;
    final plans = await (_db.select(_db.wordPlans)..limit(1)).get();
    return plans.isNotEmpty;
  }

  Future<int> wordCount(String target) async {
    final count = _db.words.id.count();
    final row = await (_db.selectOnly(_db.words)
          ..addColumns([count])
          ..where(_db.words.lang.equals(target)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// The first word of [target] (what the onboarding preview shows).
  Future<Word?> firstWordOf(String target) => (_db.select(_db.words)
        ..where((t) => t.lang.equals(target))
        ..orderBy([(t) => OrderingTerm.asc(t.id)])
        ..limit(1))
      .getSingleOrNull();

  /// Target switched: plans not yet counted (today's later slots and the
  /// rest of the week) are dropped so the planner refills them with words
  /// of the new target. Learned words, favourites and history are kept.
  Future<void> dropUnrecordedPlansFrom(DateTime day) => (_db.delete(_db.wordPlans)
        ..where((t) => t.recorded.equals(false) & t.day.isBiggerOrEqualValue(_dateOnly(day))))
      .go();

  // ---------------------------------------------------------------------
  // Word bank seeding
  // ---------------------------------------------------------------------

  static const seedAsset = 'assets/words_seed.json';

  Future<List<Map<String, dynamic>>> _loadSeed() async {
    // Bytes + utf8 here rather than loadString: for assets over 50 KB that
    // decodes in a background isolate (and caches the result), neither of
    // which is needed for a one-off read of ~250 KB.
    final bytes = await rootBundle.load(seedAsset);
    final text = utf8.decode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return (decoded['words'] as List).cast<Map<String, dynamic>>();
  }

  /// Loads the bundled en-de word list on first launch so the app has
  /// content before it ever talks to the backend. Safe to call every
  /// launch: once words exist it only adds bundled words that are missing
  /// (a newer app version ships more), and only while the translations on
  /// the phone are English - otherwise English rows would be mixed into
  /// another language's word bank.
  Future<void> seedWordsIfEmpty() async {
    final existing = await (_db.select(_db.words)..limit(1)).get();
    if (existing.isEmpty) {
      await mergeContentPack(await _loadSeed(), defaultLang: builtInPair.target);
      return;
    }
    if (pair.source == builtInPair.source) {
      await mergeContentPack(await _loadSeed(), defaultLang: builtInPair.target, updateExisting: false);
    }
  }

  /// Puts the bundled English translations back (switching back to
  /// English while offline). Progress is kept: rows are updated in place.
  Future<void> restoreBuiltInTranslations() async =>
      mergeContentPack(await _loadSeed(), defaultLang: builtInPair.target);

  /// Merges a content pack (downloaded, or the bundled seed) into the local
  /// word bank, matched by externalId. New words are inserted; words that
  /// already exist get their text fields updated (e.g. a fixed translation,
  /// or the translation in a new source language) but keep their local id,
  /// so learning progress and favorites are kept. Words missing from the
  /// pack are NOT deleted locally, for the same reason. Returns the number
  /// of newly added words.
  ///
  /// Accepts the v2 word shape (`term`, `lang`, `example_translation`) and
  /// the v1 one (`german`); [defaultLang] is used when `lang` is absent.
  Future<int> mergeContentPack(
    List<Map<String, dynamic>> words, {
    String defaultLang = 'de',
    bool updateExisting = true,
  }) async {
    final existing = {
      for (final w in await _db.select(_db.words).get()) w.externalId: w,
    };
    var added = 0;

    await _db.batch((batch) {
      for (final map in words) {
        final externalId = map['external_id'] as String;
        final fields = WordsCompanion(
          lang: Value(map['lang'] as String? ?? defaultLang),
          term: Value((map['term'] ?? map['german']) as String),
          article: Value(map['article'] as String?),
          translation: Value(map['translation'] as String),
          example: Value(map['example'] as String),
          exampleTranslation: Value(map['example_translation'] as String?),
          pronunciation: Value(map['pronunciation'] as String?),
          category: Value(map['category'] as String),
          difficulty: Value(map['difficulty'] as String? ?? 'beginner'),
          level: Value(map['level'] as String?),
          topics: Value(encodeTopics(((map['topics'] as List?) ?? const []).cast<String>())),
        );
        final current = existing[externalId];
        if (current == null) {
          batch.insert(_db.words, fields.copyWith(externalId: Value(externalId)));
          added++;
        } else if (updateExisting) {
          batch.update(_db.words, fields, where: (t) => t.id.equals(current.id));
        }
      }
    });
    return added;
  }

  // ---------------------------------------------------------------------
  // Vocabulary selection
  // ---------------------------------------------------------------------

  /// Today's words (planning today if needed and counting them as shown).
  Future<List<Word>> assignTodaysWords({DateTime? today}) async {
    final day = _dateOnly(today ?? DateTime.now());
    final plan = await planWords(from: day, days: 1);
    return plan[day] ?? const [];
  }

  /// Makes sure each of the [days] days starting at [from] has its
  /// [wordsPerDay] words planned, and returns day -> words in slot order.
  ///
  /// Existing plans are never changed (so a notification scheduled days
  /// ago and the widget always agree with the app); only missing slots
  /// are filled. Days up to and including [from] are counted into
  /// [LearnedWords] - later days are not, until they arrive.
  ///
  /// Selection for each new slot: never-shown-or-planned words first
  /// (oldest inserted first), then words not used for [reviewCooldownDays]
  /// (least recently used first), then the least recently used overall -
  /// never the same word twice in one day.
  /// Level or work areas changed: today's words are replaced right away
  /// (their "learned" counts undone), and the rest of the week replanned.
  Future<void> replanToday(DateTime now) async {
    final today = _dateOnly(now);
    await _db.transaction(() async {
      final plans = await (_db.select(_db.wordPlans)..where((t) => t.day.isBiggerOrEqualValue(today))).get();
      for (final p in plans) {
        if (p.recorded && _dateOnly(p.day) == today) await _unrecord(p.wordId, today);
      }
      await (_db.delete(_db.wordPlans)..where((t) => t.day.isBiggerOrEqualValue(today))).go();
    });
    await planWords(from: today, days: 1, keepLegacyToday: false);
  }

  Future<Map<DateTime, List<Word>>> planWords({
    required DateTime from,
    int days = 7,
    bool keepLegacyToday = true,
  }) async {
    final start = _dateOnly(from);
    final end = start.add(Duration(days: days));

    return _db.transaction(() async {
      final targetWords = await (_db.select(_db.words)
            ..where((t) => t.lang.equals(pair.target))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();
      // Existing plans may hold words that are no longer eligible (topics
      // changed): they stay valid, only new slots use the filter.
      final byId = {for (final w in targetWords) w.id: w};
      final allWords = targetWords.where(_eligible).toList();

      // Last date each word was shown or is planned for.
      final lastUsed = <int, DateTime>{};
      void use(int wordId, DateTime day) {
        final prev = lastUsed[wordId];
        if (prev == null || day.isAfter(prev)) lastUsed[wordId] = day;
      }

      for (final l in await _db.select(_db.learnedWords).get()) {
        use(l.wordId, _dateOnly(l.lastShownDate));
      }
      final existingPlans = await _db.select(_db.wordPlans).get();
      for (final p in existingPlans) {
        use(p.wordId, _dateOnly(p.day));
      }

      final planByDay = <DateTime, Map<int, int>>{}; // day -> slot -> wordId
      final recordedSlots = <DateTime, Set<int>>{}; // day -> slots already counted
      for (final p in existingPlans) {
        planByDay.putIfAbsent(_dateOnly(p.day), () => {})[p.slot] = p.wordId;
        if (p.recorded) recordedSlots.putIfAbsent(_dateOnly(p.day), () => {}).add(p.slot);
      }

      // Upgrade path: today was assigned by the pre-planning version of
      // the app (LearnedWords.lastShownDate == today, no plan yet) - keep
      // those exact words rather than switching them mid-day.
      if (keepLegacyToday && !planByDay.containsKey(start) && allWords.isNotEmpty) {
        final legacyToday = await (_db.select(_db.learnedWords)
              ..where((t) => t.lastShownDate.equals(start))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
        var slot = 0;
        for (final l in legacyToday.take(wordsPerDay)) {
          await _db.into(_db.wordPlans).insert(WordPlansCompanion.insert(
                day: start, slot: slot, wordId: l.wordId, recorded: const Value(true)));
          planByDay.putIfAbsent(start, () => {})[slot] = l.wordId;
          slot++;
        }
      }

      final result = <DateTime, List<Word>>{};
      if (allWords.isEmpty) return result;
      final userRank = levelRank(level);
      final perDay = wordsPerDay < allWords.length ? wordsPerDay : allWords.length;

      for (var day = start; day.isBefore(end); day = DateTime(day.year, day.month, day.day + 1)) {
        final slots = planByDay.putIfAbsent(day, () => {});
        // Slots holding a word of another target (the user switched the
        // language mid-day) get refilled below. If such a slot was already
        // counted, undo that count first - otherwise every switch would add
        // another day's worth of "learned" words.
        final stale = {
          for (final e in slots.entries)
            if (!byId.containsKey(e.value)) e.key: e.value,
        };
        for (final e in stale.entries) {
          if (recordedSlots[day]?.contains(e.key) ?? false) await _unrecord(e.value, day);
          slots.remove(e.key);
        }

        for (var slot = 0; slot < perDay; slot++) {
          if (slots.containsKey(slot)) continue;
          final pick = _pickWord(allWords, lastUsed,
              exclude: slots.values.toSet(), day: day, slot: slot, userRank: userRank);
          if (pick == null) break;
          await _db.into(_db.wordPlans).insert(
                WordPlansCompanion.insert(day: day, slot: slot, wordId: pick.id),
                mode: InsertMode.insertOrReplace,
              );
          slots[slot] = pick.id;
          use(pick.id, day);
        }

        final ordered = slots.keys.toList()..sort();
        result[day] = [for (final s in ordered) byId[slots[s]!]!];
      }

      await _recordArrivedDays(upTo: start);
      // Old plans aren't needed for anything once recorded.
      await (_db.delete(_db.wordPlans)
            ..where((t) =>
                t.recorded.equals(true) &
                t.day.isSmallerThanValue(start.subtract(const Duration(days: 60)))))
          .go();
      return result;
    });
  }

  /// Picks the word for one slot.
  ///
  /// New (never shown or planned) words first, by fit:
  ///  - slot 2 wants one level above the user's, the others the user's level;
  ///    words above the wanted level come next (closest first), words below
  ///    the user's level only when nothing at/above is left;
  ///  - with topics picked, slot 1 prefers a topic word (closest level >=
  ///    the user's), the other slots prefer general words.
  /// Ties: oldest inserted first. When every word was used: review, least
  /// recently used first, preferring words at/above the user's level.
  Word? _pickWord(List<Word> allWords, Map<int, DateTime> lastUsed,
      {required Set<int> exclude, required DateTime day, int slot = 0, int userRank = 0}) {
    final candidates = allWords.where((w) => !exclude.contains(w.id)).toList();
    if (candidates.isEmpty) return null;

    final wantRank = slot == 2 ? userRank + 1 : userRank;
    final wantTopic = topics.isNotEmpty && slot == 1;
    int levelPenalty(Word w) {
      final r = levelRank(w.level, w.difficulty);
      if (r < userRank) return 100 + (userRank - r);
      return (r - wantRank).abs() + (r < wantRank ? 1 : 0);
    }

    int topicPenalty(Word w) => parseTopics(w.topics).isNotEmpty == wantTopic ? 0 : 1;
    Word? best;
    (int, int)? bestKey;
    for (final w in candidates) {
      if (lastUsed.containsKey(w.id)) continue;
      final lp = levelPenalty(w);
      final tp = topicPenalty(w);
      // Topic slot: topic first (but never below level); otherwise level first.
      final key = wantTopic && lp < 100 ? (tp, lp) : (lp, tp);
      if (bestKey == null || key.$1 < bestKey.$1 || (key.$1 == bestKey.$1 && key.$2 < bestKey.$2)) {
        best = w;
        bestKey = key; // candidates are id-ordered: first wins ties
      }
    }
    if (best != null) return best;

    final cutoff = day.subtract(const Duration(days: reviewCooldownDays));
    final atLevel = candidates.where((w) => levelRank(w.level, w.difficulty) >= userRank).toList();
    final pool = atLevel.isNotEmpty ? atLevel : candidates;
    final used = pool.where((w) => lastUsed[w.id]!.isBefore(day)).toList()
      ..sort((a, b) => lastUsed[a.id]!.compareTo(lastUsed[b.id]!));
    for (final w in used) {
      if (lastUsed[w.id]!.isBefore(cutoff)) return w;
    }
    if (used.isNotEmpty) return used.first;

    candidates.sort((a, b) => lastUsed[a.id]!.compareTo(lastUsed[b.id]!));
    return candidates.first;
  }

  /// Reverses what [_recordArrivedDays] did for [wordId] on [day].
  Future<void> _unrecord(int wordId, DateTime day) async {
    final learned =
        await (_db.select(_db.learnedWords)..where((t) => t.wordId.equals(wordId))).getSingleOrNull();
    if (learned == null || _dateOnly(learned.lastShownDate) != day) return;
    if (_dateOnly(learned.firstSeenDate) == day) {
      await (_db.delete(_db.learnedWords)..where((t) => t.id.equals(learned.id))).go();
    } else if (learned.timesShown > 1) {
      await (_db.update(_db.learnedWords)..where((t) => t.id.equals(learned.id)))
          .write(LearnedWordsCompanion(timesShown: Value(learned.timesShown - 1)));
    }
  }

  /// Counts planned days up to [upTo] that haven't been counted yet into
  /// [LearnedWords] (first seen / last shown / times shown).
  Future<void> _recordArrivedDays({required DateTime upTo}) async {
    final pending = await (_db.select(_db.wordPlans)
          ..where((t) => t.recorded.equals(false) & t.day.isSmallerOrEqualValue(upTo))
          ..orderBy([(t) => OrderingTerm.asc(t.day), (t) => OrderingTerm.asc(t.slot)]))
        .get();
    for (final p in pending) {
      final day = _dateOnly(p.day);
      final learned = await (_db.select(_db.learnedWords)..where((t) => t.wordId.equals(p.wordId)))
          .getSingleOrNull();
      if (learned == null) {
        await _db.into(_db.learnedWords).insert(LearnedWordsCompanion.insert(
              wordId: p.wordId,
              firstSeenDate: Value(day),
              lastShownDate: Value(day),
            ));
      } else if (_dateOnly(learned.lastShownDate).isBefore(day)) {
        await (_db.update(_db.learnedWords)..where((t) => t.id.equals(learned.id))).write(
              LearnedWordsCompanion(
                lastShownDate: Value(day),
                timesShown: Value(learned.timesShown + 1),
              ),
            );
      }
      await (_db.update(_db.wordPlans)..where((t) => t.id.equals(p.id)))
          .write(const WordPlansCompanion(recorded: Value(true)));
    }
  }

  Future<List<Word>> _wordsForLearned(List<LearnedWord> learned) async {
    final ids = learned.map((l) => l.wordId).toList();
    final words = await (_db.select(_db.words)..where((t) => t.id.isIn(ids) & t.lang.equals(pair.target))).get();
    final byId = {for (final w in words) w.id: w};
    return ids.map((id) => byId[id]).whereType<Word>().toList();
  }

  Future<List<Word>> yesterdaysWords({DateTime? today}) async {
    final t = _dateOnly(today ?? DateTime.now());
    final yesterday = DateTime(t.year, t.month, t.day - 1);
    final plans = await (_db.select(_db.wordPlans)
          ..where((t) => t.day.equals(yesterday))
          ..orderBy([(t) => OrderingTerm.asc(t.slot)]))
        .get();
    if (plans.isNotEmpty) {
      final words = await (_db.select(_db.words)
            ..where((t) => t.id.isIn(plans.map((p) => p.wordId)) & t.lang.equals(pair.target)))
          .get();
      final byId = {for (final w in words) w.id: w};
      return plans.map((p) => byId[p.wordId]).whereType<Word>().toList();
    }
    // Days from before week-ahead planning existed.
    final learned = await (_db.select(_db.learnedWords)
          ..where((t) => t.lastShownDate.equals(yesterday)))
        .get();
    return _wordsForLearned(learned);
  }

  Future<List<Word>> favoriteWords() async {
    final favorites = await _db.select(_db.favoriteWords).get();
    final ids = favorites.map((f) => f.wordId).toList();
    if (ids.isEmpty) return [];
    return (_db.select(_db.words)..where((t) => t.id.isIn(ids))).get();
  }

  Future<bool> isFavorite(int wordId) async {
    final row = await (_db.select(_db.favoriteWords)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> toggleFavorite(int wordId) async {
    final row = await (_db.select(_db.favoriteWords)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
    if (row == null) {
      await _db.into(_db.favoriteWords).insert(FavoriteWordsCompanion.insert(wordId: wordId));
    } else {
      await (_db.delete(_db.favoriteWords)..where((t) => t.id.equals(row.id))).go();
    }
  }

  Future<int> totalWordsLearnedCount() async {
    final all = await _db.select(_db.learnedWords).get();
    return all.length;
  }

  // ---------------------------------------------------------------------
  // Reminders
  // ---------------------------------------------------------------------

  Stream<List<Reminder>> watchReminders() =>
      (_db.select(_db.reminders)..orderBy([(t) => OrderingTerm.asc(t.timeMinutes)])).watch();

  Future<int> upsertReminder(RemindersCompanion companion, {int? id}) async {
    if (id == null) {
      return _db.into(_db.reminders).insert(companion);
    }
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(companion);
    return id;
  }

  Future<void> deleteReminder(int id) =>
      (_db.delete(_db.reminders)..where((t) => t.id.equals(id))).go();

  Future<void> setReminderEnabled(int id, bool enabled) =>
      (_db.update(_db.reminders)..where((t) => t.id.equals(id)))
          .write(RemindersCompanion(enabled: Value(enabled)));

  Future<List<Reminder>> allEnabledReminders() =>
      (_db.select(_db.reminders)..where((t) => t.enabled.equals(true))).get();

  Future<List<Reminder>> allReminders() => _db.select(_db.reminders).get();

  Future<List<Word>> allWords() => _db.select(_db.words).get();

  // ---------------------------------------------------------------------
  // Notification log / history
  // ---------------------------------------------------------------------

  /// Replaces every not-yet-happened log row with [planned]. Called by
  /// the scheduler each time it rebuilds the schedule, so History never
  /// keeps entries for notifications that were rescheduled or removed.
  ///
  /// There is no reliable OS callback for "a local notification was
  /// shown", so `deliveredAt` is set to the scheduled time; a row counts
  /// as delivered once that time has passed.
  Future<void> replaceFutureLogs(DateTime now, List<NotificationLogsCompanion> planned) async {
    await _db.transaction(() async {
      await (_db.delete(_db.notificationLogs)..where((t) => t.scheduledAt.isBiggerThanValue(now))).go();
      await _db.batch((b) => b.insertAll(_db.notificationLogs, planned));
    });
  }

  /// Notifications from the last [days] days that have already happened.
  Future<List<NotificationLog>> recentHistory({int days = 14}) {
    final now = DateTime.now();
    final cutoff = _dateOnly(now).subtract(Duration(days: days));
    return (_db.select(_db.notificationLogs)
          ..where((t) => t.scheduledAt.isBiggerOrEqualValue(cutoff) & t.scheduledAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .get();
  }

  /// Notifications on [day], including ones still to come today.
  Future<List<NotificationLog>> historyForDay(DateTime day) {
    final start = _dateOnly(day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.notificationLogs)
          ..where((t) => t.scheduledAt.isBiggerOrEqualValue(start) & t.scheduledAt.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]))
        .get();
  }

  /// Current streak in days of at least one delivered notification
  /// (reminder completion or vocab word) per day, ending today or
  /// yesterday (so a streak isn't broken until a full day is missed).
  Future<int> currentStreakDays() async {
    final now = DateTime.now();
    final delivered = await (_db.select(_db.notificationLogs)
          ..where((t) => t.deliveredAt.isSmallerOrEqualValue(now)))
        .get();
    if (delivered.isEmpty) return 0;

    final daysWithActivity = delivered
        .map((n) => _dateOnly(n.deliveredAt!))
        .toSet();

    var streak = 0;
    var cursor = _dateOnly(DateTime.now());
    if (!daysWithActivity.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (daysWithActivity.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
