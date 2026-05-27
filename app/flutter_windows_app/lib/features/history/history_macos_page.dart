import 'package:flutter/cupertino.dart';

import '../../models/chat_history_item.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../macos_feature_widgets.dart';

class MacHistoryPage extends StatefulWidget {
  const MacHistoryPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacHistoryPage> createState() => _MacHistoryPageState();
}

class _MacHistoryPageState extends State<MacHistoryPage> {
  List<ChatHistoryItem> history = [];
  int selectedIndex = 0;
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
        if (selectedIndex >= history.length) {
          selectedIndex = history.isEmpty ? 0 : history.length - 1;
        }
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
    final selectedItem = history.isEmpty
        ? null
        : history[selectedIndex.clamp(0, history.length - 1)];

    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Column(
            children: [
              MacPageHeader(
                title: 'History',
                subtitle: 'Return to previous local-file conversations.',
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: loading ? null : loadHistory,
                  child: const Icon(
                    CupertinoIcons.refresh,
                    color: AppPalette.text,
                  ),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MacError(message: error!),
                ),
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
                            padding: const EdgeInsets.all(12),
                            itemCount: history.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = history[index];
                              return _HistoryListItem(
                                item: item,
                                selected: index == selectedIndex,
                                onTap: () {
                                  setState(() {
                                    selectedIndex = index;
                                  });
                                },
                                onDelete: () => deleteItem(item),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: AppPalette.border),
        Expanded(
          child: Column(
            children: [
              Container(
                height: 58,
                width: double.infinity,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppPalette.border)),
                ),
                child: const Text(
                  'Conversation Preview',
                  style: TextStyle(
                    color: AppPalette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: selectedItem == null
                    ? const MacEmptyState(
                        icon: CupertinoIcons.clock,
                        title: 'No conversation selected',
                        message: 'Select a previous conversation.',
                      )
                    : MacConversationPreview(
                        question: selectedItem.question,
                        answer: selectedItem.answer,
                        sources: selectedItem.sources,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  const _HistoryListItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final ChatHistoryItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppPalette.dustGrey : AppPalette.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppPalette.gunmetal : AppPalette.border,
          ),
        ),
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
                      color: AppPalette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  onPressed: onDelete,
                  child: const Icon(
                    CupertinoIcons.delete,
                    color: AppPalette.gunmetal,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (item.labels.isNotEmpty) MacPill(label: item.labels.first),
                const Spacer(),
                Text(
                  formatMacDate(item.createdAt),
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
    );
  }
}
