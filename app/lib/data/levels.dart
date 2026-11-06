/// CEFR levels and job-area topics (v2.1).
library;

/// Levels the user can pick, lowest first. Words of the picked level and
/// above are planned ("A2" -> A2+).
const List<String> cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1'];

const String defaultLevel = 'A1';

/// Job areas. A word with topics is only planned for users who picked one
/// of them; words without topics are general and planned for everyone.
const List<String> jobTopics = [
  'retail', 'it', 'medicine', 'hospitality', 'construction', 'logistics', 'office', 'care',
];

/// 0 (A1) .. 4 (C1). Words without a level (downloaded before 2.1) fall
/// back to their difficulty.
int levelRank(String? level, [String difficulty = 'beginner']) {
  final i = level == null ? -1 : cefrLevels.indexOf(level);
  if (i >= 0) return i;
  return switch (difficulty) { 'intermediate' => 2, 'advanced' => 3, _ => 0 };
}

/// Stored as comma-separated keys ("" = general word).
Set<String> parseTopics(String? stored) =>
    {for (final t in (stored ?? '').split(',')) if (t.isNotEmpty) t};

String encodeTopics(Iterable<String> topics) => (topics.toSet().toList()..sort()).join(',');
