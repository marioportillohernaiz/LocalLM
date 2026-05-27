import 'package:flutter/material.dart';

import '../../models/chat_response.dart';
import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../../widgets/chat_answer_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/local_lm_logo.dart';
import '../../widgets/model_dropdown.dart';

class ChatWindowsPage extends StatefulWidget {
  const ChatWindowsPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ChatWindowsPage> createState() => _ChatWindowsPageState();
}

class _ChatWindowsPageState extends State<ChatWindowsPage> {
  final questionController = TextEditingController();
  final selectedLabels = <String>{};
  List<Source> sources = [];
  List<String> models = [];
  String? selectedModel;
  ChatResponse? response;
  bool loadingSources = false;
  bool loadingModels = false;
  bool asking = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSources();
    loadModels();
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  Future<void> loadSources() async {
    setState(() {
      loadingSources = true;
      errorMessage = null;
    });

    try {
      final nextSources = await widget.apiClient.getSources();
      if (!mounted) {
        return;
      }
      setState(() {
        sources = nextSources;
        selectedLabels.removeWhere(
          (label) => !nextSources.any((source) => source.label == label),
        );
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
          loadingSources = false;
        });
      }
    }
  }

  Future<void> loadModels() async {
    setState(() {
      loadingModels = true;
    });

    try {
      final nextModels = await widget.apiClient.getChatModels();
      if (!mounted) {
        return;
      }
      setState(() {
        models = nextModels;
        if (selectedModel != null && !nextModels.contains(selectedModel)) {
          selectedModel = null;
        }
        selectedModel ??= nextModels.isEmpty ? null : nextModels.first;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        models = [];
        selectedModel = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingModels = false;
        });
      }
    }
  }

  Future<void> ask() async {
    final question = questionController.text.trim();
    if (question.isEmpty || models.isEmpty) {
      return;
    }

    setState(() {
      asking = true;
      errorMessage = null;
    });

    try {
      final result = await widget.apiClient.ask(
        question: question,
        labels: selectedLabels.toList()..sort(),
        llmModel: selectedModel,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        response = result;
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
          asking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = sources.map((source) => source.label).toSet().toList()
      ..sort();

    return Container(
      color: AppPalette.surface,
      child: Column(
        children: [
          _ChatHeader(loading: loadingSources, onRefresh: loadSources),
          if (labels.isNotEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppPalette.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: _LabelSelector(
                labels: labels,
                selectedLabels: selectedLabels,
                onChanged: (label, selected) {
                  setState(() {
                    if (selected) {
                      selectedLabels.add(label);
                    } else {
                      selectedLabels.remove(label);
                    }
                  });
                },
              ),
            ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
              child: _ErrorBanner(message: errorMessage!),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768),
                child: response == null
                    ? const _EmptyChat()
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ChatAnswerView(response: response!),
                      ),
              ),
            ),
          ),
          _InputDock(
            controller: questionController,
            asking: asking,
            loadingModels: loadingModels,
            models: models,
            selectedModel: selectedModel,
            onModelChanged: (model) {
              setState(() {
                selectedModel = model;
              });
            },
            onAsk: ask,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.loading, required this.onRefresh});

  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ask questions across your indexed local sources.',
                  style: TextStyle(color: AppPalette.mutedText, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh labels',
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }
}

class _LabelSelector extends StatelessWidget {
  const _LabelSelector({
    required this.labels,
    required this.selectedLabels,
    required this.onChanged,
  });

  final List<String> labels;
  final Set<String> selectedLabels;
  final void Function(String label, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          FilterChip(
            label: Text(label),
            selected: selectedLabels.contains(label),
            showCheckmark: false,
            avatar: selectedLabels.contains(label)
                ? const Icon(Icons.check, size: 14)
                : null,
            selectedColor: AppPalette.dustGrey,
            side: const BorderSide(color: AppPalette.border),
            labelStyle: const TextStyle(fontSize: 13),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onSelected: (selected) => onChanged(label, selected),
          ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: LocalLmLogo(size: 96),
      subtitle: 'Ask questions across your indexed local sources.',
    );
  }
}

class _InputDock extends StatelessWidget {
  const _InputDock({
    required this.controller,
    required this.asking,
    required this.loadingModels,
    required this.models,
    required this.selectedModel,
    required this.onModelChanged,
    required this.onAsk,
  });

  final TextEditingController controller;
  final bool asking;
  final bool loadingModels;
  final List<String> models;
  final String? selectedModel;
  final ValueChanged<String?> onModelChanged;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _Composer(
                  controller: controller,
                  asking: asking,
                  hasModels: models.isNotEmpty,
                  onAsk: onAsk,
                ),
              ),
              const SizedBox(width: 12),
              ModelDropdown(
                models: models,
                selectedModel: selectedModel,
                loading: loadingModels,
                tooltip: 'Answer model',
                maxWidth: 180,
                onChanged: onModelChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.asking,
    required this.hasModels,
    required this.onAsk,
  });

  final TextEditingController controller;
  final bool asking;
  final bool hasModels;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Ask a question about your sources...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
                onSubmitted: (_) {
                  if (hasModels && !asking) {
                    onAsk();
                  }
                },
              ),
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: IconButton.filled(
                tooltip: !hasModels
                    ? 'Install an answer model first'
                    : asking
                        ? 'Asking'
                        : 'Send',
                onPressed: asking || !hasModels ? null : onAsk,
                style: IconButton.styleFrom(
                  backgroundColor: AppPalette.gunmetal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppPalette.dustGrey,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: asking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 17),
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
