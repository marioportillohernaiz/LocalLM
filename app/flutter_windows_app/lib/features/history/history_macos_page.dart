import 'package:flutter/cupertino.dart';

import '../../models/chat_history_item.dart';
import '../../services/api_client.dart';
import '../macos_feature_widgets.dart';

class MacHistoryPage extends StatefulWidget {
  const MacHistoryPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacHistoryPage> createState() => _MacHistoryPageState();
}

class _MacHistoryPageState extends State<MacHistoryPage> {
  List<ChatHistoryItem> history = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final loaded = await widget.apiClient.getHistory();
      if (!mounted) return;
      setState(() {
        history = loaded;
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
        loading = false;
      });
    }
  }

  Future<void> deleteItem(ChatHistoryItem item) async {
    try {
      await widget.apiClient.deleteHistoryItem(item.id);
      await loadHistory();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacPage(
      title: 'History',
      trailing: MacSecondaryButton(label: 'Refresh', onPressed: loadHistory),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            MacError(message: error!),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: loading
                ? const MacLoading(label: 'Loading history')
                : history.isEmpty
                    ? const MacEmptyState(
                        icon: CupertinoIcons.clock,
                        title: 'No history yet',
                        message: 'Ask questions to build your history.',
                      )
                    : ListView.separated(
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          return MacCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.question,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    MacSecondaryButton(
                                      label: 'Delete',
                                      destructive: true,
                                      onPressed: () => deleteItem(item),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatMacDate(item.createdAt),
                                  style: const TextStyle(
                                    color: CupertinoColors.secondaryLabel,
                                    fontSize: 12,
                                  ),
                                ),
                                if (item.labels.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: item.labels
                                        .map((label) => MacPill(label: label))
                                        .toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Text(
                                  item.answer,
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(height: 1.35),
                                ),
                                const SizedBox(height: 12),
                                MacSourcesUsed(sources: item.sources),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
