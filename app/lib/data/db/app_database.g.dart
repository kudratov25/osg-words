// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMinutesMeta = const VerificationMeta(
    'timeMinutes',
  );
  @override
  late final GeneratedColumn<int> timeMinutes = GeneratedColumn<int>(
    'time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RepeatType, String> repeatType =
      GeneratedColumn<String>(
        'repeat_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('daily'),
      ).withConverter<RepeatType>($RemindersTable.$converterrepeatType);
  static const VerificationMeta _onDateMeta = const VerificationMeta('onDate');
  @override
  late final GeneratedColumn<DateTime> onDate = GeneratedColumn<DateTime>(
    'on_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _nextOccurrenceMeta = const VerificationMeta(
    'nextOccurrence',
  );
  @override
  late final GeneratedColumn<DateTime> nextOccurrence =
      GeneratedColumn<DateTime>(
        'next_occurrence',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    timeMinutes,
    repeatType,
    onDate,
    dayOfWeek,
    dayOfMonth,
    enabled,
    nextOccurrence,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('time_minutes')) {
      context.handle(
        _timeMinutesMeta,
        timeMinutes.isAcceptableOrUnknown(
          data['time_minutes']!,
          _timeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeMinutesMeta);
    }
    if (data.containsKey('on_date')) {
      context.handle(
        _onDateMeta,
        onDate.isAcceptableOrUnknown(data['on_date']!, _onDateMeta),
      );
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('next_occurrence')) {
      context.handle(
        _nextOccurrenceMeta,
        nextOccurrence.isAcceptableOrUnknown(
          data['next_occurrence']!,
          _nextOccurrenceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      timeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_minutes'],
      )!,
      repeatType: $RemindersTable.$converterrepeatType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repeat_type'],
        )!,
      ),
      onDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}on_date'],
      ),
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      ),
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      nextOccurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_occurrence'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RepeatType, String, String> $converterrepeatType =
      const EnumNameConverter<RepeatType>(RepeatType.values);
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;
  final String? description;

  /// Time of day the reminder fires, stored as total minutes since midnight
  /// (0-1439). Kept separate from date fields so recurrence rules apply
  /// against "today at this time" regardless of repeat type.
  final int timeMinutes;
  final RepeatType repeatType;

  /// Only used when repeatType == once: the specific calendar date.
  final DateTime? onDate;

  /// Only used when repeatType == weekly: 1 (Monday) - 7 (Sunday).
  final int? dayOfWeek;

  /// Only used when repeatType == monthly: 1-31.
  final int? dayOfMonth;
  final bool enabled;

  /// Cached next fire time, recomputed by the recurrence engine whenever
  /// the app opens or a reminder is created/edited. Avoids recomputing
  /// recurrence math every time we just need "what's due next".
  final DateTime? nextOccurrence;
  final DateTime createdAt;
  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.timeMinutes,
    required this.repeatType,
    this.onDate,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.enabled,
    this.nextOccurrence,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['time_minutes'] = Variable<int>(timeMinutes);
    {
      map['repeat_type'] = Variable<String>(
        $RemindersTable.$converterrepeatType.toSql(repeatType),
      );
    }
    if (!nullToAbsent || onDate != null) {
      map['on_date'] = Variable<DateTime>(onDate);
    }
    if (!nullToAbsent || dayOfWeek != null) {
      map['day_of_week'] = Variable<int>(dayOfWeek);
    }
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || nextOccurrence != null) {
      map['next_occurrence'] = Variable<DateTime>(nextOccurrence);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      timeMinutes: Value(timeMinutes),
      repeatType: Value(repeatType),
      onDate: onDate == null && nullToAbsent
          ? const Value.absent()
          : Value(onDate),
      dayOfWeek: dayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfWeek),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      enabled: Value(enabled),
      nextOccurrence: nextOccurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(nextOccurrence),
      createdAt: Value(createdAt),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      timeMinutes: serializer.fromJson<int>(json['timeMinutes']),
      repeatType: $RemindersTable.$converterrepeatType.fromJson(
        serializer.fromJson<String>(json['repeatType']),
      ),
      onDate: serializer.fromJson<DateTime?>(json['onDate']),
      dayOfWeek: serializer.fromJson<int?>(json['dayOfWeek']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      nextOccurrence: serializer.fromJson<DateTime?>(json['nextOccurrence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'timeMinutes': serializer.toJson<int>(timeMinutes),
      'repeatType': serializer.toJson<String>(
        $RemindersTable.$converterrepeatType.toJson(repeatType),
      ),
      'onDate': serializer.toJson<DateTime?>(onDate),
      'dayOfWeek': serializer.toJson<int?>(dayOfWeek),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'enabled': serializer.toJson<bool>(enabled),
      'nextOccurrence': serializer.toJson<DateTime?>(nextOccurrence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    int? timeMinutes,
    RepeatType? repeatType,
    Value<DateTime?> onDate = const Value.absent(),
    Value<int?> dayOfWeek = const Value.absent(),
    Value<int?> dayOfMonth = const Value.absent(),
    bool? enabled,
    Value<DateTime?> nextOccurrence = const Value.absent(),
    DateTime? createdAt,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    timeMinutes: timeMinutes ?? this.timeMinutes,
    repeatType: repeatType ?? this.repeatType,
    onDate: onDate.present ? onDate.value : this.onDate,
    dayOfWeek: dayOfWeek.present ? dayOfWeek.value : this.dayOfWeek,
    dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
    enabled: enabled ?? this.enabled,
    nextOccurrence: nextOccurrence.present
        ? nextOccurrence.value
        : this.nextOccurrence,
    createdAt: createdAt ?? this.createdAt,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      timeMinutes: data.timeMinutes.present
          ? data.timeMinutes.value
          : this.timeMinutes,
      repeatType: data.repeatType.present
          ? data.repeatType.value
          : this.repeatType,
      onDate: data.onDate.present ? data.onDate.value : this.onDate,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      nextOccurrence: data.nextOccurrence.present
          ? data.nextOccurrence.value
          : this.nextOccurrence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('repeatType: $repeatType, ')
          ..write('onDate: $onDate, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('enabled: $enabled, ')
          ..write('nextOccurrence: $nextOccurrence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    timeMinutes,
    repeatType,
    onDate,
    dayOfWeek,
    dayOfMonth,
    enabled,
    nextOccurrence,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.timeMinutes == this.timeMinutes &&
          other.repeatType == this.repeatType &&
          other.onDate == this.onDate &&
          other.dayOfWeek == this.dayOfWeek &&
          other.dayOfMonth == this.dayOfMonth &&
          other.enabled == this.enabled &&
          other.nextOccurrence == this.nextOccurrence &&
          other.createdAt == this.createdAt);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> timeMinutes;
  final Value<RepeatType> repeatType;
  final Value<DateTime?> onDate;
  final Value<int?> dayOfWeek;
  final Value<int?> dayOfMonth;
  final Value<bool> enabled;
  final Value<DateTime?> nextOccurrence;
  final Value<DateTime> createdAt;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.timeMinutes = const Value.absent(),
    this.repeatType = const Value.absent(),
    this.onDate = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.enabled = const Value.absent(),
    this.nextOccurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int timeMinutes,
    this.repeatType = const Value.absent(),
    this.onDate = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.enabled = const Value.absent(),
    this.nextOccurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title),
       timeMinutes = Value(timeMinutes);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? timeMinutes,
    Expression<String>? repeatType,
    Expression<DateTime>? onDate,
    Expression<int>? dayOfWeek,
    Expression<int>? dayOfMonth,
    Expression<bool>? enabled,
    Expression<DateTime>? nextOccurrence,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (timeMinutes != null) 'time_minutes': timeMinutes,
      if (repeatType != null) 'repeat_type': repeatType,
      if (onDate != null) 'on_date': onDate,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (enabled != null) 'enabled': enabled,
      if (nextOccurrence != null) 'next_occurrence': nextOccurrence,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? timeMinutes,
    Value<RepeatType>? repeatType,
    Value<DateTime?>? onDate,
    Value<int?>? dayOfWeek,
    Value<int?>? dayOfMonth,
    Value<bool>? enabled,
    Value<DateTime?>? nextOccurrence,
    Value<DateTime>? createdAt,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      repeatType: repeatType ?? this.repeatType,
      onDate: onDate ?? this.onDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      enabled: enabled ?? this.enabled,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (timeMinutes.present) {
      map['time_minutes'] = Variable<int>(timeMinutes.value);
    }
    if (repeatType.present) {
      map['repeat_type'] = Variable<String>(
        $RemindersTable.$converterrepeatType.toSql(repeatType.value),
      );
    }
    if (onDate.present) {
      map['on_date'] = Variable<DateTime>(onDate.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (nextOccurrence.present) {
      map['next_occurrence'] = Variable<DateTime>(nextOccurrence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('timeMinutes: $timeMinutes, ')
          ..write('repeatType: $repeatType, ')
          ..write('onDate: $onDate, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('enabled: $enabled, ')
          ..write('nextOccurrence: $nextOccurrence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('de'),
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _articleMeta = const VerificationMeta(
    'article',
  );
  @override
  late final GeneratedColumn<String> article = GeneratedColumn<String>(
    'article',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleTranslationMeta =
      const VerificationMeta('exampleTranslation');
  @override
  late final GeneratedColumn<String> exampleTranslation =
      GeneratedColumn<String>(
        'example_translation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pronunciationMeta = const VerificationMeta(
    'pronunciation',
  );
  @override
  late final GeneratedColumn<String> pronunciation = GeneratedColumn<String>(
    'pronunciation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('beginner'),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicsMeta = const VerificationMeta('topics');
  @override
  late final GeneratedColumn<String> topics = GeneratedColumn<String>(
    'topics',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    externalId,
    lang,
    term,
    article,
    translation,
    example,
    exampleTranslation,
    pronunciation,
    category,
    difficulty,
    level,
    topics,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('article')) {
      context.handle(
        _articleMeta,
        article.isAcceptableOrUnknown(data['article']!, _articleMeta),
      );
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    } else if (isInserting) {
      context.missing(_exampleMeta);
    }
    if (data.containsKey('example_translation')) {
      context.handle(
        _exampleTranslationMeta,
        exampleTranslation.isAcceptableOrUnknown(
          data['example_translation']!,
          _exampleTranslationMeta,
        ),
      );
    }
    if (data.containsKey('pronunciation')) {
      context.handle(
        _pronunciationMeta,
        pronunciation.isAcceptableOrUnknown(
          data['pronunciation']!,
          _pronunciationMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('topics')) {
      context.handle(
        _topicsMeta,
        topics.isAcceptableOrUnknown(data['topics']!, _topicsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      article: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}article'],
      ),
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      )!,
      exampleTranslation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_translation'],
      ),
      pronunciation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pronunciation'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      ),
      topics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topics'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  final int id;

  /// Stable id from the backend content pack, used to dedupe on sync.
  final String externalId;

  /// Target language of the word (`de`, `en`) - see lib/data/languages.dart.
  final String lang;

  /// The word itself in the target language (was `german` before v3).
  final String term;
  final String? article;

  /// Translation into the current source language. Replaced in place when
  /// the source language changes (the row id - and so progress - is kept).
  final String translation;
  final String example;
  final String? exampleTranslation;
  final String? pronunciation;
  final String category;
  final String difficulty;

  /// CEFR level A1..C1 (v4). Null for words downloaded before 2.1.
  final String? level;

  /// Job-area keys, comma-separated (v4); empty = general word.
  final String topics;
  final DateTime createdAt;
  const Word({
    required this.id,
    required this.externalId,
    required this.lang,
    required this.term,
    this.article,
    required this.translation,
    required this.example,
    this.exampleTranslation,
    this.pronunciation,
    required this.category,
    required this.difficulty,
    this.level,
    required this.topics,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['external_id'] = Variable<String>(externalId);
    map['lang'] = Variable<String>(lang);
    map['term'] = Variable<String>(term);
    if (!nullToAbsent || article != null) {
      map['article'] = Variable<String>(article);
    }
    map['translation'] = Variable<String>(translation);
    map['example'] = Variable<String>(example);
    if (!nullToAbsent || exampleTranslation != null) {
      map['example_translation'] = Variable<String>(exampleTranslation);
    }
    if (!nullToAbsent || pronunciation != null) {
      map['pronunciation'] = Variable<String>(pronunciation);
    }
    map['category'] = Variable<String>(category);
    map['difficulty'] = Variable<String>(difficulty);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<String>(level);
    }
    map['topics'] = Variable<String>(topics);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      externalId: Value(externalId),
      lang: Value(lang),
      term: Value(term),
      article: article == null && nullToAbsent
          ? const Value.absent()
          : Value(article),
      translation: Value(translation),
      example: Value(example),
      exampleTranslation: exampleTranslation == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleTranslation),
      pronunciation: pronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(pronunciation),
      category: Value(category),
      difficulty: Value(difficulty),
      level: level == null && nullToAbsent
          ? const Value.absent()
          : Value(level),
      topics: Value(topics),
      createdAt: Value(createdAt),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      externalId: serializer.fromJson<String>(json['externalId']),
      lang: serializer.fromJson<String>(json['lang']),
      term: serializer.fromJson<String>(json['term']),
      article: serializer.fromJson<String?>(json['article']),
      translation: serializer.fromJson<String>(json['translation']),
      example: serializer.fromJson<String>(json['example']),
      exampleTranslation: serializer.fromJson<String?>(
        json['exampleTranslation'],
      ),
      pronunciation: serializer.fromJson<String?>(json['pronunciation']),
      category: serializer.fromJson<String>(json['category']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      level: serializer.fromJson<String?>(json['level']),
      topics: serializer.fromJson<String>(json['topics']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'externalId': serializer.toJson<String>(externalId),
      'lang': serializer.toJson<String>(lang),
      'term': serializer.toJson<String>(term),
      'article': serializer.toJson<String?>(article),
      'translation': serializer.toJson<String>(translation),
      'example': serializer.toJson<String>(example),
      'exampleTranslation': serializer.toJson<String?>(exampleTranslation),
      'pronunciation': serializer.toJson<String?>(pronunciation),
      'category': serializer.toJson<String>(category),
      'difficulty': serializer.toJson<String>(difficulty),
      'level': serializer.toJson<String?>(level),
      'topics': serializer.toJson<String>(topics),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Word copyWith({
    int? id,
    String? externalId,
    String? lang,
    String? term,
    Value<String?> article = const Value.absent(),
    String? translation,
    String? example,
    Value<String?> exampleTranslation = const Value.absent(),
    Value<String?> pronunciation = const Value.absent(),
    String? category,
    String? difficulty,
    Value<String?> level = const Value.absent(),
    String? topics,
    DateTime? createdAt,
  }) => Word(
    id: id ?? this.id,
    externalId: externalId ?? this.externalId,
    lang: lang ?? this.lang,
    term: term ?? this.term,
    article: article.present ? article.value : this.article,
    translation: translation ?? this.translation,
    example: example ?? this.example,
    exampleTranslation: exampleTranslation.present
        ? exampleTranslation.value
        : this.exampleTranslation,
    pronunciation: pronunciation.present
        ? pronunciation.value
        : this.pronunciation,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    level: level.present ? level.value : this.level,
    topics: topics ?? this.topics,
    createdAt: createdAt ?? this.createdAt,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      lang: data.lang.present ? data.lang.value : this.lang,
      term: data.term.present ? data.term.value : this.term,
      article: data.article.present ? data.article.value : this.article,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      example: data.example.present ? data.example.value : this.example,
      exampleTranslation: data.exampleTranslation.present
          ? data.exampleTranslation.value
          : this.exampleTranslation,
      pronunciation: data.pronunciation.present
          ? data.pronunciation.value
          : this.pronunciation,
      category: data.category.present ? data.category.value : this.category,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      level: data.level.present ? data.level.value : this.level,
      topics: data.topics.present ? data.topics.value : this.topics,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('lang: $lang, ')
          ..write('term: $term, ')
          ..write('article: $article, ')
          ..write('translation: $translation, ')
          ..write('example: $example, ')
          ..write('exampleTranslation: $exampleTranslation, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('level: $level, ')
          ..write('topics: $topics, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    externalId,
    lang,
    term,
    article,
    translation,
    example,
    exampleTranslation,
    pronunciation,
    category,
    difficulty,
    level,
    topics,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.externalId == this.externalId &&
          other.lang == this.lang &&
          other.term == this.term &&
          other.article == this.article &&
          other.translation == this.translation &&
          other.example == this.example &&
          other.exampleTranslation == this.exampleTranslation &&
          other.pronunciation == this.pronunciation &&
          other.category == this.category &&
          other.difficulty == this.difficulty &&
          other.level == this.level &&
          other.topics == this.topics &&
          other.createdAt == this.createdAt);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> externalId;
  final Value<String> lang;
  final Value<String> term;
  final Value<String?> article;
  final Value<String> translation;
  final Value<String> example;
  final Value<String?> exampleTranslation;
  final Value<String?> pronunciation;
  final Value<String> category;
  final Value<String> difficulty;
  final Value<String?> level;
  final Value<String> topics;
  final Value<DateTime> createdAt;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.externalId = const Value.absent(),
    this.lang = const Value.absent(),
    this.term = const Value.absent(),
    this.article = const Value.absent(),
    this.translation = const Value.absent(),
    this.example = const Value.absent(),
    this.exampleTranslation = const Value.absent(),
    this.pronunciation = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.level = const Value.absent(),
    this.topics = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String externalId,
    this.lang = const Value.absent(),
    required String term,
    this.article = const Value.absent(),
    required String translation,
    required String example,
    this.exampleTranslation = const Value.absent(),
    this.pronunciation = const Value.absent(),
    required String category,
    this.difficulty = const Value.absent(),
    this.level = const Value.absent(),
    this.topics = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : externalId = Value(externalId),
       term = Value(term),
       translation = Value(translation),
       example = Value(example),
       category = Value(category);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? externalId,
    Expression<String>? lang,
    Expression<String>? term,
    Expression<String>? article,
    Expression<String>? translation,
    Expression<String>? example,
    Expression<String>? exampleTranslation,
    Expression<String>? pronunciation,
    Expression<String>? category,
    Expression<String>? difficulty,
    Expression<String>? level,
    Expression<String>? topics,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (externalId != null) 'external_id': externalId,
      if (lang != null) 'lang': lang,
      if (term != null) 'term': term,
      if (article != null) 'article': article,
      if (translation != null) 'translation': translation,
      if (example != null) 'example': example,
      if (exampleTranslation != null) 'example_translation': exampleTranslation,
      if (pronunciation != null) 'pronunciation': pronunciation,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (level != null) 'level': level,
      if (topics != null) 'topics': topics,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? externalId,
    Value<String>? lang,
    Value<String>? term,
    Value<String?>? article,
    Value<String>? translation,
    Value<String>? example,
    Value<String?>? exampleTranslation,
    Value<String?>? pronunciation,
    Value<String>? category,
    Value<String>? difficulty,
    Value<String?>? level,
    Value<String>? topics,
    Value<DateTime>? createdAt,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      externalId: externalId ?? this.externalId,
      lang: lang ?? this.lang,
      term: term ?? this.term,
      article: article ?? this.article,
      translation: translation ?? this.translation,
      example: example ?? this.example,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      pronunciation: pronunciation ?? this.pronunciation,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      level: level ?? this.level,
      topics: topics ?? this.topics,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(article.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (exampleTranslation.present) {
      map['example_translation'] = Variable<String>(exampleTranslation.value);
    }
    if (pronunciation.present) {
      map['pronunciation'] = Variable<String>(pronunciation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (topics.present) {
      map['topics'] = Variable<String>(topics.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('externalId: $externalId, ')
          ..write('lang: $lang, ')
          ..write('term: $term, ')
          ..write('article: $article, ')
          ..write('translation: $translation, ')
          ..write('example: $example, ')
          ..write('exampleTranslation: $exampleTranslation, ')
          ..write('pronunciation: $pronunciation, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('level: $level, ')
          ..write('topics: $topics, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavoriteWordsTable extends FavoriteWords
    with TableInfo<$FavoriteWordsTable, FavoriteWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoriteWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, wordId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavoriteWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId},
  ];
  @override
  FavoriteWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoriteWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavoriteWordsTable createAlias(String alias) {
    return $FavoriteWordsTable(attachedDatabase, alias);
  }
}

class FavoriteWord extends DataClass implements Insertable<FavoriteWord> {
  final int id;
  final int wordId;
  final DateTime createdAt;
  const FavoriteWord({
    required this.id,
    required this.wordId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavoriteWordsCompanion toCompanion(bool nullToAbsent) {
    return FavoriteWordsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      createdAt: Value(createdAt),
    );
  }

  factory FavoriteWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoriteWord(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FavoriteWord copyWith({int? id, int? wordId, DateTime? createdAt}) =>
      FavoriteWord(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        createdAt: createdAt ?? this.createdAt,
      );
  FavoriteWord copyWithCompanion(FavoriteWordsCompanion data) {
    return FavoriteWord(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteWord(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, wordId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteWord &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.createdAt == this.createdAt);
}

class FavoriteWordsCompanion extends UpdateCompanion<FavoriteWord> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<DateTime> createdAt;
  const FavoriteWordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FavoriteWordsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    this.createdAt = const Value.absent(),
  }) : wordId = Value(wordId);
  static Insertable<FavoriteWord> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FavoriteWordsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<DateTime>? createdAt,
  }) {
    return FavoriteWordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoriteWordsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LearnedWordsTable extends LearnedWords
    with TableInfo<$LearnedWordsTable, LearnedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnedWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _firstSeenDateMeta = const VerificationMeta(
    'firstSeenDate',
  );
  @override
  late final GeneratedColumn<DateTime> firstSeenDate =
      GeneratedColumn<DateTime>(
        'first_seen_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _lastShownDateMeta = const VerificationMeta(
    'lastShownDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastShownDate =
      GeneratedColumn<DateTime>(
        'last_shown_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _timesShownMeta = const VerificationMeta(
    'timesShown',
  );
  @override
  late final GeneratedColumn<int> timesShown = GeneratedColumn<int>(
    'times_shown',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    firstSeenDate,
    lastShownDate,
    timesShown,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learned_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearnedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('first_seen_date')) {
      context.handle(
        _firstSeenDateMeta,
        firstSeenDate.isAcceptableOrUnknown(
          data['first_seen_date']!,
          _firstSeenDateMeta,
        ),
      );
    }
    if (data.containsKey('last_shown_date')) {
      context.handle(
        _lastShownDateMeta,
        lastShownDate.isAcceptableOrUnknown(
          data['last_shown_date']!,
          _lastShownDateMeta,
        ),
      );
    }
    if (data.containsKey('times_shown')) {
      context.handle(
        _timesShownMeta,
        timesShown.isAcceptableOrUnknown(data['times_shown']!, _timesShownMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {wordId},
  ];
  @override
  LearnedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearnedWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      firstSeenDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}first_seen_date'],
      )!,
      lastShownDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_shown_date'],
      )!,
      timesShown: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_shown'],
      )!,
    );
  }

  @override
  $LearnedWordsTable createAlias(String alias) {
    return $LearnedWordsTable(attachedDatabase, alias);
  }
}

class LearnedWord extends DataClass implements Insertable<LearnedWord> {
  final int id;
  final int wordId;
  final DateTime firstSeenDate;
  final DateTime lastShownDate;
  final int timesShown;
  const LearnedWord({
    required this.id,
    required this.wordId,
    required this.firstSeenDate,
    required this.lastShownDate,
    required this.timesShown,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['first_seen_date'] = Variable<DateTime>(firstSeenDate);
    map['last_shown_date'] = Variable<DateTime>(lastShownDate);
    map['times_shown'] = Variable<int>(timesShown);
    return map;
  }

  LearnedWordsCompanion toCompanion(bool nullToAbsent) {
    return LearnedWordsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      firstSeenDate: Value(firstSeenDate),
      lastShownDate: Value(lastShownDate),
      timesShown: Value(timesShown),
    );
  }

  factory LearnedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearnedWord(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      firstSeenDate: serializer.fromJson<DateTime>(json['firstSeenDate']),
      lastShownDate: serializer.fromJson<DateTime>(json['lastShownDate']),
      timesShown: serializer.fromJson<int>(json['timesShown']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'firstSeenDate': serializer.toJson<DateTime>(firstSeenDate),
      'lastShownDate': serializer.toJson<DateTime>(lastShownDate),
      'timesShown': serializer.toJson<int>(timesShown),
    };
  }

  LearnedWord copyWith({
    int? id,
    int? wordId,
    DateTime? firstSeenDate,
    DateTime? lastShownDate,
    int? timesShown,
  }) => LearnedWord(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    firstSeenDate: firstSeenDate ?? this.firstSeenDate,
    lastShownDate: lastShownDate ?? this.lastShownDate,
    timesShown: timesShown ?? this.timesShown,
  );
  LearnedWord copyWithCompanion(LearnedWordsCompanion data) {
    return LearnedWord(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      firstSeenDate: data.firstSeenDate.present
          ? data.firstSeenDate.value
          : this.firstSeenDate,
      lastShownDate: data.lastShownDate.present
          ? data.lastShownDate.value
          : this.lastShownDate,
      timesShown: data.timesShown.present
          ? data.timesShown.value
          : this.timesShown,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearnedWord(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('firstSeenDate: $firstSeenDate, ')
          ..write('lastShownDate: $lastShownDate, ')
          ..write('timesShown: $timesShown')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, wordId, firstSeenDate, lastShownDate, timesShown);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnedWord &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.firstSeenDate == this.firstSeenDate &&
          other.lastShownDate == this.lastShownDate &&
          other.timesShown == this.timesShown);
}

class LearnedWordsCompanion extends UpdateCompanion<LearnedWord> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<DateTime> firstSeenDate;
  final Value<DateTime> lastShownDate;
  final Value<int> timesShown;
  const LearnedWordsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.firstSeenDate = const Value.absent(),
    this.lastShownDate = const Value.absent(),
    this.timesShown = const Value.absent(),
  });
  LearnedWordsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    this.firstSeenDate = const Value.absent(),
    this.lastShownDate = const Value.absent(),
    this.timesShown = const Value.absent(),
  }) : wordId = Value(wordId);
  static Insertable<LearnedWord> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<DateTime>? firstSeenDate,
    Expression<DateTime>? lastShownDate,
    Expression<int>? timesShown,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (firstSeenDate != null) 'first_seen_date': firstSeenDate,
      if (lastShownDate != null) 'last_shown_date': lastShownDate,
      if (timesShown != null) 'times_shown': timesShown,
    });
  }

  LearnedWordsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<DateTime>? firstSeenDate,
    Value<DateTime>? lastShownDate,
    Value<int>? timesShown,
  }) {
    return LearnedWordsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      firstSeenDate: firstSeenDate ?? this.firstSeenDate,
      lastShownDate: lastShownDate ?? this.lastShownDate,
      timesShown: timesShown ?? this.timesShown,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (firstSeenDate.present) {
      map['first_seen_date'] = Variable<DateTime>(firstSeenDate.value);
    }
    if (lastShownDate.present) {
      map['last_shown_date'] = Variable<DateTime>(lastShownDate.value);
    }
    if (timesShown.present) {
      map['times_shown'] = Variable<int>(timesShown.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnedWordsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('firstSeenDate: $firstSeenDate, ')
          ..write('lastShownDate: $lastShownDate, ')
          ..write('timesShown: $timesShown')
          ..write(')'))
        .toString();
  }
}

class $NotificationLogsTable extends NotificationLogs
    with TableInfo<$NotificationLogsTable, NotificationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<NotificationKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<NotificationKind>($NotificationLogsTable.$converterkind);
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<int> reminderId = GeneratedColumn<int>(
    'reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES reminders (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deliveredAtMeta = const VerificationMeta(
    'deliveredAt',
  );
  @override
  late final GeneratedColumn<DateTime> deliveredAt = GeneratedColumn<DateTime>(
    'delivered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    reminderId,
    wordId,
    scheduledAt,
    deliveredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('delivered_at')) {
      context.handle(
        _deliveredAtMeta,
        deliveredAt.isAcceptableOrUnknown(
          data['delivered_at']!,
          _deliveredAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $NotificationLogsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_id'],
      ),
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      deliveredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}delivered_at'],
      ),
    );
  }

  @override
  $NotificationLogsTable createAlias(String alias) {
    return $NotificationLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<NotificationKind, String, String> $converterkind =
      const EnumNameConverter<NotificationKind>(NotificationKind.values);
}

class NotificationLog extends DataClass implements Insertable<NotificationLog> {
  final int id;
  final NotificationKind kind;

  /// Reminder id when kind is reminder/combined.
  final int? reminderId;

  /// Word id when kind is vocab/combined.
  final int? wordId;
  final DateTime scheduledAt;
  final DateTime? deliveredAt;
  const NotificationLog({
    required this.id,
    required this.kind,
    this.reminderId,
    this.wordId,
    required this.scheduledAt,
    this.deliveredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
        $NotificationLogsTable.$converterkind.toSql(kind),
      );
    }
    if (!nullToAbsent || reminderId != null) {
      map['reminder_id'] = Variable<int>(reminderId);
    }
    if (!nullToAbsent || wordId != null) {
      map['word_id'] = Variable<int>(wordId);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || deliveredAt != null) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt);
    }
    return map;
  }

  NotificationLogsCompanion toCompanion(bool nullToAbsent) {
    return NotificationLogsCompanion(
      id: Value(id),
      kind: Value(kind),
      reminderId: reminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderId),
      wordId: wordId == null && nullToAbsent
          ? const Value.absent()
          : Value(wordId),
      scheduledAt: Value(scheduledAt),
      deliveredAt: deliveredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deliveredAt),
    );
  }

  factory NotificationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationLog(
      id: serializer.fromJson<int>(json['id']),
      kind: $NotificationLogsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      reminderId: serializer.fromJson<int?>(json['reminderId']),
      wordId: serializer.fromJson<int?>(json['wordId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      deliveredAt: serializer.fromJson<DateTime?>(json['deliveredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $NotificationLogsTable.$converterkind.toJson(kind),
      ),
      'reminderId': serializer.toJson<int?>(reminderId),
      'wordId': serializer.toJson<int?>(wordId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'deliveredAt': serializer.toJson<DateTime?>(deliveredAt),
    };
  }

  NotificationLog copyWith({
    int? id,
    NotificationKind? kind,
    Value<int?> reminderId = const Value.absent(),
    Value<int?> wordId = const Value.absent(),
    DateTime? scheduledAt,
    Value<DateTime?> deliveredAt = const Value.absent(),
  }) => NotificationLog(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    reminderId: reminderId.present ? reminderId.value : this.reminderId,
    wordId: wordId.present ? wordId.value : this.wordId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    deliveredAt: deliveredAt.present ? deliveredAt.value : this.deliveredAt,
  );
  NotificationLog copyWithCompanion(NotificationLogsCompanion data) {
    return NotificationLog(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      deliveredAt: data.deliveredAt.present
          ? data.deliveredAt.value
          : this.deliveredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLog(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('reminderId: $reminderId, ')
          ..write('wordId: $wordId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, reminderId, wordId, scheduledAt, deliveredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationLog &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.reminderId == this.reminderId &&
          other.wordId == this.wordId &&
          other.scheduledAt == this.scheduledAt &&
          other.deliveredAt == this.deliveredAt);
}

class NotificationLogsCompanion extends UpdateCompanion<NotificationLog> {
  final Value<int> id;
  final Value<NotificationKind> kind;
  final Value<int?> reminderId;
  final Value<int?> wordId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> deliveredAt;
  const NotificationLogsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.deliveredAt = const Value.absent(),
  });
  NotificationLogsCompanion.insert({
    this.id = const Value.absent(),
    required NotificationKind kind,
    this.reminderId = const Value.absent(),
    this.wordId = const Value.absent(),
    required DateTime scheduledAt,
    this.deliveredAt = const Value.absent(),
  }) : kind = Value(kind),
       scheduledAt = Value(scheduledAt);
  static Insertable<NotificationLog> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? reminderId,
    Expression<int>? wordId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? deliveredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (reminderId != null) 'reminder_id': reminderId,
      if (wordId != null) 'word_id': wordId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (deliveredAt != null) 'delivered_at': deliveredAt,
    });
  }

  NotificationLogsCompanion copyWith({
    Value<int>? id,
    Value<NotificationKind>? kind,
    Value<int?>? reminderId,
    Value<int?>? wordId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? deliveredAt,
  }) {
    return NotificationLogsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      reminderId: reminderId ?? this.reminderId,
      wordId: wordId ?? this.wordId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $NotificationLogsTable.$converterkind.toSql(kind.value),
      );
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<int>(reminderId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (deliveredAt.present) {
      map['delivered_at'] = Variable<DateTime>(deliveredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationLogsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('reminderId: $reminderId, ')
          ..write('wordId: $wordId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('deliveredAt: $deliveredAt')
          ..write(')'))
        .toString();
  }
}

class $WordPlansTable extends WordPlans
    with TableInfo<$WordPlansTable, WordPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _recordedMeta = const VerificationMeta(
    'recorded',
  );
  @override
  late final GeneratedColumn<bool> recorded = GeneratedColumn<bool>(
    'recorded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recorded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, slot, wordId, recorded];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('recorded')) {
      context.handle(
        _recordedMeta,
        recorded.isAcceptableOrUnknown(data['recorded']!, _recordedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {day, slot},
  ];
  @override
  WordPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      recorded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recorded'],
      )!,
    );
  }

  @override
  $WordPlansTable createAlias(String alias) {
    return $WordPlansTable(attachedDatabase, alias);
  }
}

class WordPlan extends DataClass implements Insertable<WordPlan> {
  final int id;

  /// Local calendar date (midnight).
  final DateTime day;

  /// Index into the vocab slot times (0 = 08:00, 1 = 12:00, 2 = 18:00).
  final int slot;
  final int wordId;
  final bool recorded;
  const WordPlan({
    required this.id,
    required this.day,
    required this.slot,
    required this.wordId,
    required this.recorded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<DateTime>(day);
    map['slot'] = Variable<int>(slot);
    map['word_id'] = Variable<int>(wordId);
    map['recorded'] = Variable<bool>(recorded);
    return map;
  }

  WordPlansCompanion toCompanion(bool nullToAbsent) {
    return WordPlansCompanion(
      id: Value(id),
      day: Value(day),
      slot: Value(slot),
      wordId: Value(wordId),
      recorded: Value(recorded),
    );
  }

  factory WordPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordPlan(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<DateTime>(json['day']),
      slot: serializer.fromJson<int>(json['slot']),
      wordId: serializer.fromJson<int>(json['wordId']),
      recorded: serializer.fromJson<bool>(json['recorded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<DateTime>(day),
      'slot': serializer.toJson<int>(slot),
      'wordId': serializer.toJson<int>(wordId),
      'recorded': serializer.toJson<bool>(recorded),
    };
  }

  WordPlan copyWith({
    int? id,
    DateTime? day,
    int? slot,
    int? wordId,
    bool? recorded,
  }) => WordPlan(
    id: id ?? this.id,
    day: day ?? this.day,
    slot: slot ?? this.slot,
    wordId: wordId ?? this.wordId,
    recorded: recorded ?? this.recorded,
  );
  WordPlan copyWithCompanion(WordPlansCompanion data) {
    return WordPlan(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      slot: data.slot.present ? data.slot.value : this.slot,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      recorded: data.recorded.present ? data.recorded.value : this.recorded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordPlan(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('slot: $slot, ')
          ..write('wordId: $wordId, ')
          ..write('recorded: $recorded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, slot, wordId, recorded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordPlan &&
          other.id == this.id &&
          other.day == this.day &&
          other.slot == this.slot &&
          other.wordId == this.wordId &&
          other.recorded == this.recorded);
}

class WordPlansCompanion extends UpdateCompanion<WordPlan> {
  final Value<int> id;
  final Value<DateTime> day;
  final Value<int> slot;
  final Value<int> wordId;
  final Value<bool> recorded;
  const WordPlansCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.slot = const Value.absent(),
    this.wordId = const Value.absent(),
    this.recorded = const Value.absent(),
  });
  WordPlansCompanion.insert({
    this.id = const Value.absent(),
    required DateTime day,
    required int slot,
    required int wordId,
    this.recorded = const Value.absent(),
  }) : day = Value(day),
       slot = Value(slot),
       wordId = Value(wordId);
  static Insertable<WordPlan> custom({
    Expression<int>? id,
    Expression<DateTime>? day,
    Expression<int>? slot,
    Expression<int>? wordId,
    Expression<bool>? recorded,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (slot != null) 'slot': slot,
      if (wordId != null) 'word_id': wordId,
      if (recorded != null) 'recorded': recorded,
    });
  }

  WordPlansCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? day,
    Value<int>? slot,
    Value<int>? wordId,
    Value<bool>? recorded,
  }) {
    return WordPlansCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      slot: slot ?? this.slot,
      wordId: wordId ?? this.wordId,
      recorded: recorded ?? this.recorded,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (recorded.present) {
      map['recorded'] = Variable<bool>(recorded.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordPlansCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('slot: $slot, ')
          ..write('wordId: $wordId, ')
          ..write('recorded: $recorded')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $WordsTable words = $WordsTable(this);
  late final $FavoriteWordsTable favoriteWords = $FavoriteWordsTable(this);
  late final $LearnedWordsTable learnedWords = $LearnedWordsTable(this);
  late final $NotificationLogsTable notificationLogs = $NotificationLogsTable(
    this,
  );
  late final $WordPlansTable wordPlans = $WordPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    reminders,
    words,
    favoriteWords,
    learnedWords,
    notificationLogs,
    wordPlans,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorite_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('learned_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'reminders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notification_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notification_logs', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('word_plans', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      required int timeMinutes,
      Value<RepeatType> repeatType,
      Value<DateTime?> onDate,
      Value<int?> dayOfWeek,
      Value<int?> dayOfMonth,
      Value<bool> enabled,
      Value<DateTime?> nextOccurrence,
      Value<DateTime> createdAt,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int> timeMinutes,
      Value<RepeatType> repeatType,
      Value<DateTime?> onDate,
      Value<int?> dayOfWeek,
      Value<int?> dayOfMonth,
      Value<bool> enabled,
      Value<DateTime?> nextOccurrence,
      Value<DateTime> createdAt,
    });

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, Reminder> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotificationLogsTable, List<NotificationLog>>
  _notificationLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notificationLogs,
    aliasName: 'reminders__id__notification_logs__reminder_id',
  );

  $$NotificationLogsTableProcessedTableManager get notificationLogsRefs {
    final manager = $$NotificationLogsTableTableManager(
      $_db,
      $_db.notificationLogs,
    ).filter((f) => f.reminderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _notificationLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RepeatType, RepeatType, String>
  get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get onDate => $composableBuilder(
    column: $table.onDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextOccurrence => $composableBuilder(
    column: $table.nextOccurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notificationLogsRefs(
    Expression<bool> Function($$NotificationLogsTableFilterComposer f) f,
  ) {
    final $$NotificationLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notificationLogs,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotificationLogsTableFilterComposer(
            $db: $db,
            $table: $db.notificationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatType => $composableBuilder(
    column: $table.repeatType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get onDate => $composableBuilder(
    column: $table.onDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextOccurrence => $composableBuilder(
    column: $table.nextOccurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeMinutes => $composableBuilder(
    column: $table.timeMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RepeatType, String> get repeatType =>
      $composableBuilder(
        column: $table.repeatType,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get onDate =>
      $composableBuilder(column: $table.onDate, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get nextOccurrence => $composableBuilder(
    column: $table.nextOccurrence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> notificationLogsRefs<T extends Object>(
    Expression<T> Function($$NotificationLogsTableAnnotationComposer a) f,
  ) {
    final $$NotificationLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notificationLogs,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotificationLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.notificationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, $$RemindersTableReferences),
          Reminder,
          PrefetchHooks Function({bool notificationLogsRefs})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> timeMinutes = const Value.absent(),
                Value<RepeatType> repeatType = const Value.absent(),
                Value<DateTime?> onDate = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> nextOccurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                description: description,
                timeMinutes: timeMinutes,
                repeatType: repeatType,
                onDate: onDate,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                enabled: enabled,
                nextOccurrence: nextOccurrence,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int timeMinutes,
                Value<RepeatType> repeatType = const Value.absent(),
                Value<DateTime?> onDate = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> nextOccurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                description: description,
                timeMinutes: timeMinutes,
                repeatType: repeatType,
                onDate: onDate,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                enabled: enabled,
                nextOccurrence: nextOccurrence,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notificationLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notificationLogsRefs) db.notificationLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notificationLogsRefs)
                    await $_getPrefetchedData<
                      Reminder,
                      $RemindersTable,
                      NotificationLog
                    >(
                      currentTable: table,
                      referencedTable: $$RemindersTableReferences
                          ._notificationLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RemindersTableReferences(
                            db,
                            table,
                            p0,
                          ).notificationLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.reminderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, $$RemindersTableReferences),
      Reminder,
      PrefetchHooks Function({bool notificationLogsRefs})
    >;
typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      required String externalId,
      Value<String> lang,
      required String term,
      Value<String?> article,
      required String translation,
      required String example,
      Value<String?> exampleTranslation,
      Value<String?> pronunciation,
      required String category,
      Value<String> difficulty,
      Value<String?> level,
      Value<String> topics,
      Value<DateTime> createdAt,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<int> id,
      Value<String> externalId,
      Value<String> lang,
      Value<String> term,
      Value<String?> article,
      Value<String> translation,
      Value<String> example,
      Value<String?> exampleTranslation,
      Value<String?> pronunciation,
      Value<String> category,
      Value<String> difficulty,
      Value<String?> level,
      Value<String> topics,
      Value<DateTime> createdAt,
    });

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FavoriteWordsTable, List<FavoriteWord>>
  _favoriteWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.favoriteWords,
    aliasName: 'words__id__favorite_words__word_id',
  );

  $$FavoriteWordsTableProcessedTableManager get favoriteWordsRefs {
    final manager = $$FavoriteWordsTableTableManager(
      $_db,
      $_db.favoriteWords,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoriteWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LearnedWordsTable, List<LearnedWord>>
  _learnedWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.learnedWords,
    aliasName: 'words__id__learned_words__word_id',
  );

  $$LearnedWordsTableProcessedTableManager get learnedWordsRefs {
    final manager = $$LearnedWordsTableTableManager(
      $_db,
      $_db.learnedWords,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_learnedWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotificationLogsTable, List<NotificationLog>>
  _notificationLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notificationLogs,
    aliasName: 'words__id__notification_logs__word_id',
  );

  $$NotificationLogsTableProcessedTableManager get notificationLogsRefs {
    final manager = $$NotificationLogsTableTableManager(
      $_db,
      $_db.notificationLogs,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _notificationLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WordPlansTable, List<WordPlan>>
  _wordPlansRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordPlans,
    aliasName: 'words__id__word_plans__word_id',
  );

  $$WordPlansTableProcessedTableManager get wordPlansRefs {
    final manager = $$WordPlansTableTableManager(
      $_db,
      $_db.wordPlans,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordPlansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get article => $composableBuilder(
    column: $table.article,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topics => $composableBuilder(
    column: $table.topics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> favoriteWordsRefs(
    Expression<bool> Function($$FavoriteWordsTableFilterComposer f) f,
  ) {
    final $$FavoriteWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteWordsTableFilterComposer(
            $db: $db,
            $table: $db.favoriteWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> learnedWordsRefs(
    Expression<bool> Function($$LearnedWordsTableFilterComposer f) f,
  ) {
    final $$LearnedWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learnedWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnedWordsTableFilterComposer(
            $db: $db,
            $table: $db.learnedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notificationLogsRefs(
    Expression<bool> Function($$NotificationLogsTableFilterComposer f) f,
  ) {
    final $$NotificationLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notificationLogs,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotificationLogsTableFilterComposer(
            $db: $db,
            $table: $db.notificationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wordPlansRefs(
    Expression<bool> Function($$WordPlansTableFilterComposer f) f,
  ) {
    final $$WordPlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordPlans,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordPlansTableFilterComposer(
            $db: $db,
            $table: $db.wordPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get article => $composableBuilder(
    column: $table.article,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topics => $composableBuilder(
    column: $table.topics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);

  GeneratedColumn<String> get exampleTranslation => $composableBuilder(
    column: $table.exampleTranslation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pronunciation => $composableBuilder(
    column: $table.pronunciation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get topics =>
      $composableBuilder(column: $table.topics, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> favoriteWordsRefs<T extends Object>(
    Expression<T> Function($$FavoriteWordsTableAnnotationComposer a) f,
  ) {
    final $$FavoriteWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favoriteWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoriteWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.favoriteWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> learnedWordsRefs<T extends Object>(
    Expression<T> Function($$LearnedWordsTableAnnotationComposer a) f,
  ) {
    final $$LearnedWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.learnedWords,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LearnedWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.learnedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notificationLogsRefs<T extends Object>(
    Expression<T> Function($$NotificationLogsTableAnnotationComposer a) f,
  ) {
    final $$NotificationLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notificationLogs,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotificationLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.notificationLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wordPlansRefs<T extends Object>(
    Expression<T> Function($$WordPlansTableAnnotationComposer a) f,
  ) {
    final $$WordPlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordPlans,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordPlansTableAnnotationComposer(
            $db: $db,
            $table: $db.wordPlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool favoriteWordsRefs,
            bool learnedWordsRefs,
            bool notificationLogsRefs,
            bool wordPlansRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String?> article = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String> example = const Value.absent(),
                Value<String?> exampleTranslation = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<String> topics = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                externalId: externalId,
                lang: lang,
                term: term,
                article: article,
                translation: translation,
                example: example,
                exampleTranslation: exampleTranslation,
                pronunciation: pronunciation,
                category: category,
                difficulty: difficulty,
                level: level,
                topics: topics,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String externalId,
                Value<String> lang = const Value.absent(),
                required String term,
                Value<String?> article = const Value.absent(),
                required String translation,
                required String example,
                Value<String?> exampleTranslation = const Value.absent(),
                Value<String?> pronunciation = const Value.absent(),
                required String category,
                Value<String> difficulty = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<String> topics = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                externalId: externalId,
                lang: lang,
                term: term,
                article: article,
                translation: translation,
                example: example,
                exampleTranslation: exampleTranslation,
                pronunciation: pronunciation,
                category: category,
                difficulty: difficulty,
                level: level,
                topics: topics,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WordsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                favoriteWordsRefs = false,
                learnedWordsRefs = false,
                notificationLogsRefs = false,
                wordPlansRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (favoriteWordsRefs) db.favoriteWords,
                    if (learnedWordsRefs) db.learnedWords,
                    if (notificationLogsRefs) db.notificationLogs,
                    if (wordPlansRefs) db.wordPlans,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (favoriteWordsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          FavoriteWord
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._favoriteWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).favoriteWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (learnedWordsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          LearnedWord
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._learnedWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).learnedWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notificationLogsRefs)
                        await $_getPrefetchedData<
                          Word,
                          $WordsTable,
                          NotificationLog
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._notificationLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).notificationLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (wordPlansRefs)
                        await $_getPrefetchedData<Word, $WordsTable, WordPlan>(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordPlansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordPlansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wordId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool favoriteWordsRefs,
        bool learnedWordsRefs,
        bool notificationLogsRefs,
        bool wordPlansRefs,
      })
    >;
typedef $$FavoriteWordsTableCreateCompanionBuilder =
    FavoriteWordsCompanion Function({
      Value<int> id,
      required int wordId,
      Value<DateTime> createdAt,
    });
typedef $$FavoriteWordsTableUpdateCompanionBuilder =
    FavoriteWordsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<DateTime> createdAt,
    });

final class $$FavoriteWordsTableReferences
    extends BaseReferences<_$AppDatabase, $FavoriteWordsTable, FavoriteWord> {
  $$FavoriteWordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('favorite_words__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoriteWordsTableFilterComposer
    extends Composer<_$AppDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoriteWordsTable> {
  $$FavoriteWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoriteWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoriteWordsTable,
          FavoriteWord,
          $$FavoriteWordsTableFilterComposer,
          $$FavoriteWordsTableOrderingComposer,
          $$FavoriteWordsTableAnnotationComposer,
          $$FavoriteWordsTableCreateCompanionBuilder,
          $$FavoriteWordsTableUpdateCompanionBuilder,
          (FavoriteWord, $$FavoriteWordsTableReferences),
          FavoriteWord,
          PrefetchHooks Function({bool wordId})
        > {
  $$FavoriteWordsTableTableManager(_$AppDatabase db, $FavoriteWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoriteWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoriteWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoriteWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteWordsCompanion(
                id: id,
                wordId: wordId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FavoriteWordsCompanion.insert(
                id: id,
                wordId: wordId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoriteWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$FavoriteWordsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$FavoriteWordsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FavoriteWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoriteWordsTable,
      FavoriteWord,
      $$FavoriteWordsTableFilterComposer,
      $$FavoriteWordsTableOrderingComposer,
      $$FavoriteWordsTableAnnotationComposer,
      $$FavoriteWordsTableCreateCompanionBuilder,
      $$FavoriteWordsTableUpdateCompanionBuilder,
      (FavoriteWord, $$FavoriteWordsTableReferences),
      FavoriteWord,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$LearnedWordsTableCreateCompanionBuilder =
    LearnedWordsCompanion Function({
      Value<int> id,
      required int wordId,
      Value<DateTime> firstSeenDate,
      Value<DateTime> lastShownDate,
      Value<int> timesShown,
    });
typedef $$LearnedWordsTableUpdateCompanionBuilder =
    LearnedWordsCompanion Function({
      Value<int> id,
      Value<int> wordId,
      Value<DateTime> firstSeenDate,
      Value<DateTime> lastShownDate,
      Value<int> timesShown,
    });

final class $$LearnedWordsTableReferences
    extends BaseReferences<_$AppDatabase, $LearnedWordsTable, LearnedWord> {
  $$LearnedWordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('learned_words__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LearnedWordsTableFilterComposer
    extends Composer<_$AppDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get firstSeenDate => $composableBuilder(
    column: $table.firstSeenDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastShownDate => $composableBuilder(
    column: $table.lastShownDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timesShown => $composableBuilder(
    column: $table.timesShown,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearnedWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get firstSeenDate => $composableBuilder(
    column: $table.firstSeenDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastShownDate => $composableBuilder(
    column: $table.lastShownDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timesShown => $composableBuilder(
    column: $table.timesShown,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearnedWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeenDate => $composableBuilder(
    column: $table.firstSeenDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastShownDate => $composableBuilder(
    column: $table.lastShownDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timesShown => $composableBuilder(
    column: $table.timesShown,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LearnedWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearnedWordsTable,
          LearnedWord,
          $$LearnedWordsTableFilterComposer,
          $$LearnedWordsTableOrderingComposer,
          $$LearnedWordsTableAnnotationComposer,
          $$LearnedWordsTableCreateCompanionBuilder,
          $$LearnedWordsTableUpdateCompanionBuilder,
          (LearnedWord, $$LearnedWordsTableReferences),
          LearnedWord,
          PrefetchHooks Function({bool wordId})
        > {
  $$LearnedWordsTableTableManager(_$AppDatabase db, $LearnedWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<DateTime> firstSeenDate = const Value.absent(),
                Value<DateTime> lastShownDate = const Value.absent(),
                Value<int> timesShown = const Value.absent(),
              }) => LearnedWordsCompanion(
                id: id,
                wordId: wordId,
                firstSeenDate: firstSeenDate,
                lastShownDate: lastShownDate,
                timesShown: timesShown,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                Value<DateTime> firstSeenDate = const Value.absent(),
                Value<DateTime> lastShownDate = const Value.absent(),
                Value<int> timesShown = const Value.absent(),
              }) => LearnedWordsCompanion.insert(
                id: id,
                wordId: wordId,
                firstSeenDate: firstSeenDate,
                lastShownDate: lastShownDate,
                timesShown: timesShown,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LearnedWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$LearnedWordsTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$LearnedWordsTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LearnedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearnedWordsTable,
      LearnedWord,
      $$LearnedWordsTableFilterComposer,
      $$LearnedWordsTableOrderingComposer,
      $$LearnedWordsTableAnnotationComposer,
      $$LearnedWordsTableCreateCompanionBuilder,
      $$LearnedWordsTableUpdateCompanionBuilder,
      (LearnedWord, $$LearnedWordsTableReferences),
      LearnedWord,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$NotificationLogsTableCreateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      required NotificationKind kind,
      Value<int?> reminderId,
      Value<int?> wordId,
      required DateTime scheduledAt,
      Value<DateTime?> deliveredAt,
    });
typedef $$NotificationLogsTableUpdateCompanionBuilder =
    NotificationLogsCompanion Function({
      Value<int> id,
      Value<NotificationKind> kind,
      Value<int?> reminderId,
      Value<int?> wordId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> deliveredAt,
    });

final class $$NotificationLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $NotificationLogsTable, NotificationLog> {
  $$NotificationLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias('notification_logs__reminder_id__reminders__id');

  $$RemindersTableProcessedTableManager? get reminderId {
    final $_column = $_itemColumn<int>('reminder_id');
    if ($_column == null) return null;
    final manager = $$RemindersTableTableManager(
      $_db,
      $_db.reminders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('notification_logs__word_id__words__id');

  $$WordsTableProcessedTableManager? get wordId {
    final $_column = $_itemColumn<int>('word_id');
    if ($_column == null) return null;
    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotificationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<NotificationKind, NotificationKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableOrderingComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationLogsTable> {
  $$NotificationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NotificationKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deliveredAt => $composableBuilder(
    column: $table.deliveredAt,
    builder: (column) => column,
  );

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotificationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationLogsTable,
          NotificationLog,
          $$NotificationLogsTableFilterComposer,
          $$NotificationLogsTableOrderingComposer,
          $$NotificationLogsTableAnnotationComposer,
          $$NotificationLogsTableCreateCompanionBuilder,
          $$NotificationLogsTableUpdateCompanionBuilder,
          (NotificationLog, $$NotificationLogsTableReferences),
          NotificationLog,
          PrefetchHooks Function({bool reminderId, bool wordId})
        > {
  $$NotificationLogsTableTableManager(
    _$AppDatabase db,
    $NotificationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotificationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotificationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<NotificationKind> kind = const Value.absent(),
                Value<int?> reminderId = const Value.absent(),
                Value<int?> wordId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> deliveredAt = const Value.absent(),
              }) => NotificationLogsCompanion(
                id: id,
                kind: kind,
                reminderId: reminderId,
                wordId: wordId,
                scheduledAt: scheduledAt,
                deliveredAt: deliveredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required NotificationKind kind,
                Value<int?> reminderId = const Value.absent(),
                Value<int?> wordId = const Value.absent(),
                required DateTime scheduledAt,
                Value<DateTime?> deliveredAt = const Value.absent(),
              }) => NotificationLogsCompanion.insert(
                id: id,
                kind: kind,
                reminderId: reminderId,
                wordId: wordId,
                scheduledAt: scheduledAt,
                deliveredAt: deliveredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotificationLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({reminderId = false, wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (reminderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.reminderId,
                                referencedTable:
                                    $$NotificationLogsTableReferences
                                        ._reminderIdTable(db),
                                referencedColumn:
                                    $$NotificationLogsTableReferences
                                        ._reminderIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable:
                                    $$NotificationLogsTableReferences
                                        ._wordIdTable(db),
                                referencedColumn:
                                    $$NotificationLogsTableReferences
                                        ._wordIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NotificationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationLogsTable,
      NotificationLog,
      $$NotificationLogsTableFilterComposer,
      $$NotificationLogsTableOrderingComposer,
      $$NotificationLogsTableAnnotationComposer,
      $$NotificationLogsTableCreateCompanionBuilder,
      $$NotificationLogsTableUpdateCompanionBuilder,
      (NotificationLog, $$NotificationLogsTableReferences),
      NotificationLog,
      PrefetchHooks Function({bool reminderId, bool wordId})
    >;
typedef $$WordPlansTableCreateCompanionBuilder =
    WordPlansCompanion Function({
      Value<int> id,
      required DateTime day,
      required int slot,
      required int wordId,
      Value<bool> recorded,
    });
typedef $$WordPlansTableUpdateCompanionBuilder =
    WordPlansCompanion Function({
      Value<int> id,
      Value<DateTime> day,
      Value<int> slot,
      Value<int> wordId,
      Value<bool> recorded,
    });

final class $$WordPlansTableReferences
    extends BaseReferences<_$AppDatabase, $WordPlansTable, WordPlan> {
  $$WordPlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_plans__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordPlansTableFilterComposer
    extends Composer<_$AppDatabase, $WordPlansTable> {
  $$WordPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recorded => $composableBuilder(
    column: $table.recorded,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $WordPlansTable> {
  $$WordPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recorded => $composableBuilder(
    column: $table.recorded,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordPlansTable> {
  $$WordPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<bool> get recorded =>
      $composableBuilder(column: $table.recorded, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordPlansTable,
          WordPlan,
          $$WordPlansTableFilterComposer,
          $$WordPlansTableOrderingComposer,
          $$WordPlansTableAnnotationComposer,
          $$WordPlansTableCreateCompanionBuilder,
          $$WordPlansTableUpdateCompanionBuilder,
          (WordPlan, $$WordPlansTableReferences),
          WordPlan,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordPlansTableTableManager(_$AppDatabase db, $WordPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> day = const Value.absent(),
                Value<int> slot = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<bool> recorded = const Value.absent(),
              }) => WordPlansCompanion(
                id: id,
                day: day,
                slot: slot,
                wordId: wordId,
                recorded: recorded,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime day,
                required int slot,
                required int wordId,
                Value<bool> recorded = const Value.absent(),
              }) => WordPlansCompanion.insert(
                id: id,
                day: day,
                slot: slot,
                wordId: wordId,
                recorded: recorded,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordPlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.wordId,
                                referencedTable: $$WordPlansTableReferences
                                    ._wordIdTable(db),
                                referencedColumn: $$WordPlansTableReferences
                                    ._wordIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordPlansTable,
      WordPlan,
      $$WordPlansTableFilterComposer,
      $$WordPlansTableOrderingComposer,
      $$WordPlansTableAnnotationComposer,
      $$WordPlansTableCreateCompanionBuilder,
      $$WordPlansTableUpdateCompanionBuilder,
      (WordPlan, $$WordPlansTableReferences),
      WordPlan,
      PrefetchHooks Function({bool wordId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$FavoriteWordsTableTableManager get favoriteWords =>
      $$FavoriteWordsTableTableManager(_db, _db.favoriteWords);
  $$LearnedWordsTableTableManager get learnedWords =>
      $$LearnedWordsTableTableManager(_db, _db.learnedWords);
  $$NotificationLogsTableTableManager get notificationLogs =>
      $$NotificationLogsTableTableManager(_db, _db.notificationLogs);
  $$WordPlansTableTableManager get wordPlans =>
      $$WordPlansTableTableManager(_db, _db.wordPlans);
}
