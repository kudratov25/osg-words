import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../services/content_sync.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/refresh_words.dart';
import '../widgets/word_card.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late Future<_VocabData> _future;

  /// Reloads when fixed/new words arrive from the server.
  late final ContentSync _sync;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _sync = context.read<ContentSync>()..addListener(_reload);
  }

  @override
  void dispose() {
    _sync.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _future = _load());
  }

  Future<void> _pullToRefresh() async {
    await refreshWordsFromServer(context);
    _reload();
  }

  Future<_VocabData> _load() async {
    final repo = context.read<Repository>();
    return _VocabData(
      today: await repo.assignTodaysWords(),
      yesterday: await repo.yesterdaysWords(),
      favorites: await repo.favoriteWords(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_VocabData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final l = context.l10n;
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  l.vocabTitle,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TabBar(
                indicatorColor: AppColors.accent,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  Tab(text: l.tabToday),
                  Tab(text: l.tabYesterday),
                  Tab(text: l.tabFavorites),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _WordList(words: data.today, emptyText: l.vocabNoToday, onRefresh: _pullToRefresh),
                    _WordList(words: data.yesterday, emptyText: l.vocabNoYesterday, onRefresh: _pullToRefresh),
                    _WordList(words: data.favorites, emptyText: l.vocabNoFavorites, onRefresh: _pullToRefresh),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VocabData {
  _VocabData({required this.today, required this.yesterday, required this.favorites});
  final List<Word> today;
  final List<Word> yesterday;
  final List<Word> favorites;
}

class _WordList extends StatelessWidget {
  const _WordList({required this.words, required this.emptyText, required this.onRefresh});
  final List<Word> words;
  final String emptyText;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    // Always scrollable so pull-to-refresh also works on an empty tab.
    final Widget list = words.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              GlassContainer(
                child: Text(emptyText, style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          )
        : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: words.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => WordCard(word: words[i]),
          );
    return RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}
