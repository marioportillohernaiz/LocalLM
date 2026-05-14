import 'package:flutter/material.dart';

import '../../models/chat_response.dart';
import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../widgets/chat_answer_view.dart';
import '../../widgets/local_lm_logo.dart';
import '../../widgets/model_dropdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            _ChatHeader(
              loading: loadingSources,
              onRefresh: loadSources,
            ),
            const SizedBox(height: 22),
            if (labels.isNotEmpty)
              _LabelSelector(
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
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: response == null
                  ? const _EmptyChat()
                  : ChatAnswerView(response: response!),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _Composer(
                    controller: questionController,
                    asking: asking,
                    hasModels: models.isNotEmpty,
                    onAsk: ask,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 64,
                  child: Center(
                    child: ModelDropdown(
                      models: models,
                      selectedModel: selectedModel,
                      loading: loadingModels,
                      tooltip: 'Answer model',
                      onChanged: (model) {
                        setState(() {
                          selectedModel = model;
                        });
                      },
                    ),
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

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
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
                'Chat',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Ask questions across your indexed local sources.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh labels',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return const LocalLmLogo(
      size: 64,
      color: Color(0xFF111827),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels)
            FilterChip(
              label: Text(label),
              selected: selectedLabels.contains(label),
              showCheckmark: false,
              avatar: selectedLabels.contains(label)
                  ? const Icon(Icons.check, size: 16)
                  : null,
              selectedColor: const Color(0xFFE7F7F1),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              onSelected: (selected) => onChanged(label, selected),
            ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Ask anything about your local files',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) {
                  if (hasModels && !asking) {
                    onAsk();
                  }
                },
              ),
            ),
            SizedBox(
              width: 42,
              height: 42,
              child: IconButton.filled(
                tooltip: !hasModels
                    ? 'Install an answer model first'
                    : asking
                        ? 'Asking'
                        : 'Send',
                onPressed: asking || !hasModels ? null : onAsk,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                ),
                icon: asking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LogoMark(),
            SizedBox(height: 18),
            Text(
              'How can I help with your files?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Choose one or more source labels, then ask a question. Answers are generated from your indexed local documents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
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
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
