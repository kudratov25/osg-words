// Regenerates assets/words_seed.json (the bundled, offline en-de pack)
// from the shared content file backend/content/de.json.
//
//   cd app && dart run tool/build_seed.dart [path/to/de.json]
//
// Output is the v2 word shape served by GET /content/words?source=en&target=de
// (term, lang, translation, example_translation, ...), English translations
// only. Words without an English translation are skipped.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = File(args.isNotEmpty ? args.first : '../backend/content/de.json');
  final output = File('assets/words_seed.json');
  final content = jsonDecode(input.readAsStringSync()) as Map<String, dynamic>;
  final target = content['target'] as String? ?? 'de';
  if (target != 'de') {
    stderr.writeln('Expected the German content file (target "de"), got "$target".');
    exit(1);
  }

  final words = <Map<String, dynamic>>[];
  final ids = <String>{};
  var skipped = 0;
  for (final w in (content['words'] as List).cast<Map<String, dynamic>>()) {
    final en = (w['translations'] as Map<String, dynamic>?)?['en'] as Map<String, dynamic>?;
    if (en == null || (en['translation'] as String?)?.isNotEmpty != true) {
      skipped++;
      continue;
    }
    final id = w['external_id'] as String;
    if (!ids.add(id)) {
      stderr.writeln('Duplicate external_id: $id');
      exit(1);
    }
    words.add({
      'external_id': id,
      'lang': target,
      'term': w['term'],
      'article': w['article'],
      'translation': en['translation'],
      'example': w['example'],
      'example_translation': en['example_translation'],
      'pronunciation': w['pronunciation'],
      'category': w['category'],
      'difficulty': w['difficulty'] ?? 'beginner',
    });
  }

  const encoder = JsonEncoder.withIndent('  ');
  output.writeAsStringSync('${encoder.convert({'version': 2, 'source': 'en', 'target': target, 'words': words})}\n');
  stdout.writeln('Wrote ${words.length} words to ${output.path}${skipped > 0 ? ' ($skipped without English skipped)' : ''}.');
}
