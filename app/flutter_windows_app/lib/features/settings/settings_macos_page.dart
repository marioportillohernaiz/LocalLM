import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/model_catalog_item.dart';
import '../../services/api_providers.dart';
import '../../theme/app_palette.dart';
import '../macos_feature_widgets.dart';

class MacSettingsPage extends ConsumerStatefulWidget {
  const MacSettingsPage({super.key});

  @override
  ConsumerState<MacSettingsPage> createState() => _MacSettingsPageState();
}

class _MacSettingsPageState extends ConsumerState<MacSettingsPage> {
  List<ModelCatalogItem> models = [];
  final downloadingModels = <String>{};
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadModels());
  }

  Future<void> loadModels() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final loadedModels = await ref.read(apiClientProvider).getModelCatalog();
      if (!mounted) return;
      setState(() {
        models = loadedModels;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
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
      error = null;
    });

    try {
      await ref.read(apiClientProvider).pullModel(model.name);
      await loadModels();
      if (mounted) {
        await showMacMessage(
          context,
          title: 'Model installed',
          message: '${model.displayName} is ready to use.',
        );
      }
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
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

    return MacPage(
      title: 'Settings',
      subtitle: 'Install local models for chat answers and source indexing.',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: loading ? null : loadModels,
        child: const Icon(CupertinoIcons.refresh, color: AppPalette.text),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null) ...[
            MacError(message: error!),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: loading && models.isEmpty
                ? const MacLoading(label: 'Loading models')
                : ListView.separated(
                    itemCount: groupedModels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final entry = groupedModels.entries.elementAt(index);
                      return _MacModelTier(
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
    );
  }
}

class _MacModelTier extends StatelessWidget {
  const _MacModelTier({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sizeLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppPalette.mutedText),
        ),
        const SizedBox(height: 16),
        for (final model in models) ...[
          _MacModelRow(
            model: model,
            downloading: downloadingModels.contains(model.name),
            onDownload: () => onDownload(model),
          ),
          if (model != models.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MacModelRow extends StatelessWidget {
  const _MacModelRow({
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

    return MacCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isChat ? AppPalette.dustGrey : AppPalette.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isChat
                  ? CupertinoIcons.chat_bubble_text
                  : CupertinoIcons.cube_box,
              color: AppPalette.gunmetal,
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
                    MacPill(label: isChat ? 'Chat' : 'Embedding'),
                    MacPill(label: model.approximateSize),
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
          _MacModelActionButton(
            installed: model.installed,
            downloading: downloading,
            onDownload: onDownload,
          ),
        ],
      ),
    );
  }
}

class _MacModelActionButton extends StatelessWidget {
  const _MacModelActionButton({
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
      return const MacSecondaryButton(label: 'Installed', onPressed: null);
    }

    return MacPrimaryButton(
      label: downloading ? 'Downloading' : 'Download',
      onPressed: downloading ? null : onDownload,
    );
  }
}
