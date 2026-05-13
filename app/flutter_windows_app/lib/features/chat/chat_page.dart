import 'package:flutter/material.dart';

import '../../models/chat_response.dart';
import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../widgets/chat_answer_view.dart';

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
  ChatResponse? response;
  bool loadingSources = false;
  bool asking = false;
  String? errorMessage;

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

  Future<void> ask() async {
    final question = questionController.text.trim();
    if (question.isEmpty) {
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Chat',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh labels',
                onPressed: loadingSources ? null : loadSources,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (labels.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in labels)
                  FilterChip(
                    label: Text(label),
                    selected: selectedLabels.contains(label),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedLabels.add(label);
                        } else {
                          selectedLabels.remove(label);
                        }
                      });
                    },
                  ),
              ],
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: questionController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => ask(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: asking ? null : ask,
                icon: asking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(asking ? 'Asking' : 'Ask'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No answer',
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
