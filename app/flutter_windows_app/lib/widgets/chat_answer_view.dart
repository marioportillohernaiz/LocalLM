import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_response.dart';
import 'local_lm_logo.dart';

class ChatAnswerView extends StatelessWidget {
  const ChatAnswerView({super.key, required this.response});

  final ChatResponse response;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      children: [
        _UserMessage(text: response.question),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AssistantAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: MarkdownBody(
                data: response.answer,
                selectable: true,
                styleSheet:
                    MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: textTheme.bodyLarge?.copyWith(
                    height: 1.55,
                    color: const Color(0xFF111827),
                  ),
                  listBullet: textTheme.bodyLarge?.copyWith(height: 1.55),
                  h1: textTheme.headlineMedium,
                  h2: textTheme.titleLarge,
                  h3: textTheme.titleMedium,
                  strong: const TextStyle(fontWeight: FontWeight.w800),
                  code: textTheme.bodyMedium?.copyWith(
                    backgroundColor: const Color(0xFFF3F4F6),
                    fontFamily: 'Consolas',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF10A37F), width: 4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (response.sources.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Text(
              'Sources',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          for (final source in response.sources)
            Padding(
              padding: const EdgeInsets.only(left: 46, bottom: 8),
              child: Card(
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined, size: 18),
                  ),
                  title: Text(
                    source.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    source.filePath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        source.chunkText,
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _UserMessage extends StatelessWidget {
  const _UserMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF111827),
                    height: 1.4,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 44,
      height: 44,
      child: LocalLmLogo(
        size: 44,
        color: Color(0xFF111827),
      ),
    );
  }
}
