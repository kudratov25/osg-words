import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/content_sync.dart';

/// Pull-to-refresh: checks the server for new/fixed words right away
/// (ignoring the automatic-check throttle) and tells the user the outcome.
/// When words were merged, [ContentSync] notifies its listeners: open
/// screens reload, notifications and the widget are rebuilt.
Future<void> refreshWordsFromServer(BuildContext context) async {
  final sync = context.read<ContentSync>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = context.l10n;
  // Offline builds (no server configured) have nothing to check.
  if (sync.baseUrl.isEmpty) return;
  final result = await sync.sync(force: true);
  final text = switch (result) {
    SyncResult.merged => l.refreshUpdated,
    SyncResult.upToDate || SyncResult.skipped => l.refreshUpToDate,
    SyncResult.failed => l.refreshFailed,
  };
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
