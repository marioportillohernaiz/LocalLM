import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class ModelDropdown extends StatelessWidget {
  const ModelDropdown({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.loading,
    required this.onChanged,
    this.tooltip = 'Model',
    this.maxWidth = 220,
  });

  final List<String> models;
  final String? selectedModel;
  final bool loading;
  final ValueChanged<String?> onChanged;
  final String tooltip;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Tooltip(
        message: models.isEmpty ? 'No compatible models available' : tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppPalette.panel,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppPalette.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedModel,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                disabledHint: const Text(
                  'No models',
                  overflow: TextOverflow.ellipsis,
                ),
                style: TextStyle(
                  color: models.isEmpty
                      ? AppPalette.mutedText
                      : AppPalette.text,
                  fontSize: 13,
                ),
                items: [
                  for (final model in models)
                    DropdownMenuItem(
                      value: model,
                      child: Text(model, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: models.isEmpty ? null : onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
