import 'package:flutter/cupertino.dart';

import '../../models/chat_response.dart';
import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../../widgets/local_lm_logo.dart';
import '../macos_feature_widgets.dart';

class MacChatPage extends StatefulWidget {
  const MacChatPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacChatPage> createState() => _MacChatPageState();
}

class _MacChatPageState extends State<MacChatPage> {
  final questionController = TextEditingController();
  final selectedLabels = <String>{};
  List<Source> sources = [];
  List<String> models = [];
  String? selectedModel;
  ChatResponse? response;
  bool loadingSources = false;
  bool loadingModels = false;
  bool asking = false;
  String? error;

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
      error = null;
    });

    try {
      final loaded = await widget.apiClient.getSources();
      if (!mounted) return;
      setState(() {
        sources = loaded;
        selectedLabels.removeWhere(
          (label) => !loaded.any((source) => source.label == label),
        );
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
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
      final loadedModels = await widget.apiClient.getChatModels();
      if (!mounted) return;
      setState(() {
        models = loadedModels;
        if (selectedModel != null && !loadedModels.contains(selectedModel)) {
          selectedModel = null;
        }
        selectedModel ??= loadedModels.isEmpty ? null : loadedModels.first;
      });
    } catch (_) {
      if (!mounted) return;
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

  Future<void> refreshPage() async {
    await Future.wait([
      loadSources(),
      loadModels(),
    ]);
  }

  Future<void> ask() async {
    final question = questionController.text.trim();
    if (question.isEmpty || asking || models.isEmpty) return;

    setState(() {
      asking = true;
      error = null;
    });

    try {
      final answer = await widget.apiClient.ask(
        question: question,
        labels: selectedLabels.toList()..sort(),
        llmModel: selectedModel,
      );
      if (!mounted) return;
      setState(() {
        response = answer;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
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

    return Column(
      children: [
        MacPageHeader(
          title: 'Chat',
          subtitle: 'Ask questions across your indexed local sources.',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: loadingSources || loadingModels ? null : refreshPage,
            child: const Icon(CupertinoIcons.refresh, color: AppPalette.text),
          ),
        ),
        if (labels.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: _MacLabelSelector(
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
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: MacError(message: error!),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: response == null
                  ? const _EmptyChat()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        MacCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                response!.question,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                response!.answer,
                                style: const TextStyle(height: 1.35),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        MacSourcesUsed(sources: response!.sources),
                      ],
                    ),
            ),
          ),
        ),
        _MacInputDock(
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
    );
  }
}

class _MacLabelSelector extends StatelessWidget {
  const _MacLabelSelector({
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
          GestureDetector(
            onTap: () => onChanged(label, !selectedLabels.contains(label)),
            child:
                MacPill(label: label, selected: selectedLabels.contains(label)),
          ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LocalLmLogo(size: 96),
        SizedBox(height: 16),
        Text(
          'Ask questions across your indexed local sources.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppPalette.mutedText, fontSize: 15),
        ),
      ],
    );
  }
}

class _MacInputDock extends StatelessWidget {
  const _MacInputDock({
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
        color: AppPalette.surface,
        border: Border(top: BorderSide(color: AppPalette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Row(
            children: [
              Expanded(
                child: _MacComposer(
                  controller: controller,
                  asking: asking,
                  hasModels: models.isNotEmpty,
                  onAsk: onAsk,
                ),
              ),
              const SizedBox(width: 12),
              MacModelPicker(
                models: models,
                selectedModel: selectedModel,
                loading: loadingModels,
                width: 180,
                onChanged: onModelChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacComposer extends StatelessWidget {
  const _MacComposer({
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
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              placeholder: 'Ask a question about your sources...',
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(color: AppPalette.surface),
              onSubmitted: (_) {
                if (hasModels && !asking) {
                  onAsk();
                }
              },
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 34),
            color: AppPalette.gunmetal,
            disabledColor: AppPalette.dustGrey,
            borderRadius: BorderRadius.circular(8),
            onPressed: asking || !hasModels ? null : onAsk,
            child: asking
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Icon(
                    CupertinoIcons.paperplane_fill,
                    size: 18,
                    color: CupertinoColors.white,
                  ),
          ),
        ],
      ),
    );
  }
}
