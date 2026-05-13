import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_response.dart';

class ChatAnswerView extends StatelessWidget {
  const ChatAnswerView({super.key, required this.response});

  final ChatResponse response;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        Text('Question', style: textTheme.labelLarge),
        const SizedBox(height: 6),
        SelectableText(response.question, style: textTheme.titleMedium),
        const SizedBox(height: 20),
        Text('Answer', style: textTheme.labelLarge),
        const SizedBox(height: 6),
        MarkdownBody(
          data: response.answer,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: textTheme.bodyLarge,
            listBullet: textTheme.bodyLarge,
            h1: textTheme.headlineMedium,
            h2: textTheme.titleLarge,
            h3: textTheme.titleMedium,
            codeblockDecoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Sources', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final source in response.sources)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(
                source.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                source.filePath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SelectableText(source.chunkText),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
