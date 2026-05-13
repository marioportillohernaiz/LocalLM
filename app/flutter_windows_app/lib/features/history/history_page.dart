import 'package:flutter/material.dart';

import '../../models/chat_history_item.dart';
import '../../services/api_client.dart';
import '../../widgets/chat_answer_view.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ChatHistoryItem> items = [];
  ChatHistoryItem? selectedItem;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final nextItems = await widget.apiClient.getHistory();
      if (!mounted) {
        return;
      }
      setState(() {
        items = nextItems;
        if (selectedItem != null &&
            !nextItems.any((item) => item.id == selectedItem!.id)) {
          selectedItem = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'History',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh history',
                onPressed: loading ? null : loadHistory,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const _EmptyHistory()
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 360,
                            child: ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final selected = selectedItem?.id == item.id;
                                return _HistoryCard(
                                  item: item,
                                  selected: selected,
                                  onTap: () {
                                    setState(() {
                                      selectedItem = item;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const VerticalDivider(width: 32),
                          Expanded(
                            child: selectedItem == null
                                ? const _SelectHistoryItem()
                                : ChatAnswerView(
                                    response: selectedItem!.toChatResponse(),
                                  ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final ChatHistoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: selected ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          item.question,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_formatTimestamp(item.createdAt)}'
          '${item.labels.isEmpty ? '' : '\n${item.labels.join(', ')}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SelectHistoryItem extends StatelessWidget {
  const _SelectHistoryItem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Select a question',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No chat history',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
