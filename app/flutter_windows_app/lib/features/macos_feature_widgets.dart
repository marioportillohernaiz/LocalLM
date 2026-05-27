import 'package:flutter/cupertino.dart';

import '../models/chat_response.dart';
import '../models/source.dart';

class MacPage extends StatelessWidget {
  const MacPage({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemGroupedBackground,
            border: Border(
              bottom: BorderSide(color: CupertinoColors.separator, width: 0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ],
    );
  }
}

class MacCard extends StatelessWidget {
  const MacCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.separator, width: 0),
      ),
      child: child,
    );
  }
}

class MacSectionTitle extends StatelessWidget {
  const MacSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class MacTextField extends StatelessWidget {
  const MacTextField({
    super.key,
    required this.controller,
    required this.placeholder,
  });

  final TextEditingController controller;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: macFieldDecoration(),
    );
  }
}

class MacPrimaryButton extends StatelessWidget {
  const MacPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: CupertinoColors.systemBlue,
      disabledColor: CupertinoColors.systemGrey4,
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class MacSecondaryButton extends StatelessWidget {
  const MacSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: CupertinoColors.tertiarySystemFill,
      disabledColor: CupertinoColors.systemGrey5,
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: destructive
              ? CupertinoColors.destructiveRed
              : CupertinoColors.systemBlue,
        ),
      ),
    );
  }
}

class MacLabelPicker extends StatelessWidget {
  const MacLabelPicker({
    super.key,
    required this.sources,
    required this.selectedLabels,
    required this.onChanged,
  });

  final List<Source> sources;
  final Set<String> selectedLabels;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = sources.map((source) => source.label).toSet().toList()
      ..sort();

    if (labels.isEmpty) {
      return const Text('No source labels available.');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final selected = selectedLabels.contains(label);
        return GestureDetector(
          onTap: () {
            final next = {...selectedLabels};
            if (selected) {
              next.remove(label);
            } else {
              next.add(label);
            }
            onChanged(next);
          },
          child: MacPill(label: label, selected: selected),
        );
      }).toList(),
    );
  }
}

class MacPill extends StatelessWidget {
  const MacPill({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? CupertinoColors.systemBlue
            : CupertinoColors.tertiarySystemFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? CupertinoColors.white : CupertinoColors.label,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class MacSourcesUsed extends StatelessWidget {
  const MacSourcesUsed({super.key, required this.sources});

  final List<ChatSource> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }

    return MacCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MacSectionTitle('Sources used'),
          const SizedBox(height: 10),
          ...sources.map(
            (source) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.fileName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    source.filePath,
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    source.chunkText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CupertinoColors.secondaryLabel,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MacLoading extends StatelessWidget {
  const MacLoading({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class MacEmptyState extends StatelessWidget {
  const MacEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: MacCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.doc_text_search,
                size: 34,
                color: CupertinoColors.secondaryLabel,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MacError extends StatelessWidget {
  const MacError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(color: CupertinoColors.destructiveRed),
      ),
    );
  }
}

BoxDecoration macFieldDecoration() {
  return BoxDecoration(
    color: CupertinoColors.secondarySystemGroupedBackground,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: CupertinoColors.separator, width: 0),
  );
}

String defaultMacSourceLabel(String path) {
  final normalized = path.replaceAll('\\', '/');
  final parts = normalized.split('/').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'Source';
  }
  return parts.last;
}

String formatMacDate(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}

String cleanMacError(Object exception) {
  return exception.toString().replaceFirst('Exception: ', '');
}

Future<void> showMacMessage(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
