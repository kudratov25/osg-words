/// Languages and pairs (docs/SPEC-v2.md section 1).
///
/// A pair is `source-target`: the user speaks [LanguagePair.source]
/// (translations + app interface) and learns [LanguagePair.target].
class Language {
  const Language({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
    required this.hasArticles,
  });

  final String code;

  /// The language's name written in that language ("O'zbekcha").
  final String nativeName;
  final String englishName;
  final String flag;

  /// Whether nouns carry an article worth highlighting (German der/die/das).
  final bool hasArticles;
}

const english = Language(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇬🇧', hasArticles: false);
const german = Language(code: 'de', nativeName: 'Deutsch', englishName: 'German', flag: '🇩🇪', hasArticles: true);
const uzbek = Language(code: 'uz', nativeName: "O'zbekcha", englishName: 'Uzbek', flag: '🇺🇿', hasArticles: false);
const russian = Language(code: 'ru', nativeName: 'Русский', englishName: 'Russian', flag: '🇷🇺', hasArticles: false);

const Map<String, Language> languages = {'en': english, 'de': german, 'uz': uzbek, 'ru': russian};

/// Languages words can be learned in.
const List<String> targetLanguages = ['de', 'en'];

/// Languages translations (and the app interface) can be in.
const List<String> sourceLanguages = ['en', 'uz', 'ru'];

Language languageOf(String code) => languages[code] ?? german;

/// Flag for a language code, e.g. a word's `lang`. Unknown codes get none.
String flagOf(String code) => languages[code]?.flag ?? '';

bool hasArticles(String code) => languages[code]?.hasArticles ?? false;

class LanguagePair {
  const LanguagePair(this.source, this.target);

  /// `en-de` -> LanguagePair('en', 'de'); null if malformed.
  static LanguagePair? tryParse(String? key) {
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length != 2) return null;
    return LanguagePair(parts[0], parts[1]);
  }

  final String source;
  final String target;

  String get key => '$source-$target';

  bool get isBuiltIn => this == builtInPair;

  @override
  bool operator ==(Object other) => other is LanguagePair && other.source == source && other.target == target;

  @override
  int get hashCode => Object.hash(source, target);

  @override
  String toString() => key;
}

/// Bundled with the app (assets/words_seed.json), works fully offline.
const builtInPair = LanguagePair('en', 'de');

/// A pair the server can deliver (GET /content/pairs), or the built-in one.
class AvailablePair {
  const AvailablePair({required this.pair, required this.words, this.version = 0});

  final LanguagePair pair;
  final int words;
  final int version;
}

/// Picks the interface/source language from the phone's language code:
/// supported -> itself, otherwise English.
String sourceForSystemLanguage(String languageCode) =>
    sourceLanguages.contains(languageCode) ? languageCode : 'en';

/// Fixed category keys (SPEC section 2), as stored on words.
const List<String> categoryKeys = [
  'Daily Life',
  'Work',
  'Food',
  'Common Verbs',
  'Travel',
  'Emotions',
  'Adjectives',
  'Time',
  'Money',
  'Health',
  'Weather',
  'Social',
  'Home',
  'Family',
  'Education',
  'Shopping',
  'Nature',
];
