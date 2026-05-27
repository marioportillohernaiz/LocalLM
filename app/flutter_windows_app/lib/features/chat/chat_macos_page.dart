import 'package:flutter/cupertino.dart';

import '../../models/chat_response.dart';
import '../../models/source.dart';
import '../../services/api_client.dart';
import '../macos_feature_widgets.dart';

class MacChatPage extends StatefulWidget {
  const MacChatPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacChatPage> createState() => _MacChatPageState();
}

class _MacChatPageState extends State<MacChatPage> {
  final questionController = TextEditingController();
  List<Source> sources = [];
  Set<String> selectedLabels = {};
  ChatResponse? response;
  bool loadingSources = true;
  bool asking = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSources();
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
        selectedLabels = selectedLabels
            .where((label) => loaded.any((source) => source.label == label))
            .toSet();
        loadingSources = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
        loadingSources = false;
      });
    }
  }

  Future<void> ask() async {
    final question = questionController.text.trim();
    if (question.isEmpty || asking) return;

    setState(() {
      asking = true;
      error = null;
    });

    try {
      final answer = await widget.apiClient.ask(
        question: question,
        labels: selectedLabels.toList(),
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
    return MacPage(
      title: 'Chat',
      trailing: MacSecondaryButton(label: 'Refresh', onPressed: loadSources),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MacCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MacSectionTitle('Ask your files'),
                const SizedBox(height: 10),
                if (loadingSources)
                  const MacLoading(label: 'Loading labels')
                else
                  MacLabelPicker(
                    sources: sources,
                    selectedLabels: selectedLabels,
                    onChanged: (labels) {
                      setState(() {
                        selectedLabels = labels;
                      });
                    },
                  ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: questionController,
                  placeholder: 'Ask a question',
                  minLines: 2,
                  maxLines: 5,
                  padding: const EdgeInsets.all(12),
                  decoration: macFieldDecoration(),
                  onSubmitted: (_) => ask(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: MacPrimaryButton(
                    label: asking ? 'Asking...' : 'Ask',
                    onPressed: asking ? null : ask,
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            MacError(message: error!),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: response == null
                ? const MacEmptyState(
                    icon: CupertinoIcons.chat_bubble_2,
                    title: 'No answer yet',
                    message: 'Choose labels and ask a question.',
                  )
                : ListView(
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
        ],
      ),
    );
  }
}
