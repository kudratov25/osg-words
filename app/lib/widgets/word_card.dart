import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/languages.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';
import 'report_sheet.dart';

/// Colours for German articles (only languages with articles get them).
Color? articleColor(String lang, String? article) {
  if (!hasArticles(lang) || article == null) return null;
  return switch (article.toLowerCase()) {
    'der' => const Color(0xFF7FB3FF),
    'die' => const Color(0xFFFF8FA8),
    'das' => const Color(0xFF7FE0B5),
    _ => null,
  };
}

/// "🇩🇪 der Schlüssel" with the article coloured where the language has
/// articles. Plain text otherwise.
class WordTitle extends StatelessWidget {
  const WordTitle({required this.word, this.style, super.key});

  final Word word;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
    final flag = flagOf(word.lang);
    final article = word.article;
    final color = articleColor(word.lang, article);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          if (flag.isNotEmpty) TextSpan(text: '$flag '),
          if (article != null && article.isNotEmpty) TextSpan(text: '$article ', style: TextStyle(color: color)),
          TextSpan(text: word.term),
        ],
      ),
    );
  }
}

class WordCard extends StatelessWidget {
  const WordCard({required this.word, this.showFavorite = true, this.showReport = true, super.key});

  final Word word;
  final bool showFavorite;
  final bool showReport;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final exampleTranslation = word.exampleTranslation;
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Padding(padding: const EdgeInsets.only(top: 8), child: WordTitle(word: word))),
              if (showFavorite) _FavoriteButton(wordId: word.id),
            ],
          ),
          const SizedBox(height: 6),
          Text(word.translation, style: const TextStyle(fontSize: 15, color: AppColors.accent)),
          const SizedBox(height: 10),
          Text('"${word.example}"',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          if (exampleTranslation != null && exampleTranslation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              exampleTranslation,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary.withValues(alpha: 0.75)),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(categoryLabel(l, word.category).toUpperCase(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1)),
              ),
              if (showReport)
                IconButton(
                  tooltip: l.reportTitle,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  icon: const Icon(Icons.outlined_flag_rounded, color: AppColors.textSecondary),
                  onPressed: () => showReportSheet(context, word),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.wordId});
  final int wordId;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool? _favorite;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<Repository>();
    final fav = await repo.isFavorite(widget.wordId);
    if (mounted) setState(() => _favorite = fav);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    return IconButton(
      icon: Icon(
        _favorite == true ? Icons.star_rounded : Icons.star_border_rounded,
        color: _favorite == true ? AppColors.accent : AppColors.textSecondary,
      ),
      onPressed: () async {
        await repo.toggleFavorite(widget.wordId);
        _load();
      },
    );
  }
}
