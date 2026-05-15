import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/model_catalog_item.dart';
import '../../services/api_providers.dart';
import '../../theme/app_palette.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<ModelCatalogItem> models = [];
  final downloadingModels = <String>{};
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadModels());
  }

  Future<void> loadModels() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final nextModels = await ref.read(apiClientProvider).getModelCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        models = nextModels;
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
          loading = false;
        });
      }
    }
  }

  Future<void> downloadModel(ModelCatalogItem model) async {
    setState(() {
      downloadingModels.add(model.name);
      errorMessage = null;
    });

    try {
      await ref.read(apiClientProvider).pullModel(model.name);
      await loadModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${model.displayName} installed')),
        );
      }
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
          downloadingModels.remove(model.name);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedModels = {
      for (final size in ['Small', 'Medium', 'Large'])
        size: models.where((model) => model.sizeLabel == size).toList(),
    };

    return Container(
      width: double.infinity,
      color: AppPalette.surface,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(loading: loading, onRefresh: loadModels),
            const SizedBox(height: 18),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: errorMessage!),
            ],
            const SizedBox(height: 18),
            Expanded(
              child: loading && models.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: groupedModels.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = groupedModels.entries.elementAt(index);
                        return _ModelTierCard(
                          sizeLabel: entry.key,
                          models: entry.value,
                          downloadingModels: downloadingModels,
                          onDownload: downloadModel,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
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
                'Settings',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Install local models for chat answers and source indexing.',
                style: TextStyle(color: AppPalette.mutedText),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh models',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _ModelTierCard extends StatelessWidget {
  const _ModelTierCard({
    required this.sizeLabel,
    required this.models,
    required this.downloadingModels,
    required this.onDownload,
  });

  final String sizeLabel;
  final List<ModelCatalogItem> models;
  final Set<String> downloadingModels;
  final ValueChanged<ModelCatalogItem> onDownload;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (sizeLabel) {
      'Small' => 'Fastest and lowest memory usage.',
      'Medium' => 'Balanced local quality and performance.',
      'Large' => 'Highest preset quality, heavier downloads.',
      _ => 'Local model preset.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sizeLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppPalette.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final model in models) ...[
              _ModelRow(
                model: model,
                downloading: downloadingModels.contains(model.name),
                onDownload: () => onDownload(model),
              ),
              if (model != models.last) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.model,
    required this.downloading,
    required this.onDownload,
  });

  final ModelCatalogItem model;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final isChat = model.kind == 'chat';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color:
                    isChat ? AppPalette.frostedBlue : AppPalette.panel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isChat ? Icons.chat_bubble_outline : Icons.dataset_outlined,
                color: AppPalette.richCerulean,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        model.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      _Badge(label: isChat ? 'Chat' : 'Embedding'),
                      _Badge(label: model.approximateSize),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.description,
                    style: const TextStyle(color: AppPalette.mutedText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model.name,
                    style: const TextStyle(
                      color: AppPalette.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _ModelActionButton(
              installed: model.installed,
              downloading: downloading,
              onDownload: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppPalette.text),
      ),
    );
  }
}

class _ModelActionButton extends StatelessWidget {
  const _ModelActionButton({
    required this.installed,
    required this.downloading,
    required this.onDownload,
  });

  final bool installed;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    if (installed) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Installed'),
      );
    }

    return FilledButton.icon(
      onPressed: downloading ? null : onDownload,
      icon: downloading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined, size: 18),
      label: Text(downloading ? 'Downloading' : 'Download'),
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
