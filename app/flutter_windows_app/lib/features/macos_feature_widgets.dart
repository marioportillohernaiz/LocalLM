import 'package:flutter/cupertino.dart';

import '../models/chat_response.dart';
import '../models/source.dart';
import '../theme/app_palette.dart';

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
            color: AppPalette.surface,
            border: Border(
              bottom: BorderSide(color: AppPalette.border),
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

class MacPageHeader extends StatelessWidget {
  const MacPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
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
        color: AppPalette.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppPalette.border),
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
      color: AppPalette.gunmetal,
      disabledColor: CupertinoColors.systemGrey4,
      borderRadius: BorderRadius.circular(8),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MacIconPrimaryButton extends StatelessWidget {
  const MacIconPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: AppPalette.gunmetal,
      disabledColor: CupertinoColors.systemGrey4,
      borderRadius: BorderRadius.circular(999),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: CupertinoColors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
              : AppPalette.gunmetal,
        ),
      ),
    );
  }
}

class MacIconSecondaryButton extends StatelessWidget {
  const MacIconSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.gunmetal),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        disabledColor: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(999),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppPalette.gunmetal),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppPalette.gunmetal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        color:
            selected ? AppPalette.gunmetal : CupertinoColors.tertiarySystemFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? CupertinoColors.white : AppPalette.text,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class MacModelPicker extends StatelessWidget {
  const MacModelPicker({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.loading,
    required this.onChanged,
    this.width = 220,
  });

  final List<String> models;
  final String? selectedModel;
  final bool loading;
  final ValueChanged<String?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CupertinoActivityIndicator(),
      );
    }

    final enabled = models.isNotEmpty;
    final value = selectedModel ?? (enabled ? models.first : 'No models');

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: enabled
          ? () async {
              final selected = await showCupertinoModalPopup<String>(
                context: context,
                builder: (context) {
                  return CupertinoActionSheet(
                    actions: [
                      for (final model in models)
                        CupertinoActionSheetAction(
                          onPressed: () => Navigator.of(context).pop(model),
                          child: Text(model),
                        ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  );
                },
              );
              if (selected != null) {
                onChanged(selected);
              }
            }
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppPalette.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppPalette.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? AppPalette.text : AppPalette.mutedText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 15,
              color: AppPalette.gunmetal,
            ),
          ],
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
    this.icon = CupertinoIcons.doc_text_search,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: MacCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 34,
                color: AppPalette.gunmetal,
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
    color: AppPalette.panel,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppPalette.border),
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
