import 'package:flutter/material.dart';

import '../../models/chat_history_item.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
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
  final deletingItemIds = <int>{};
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

  Future<void> deleteHistoryItem(ChatHistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete conversation?'),
          content: Text(
            'This will permanently delete "${_previewQuestion(item.question)}".',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      deletingItemIds.add(item.id);
      errorMessage = null;
    });

    try {
      await widget.apiClient.deleteHistoryItem(item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        items = items.where((nextItem) => nextItem.id != item.id).toList();
        if (selectedItem?.id == item.id) {
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
          deletingItemIds.remove(item.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(
              loading: loading,
              onRefresh: loadHistory,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: 18),
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
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final selected = selectedItem?.id == item.id;
                                  return _HistoryCard(
                                    item: item,
                                    selected: selected,
                                    deleting: deletingItemIds.contains(item.id),
                                    onTap: () {
                                      setState(() {
                                        selectedItem = item;
                                      });
                                    },
                                    onDelete: () => deleteHistoryItem(item),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 900),
                                  child: selectedItem == null
                                      ? const _SelectHistoryItem()
                                      : ChatAnswerView(
                                          response:
                                              selectedItem!.toChatResponse(),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.loading,
    required this.onRefresh,
  });

  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Return to previous local-file conversations.',
                style: TextStyle(color: AppPalette.mutedText),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh history',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.selected,
    required this.deleting,
    required this.onTap,
    required this.onDelete,
  });

  final ChatHistoryItem item;
  final bool selected;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.frostedBlue : AppPalette.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
                  selected ? AppPalette.richCerulean : AppPalette.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.question,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        tooltip: 'Delete conversation',
                        padding: EdgeInsets.zero,
                        onPressed: deleting ? null : onDelete,
                        icon: deleting
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (item.labels.isNotEmpty) ...[
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final label in item.labels)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppPalette.border,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      _formatTimestamp(item.createdAt),
                      style: const TextStyle(
                        color: AppPalette.mutedText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppPalette.frostedBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.history_outlined),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select a conversation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a saved question to review its answer and sources.',
            style: TextStyle(color: AppPalette.mutedText),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppPalette.frostedBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          const SizedBox(height: 14),
          const Text(
            'No chat history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ask a question to save your first conversation.',
            style: TextStyle(color: AppPalette.mutedText),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
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

String _previewQuestion(String question) {
  const maxLength = 80;
  if (question.length <= maxLength) {
    return question;
  }
  return '${question.substring(0, maxLength)}...';
}
