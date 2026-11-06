import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/languages.dart';
import '../l10n/l10n.dart';
import '../services/feedback_api.dart';
import '../services/language_settings.dart';
import '../theme/glass_theme.dart';
import 'word_card.dart' show WordTitle;

/// Shared look for the app's bottom sheets: solid panel + drag handle.
Future<T?> showGlassSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundGradientEnd,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      ),
    );

/// "Report a mistake": 4 kinds + optional note -> POST /feedback/word-issue.
Future<void> showReportSheet(BuildContext context, Word word) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = context.l10n;
  final result = await showGlassSheet<ReportResult>(context, (_) => _ReportForm(word: word));
  if (result == null || messenger == null) return;
  final text = switch (result) {
    ReportResult.sent => l.reportThanks,
    ReportResult.offline => l.reportOffline,
    ReportResult.tooMany => l.reportTooMany,
    ReportResult.failed => l.genericError,
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.word});
  final Word word;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  WordIssueKind? _kind;
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final kind = _kind;
    if (kind == null) return;
    setState(() => _sending = true);
    final source = context.read<LanguageSettings>().pair.source;
    final result = await context.read<FeedbackApi>().reportWordIssue(
          externalId: widget.word.externalId,
          pair: LanguagePair(source, widget.word.lang),
          kind: kind,
          note: _note.text,
        );
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final kinds = [
      (WordIssueKind.wrongTranslation, l.reportKindTranslation),
      if (hasArticles(widget.word.lang)) (WordIssueKind.wrongArticle, l.reportKindArticle),
      (WordIssueKind.wrongExample, l.reportKindExample),
      (WordIssueKind.other, l.reportKindOther),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.reportTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          WordTitle(word: widget.word, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (kind, label) in kinds)
                ChoiceChip(
                  label: Text(label),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                  selectedColor: AppColors.accent.withValues(alpha: 0.3),
                  backgroundColor: AppColors.glassFill,
                  labelStyle: TextStyle(color: _kind == kind ? AppColors.textPrimary : AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLength: FeedbackApi.maxNoteLength,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l.reportNoteHint,
              filled: true,
              fillColor: AppColors.glassFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _kind == null || _sending ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _sending
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.reportSend),
          ),
        ],
      ),
    );
  }
}
