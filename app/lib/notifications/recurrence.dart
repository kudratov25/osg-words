import '../data/db/app_database.dart';
import '../data/db/tables.dart';

/// Pure date math for reminders. Everything is derived from one rule,
/// [occursOn], so "does it fire on this day" and "when does it fire next"
/// can never disagree.

/// Whether [reminder] fires on the calendar date [day] (time ignored).
///
/// Monthly reminders on a day the month doesn't have (e.g. the 31st in
/// April, or the 30th in February) fire on that month's last day instead
/// of being skipped or spilling into the next month.
bool occursOn(Reminder reminder, DateTime day) {
  switch (reminder.repeatType) {
    case RepeatType.once:
      final date = reminder.onDate;
      return date != null && _sameDay(date, day);
    case RepeatType.daily:
      return true;
    case RepeatType.weekdays:
      return day.weekday != DateTime.saturday && day.weekday != DateTime.sunday;
    case RepeatType.weekly:
      return day.weekday == (reminder.dayOfWeek ?? DateTime.monday);
    case RepeatType.monthly:
      final target = (reminder.dayOfMonth ?? 1).clamp(1, 31);
      final lastDay = daysInMonth(day.year, day.month);
      return day.day == (target > lastDay ? lastDay : target);
  }
}

/// Fire time of [reminder] on [day] (local time).
DateTime fireTimeOn(Reminder reminder, DateTime day) =>
    DateTime(day.year, day.month, day.day, reminder.timeMinutes ~/ 60, reminder.timeMinutes % 60);

/// Every fire time of [reminder] strictly after [from] and before [until].
List<DateTime> occurrencesBetween(Reminder reminder, DateTime from, DateTime until) {
  final result = <DateTime>[];
  var day = DateTime(from.year, from.month, from.day);
  while (day.isBefore(until)) {
    if (occursOn(reminder, day)) {
      final at = fireTimeOn(reminder, day);
      if (at.isAfter(from) && at.isBefore(until)) result.add(at);
    }
    day = DateTime(day.year, day.month, day.day + 1);
  }
  return result;
}

/// The next fire time strictly after [from], or null if there is none
/// (a "once" reminder whose time has passed). Looks up to ~13 months
/// ahead, which covers every repeat type.
DateTime? computeNextOccurrence(Reminder reminder, DateTime from) {
  final until = DateTime(from.year, from.month + 13, from.day);
  final all = occurrencesBetween(reminder, from, until);
  return all.isEmpty ? null : all.first;
}

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
