import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/model_dropdown.dart';

class SourcesWindowsPage extends StatefulWidget {
  const SourcesWindowsPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<SourcesWindowsPage> createState() => _SourcesWindowsPageState();
}

class _SourcesWindowsPageState extends State<SourcesWindowsPage> {
  final labelController = TextEditingController();
  final indexingSourceIds = <int>{};
  List<Source> sources = [];
  List<String> models = [];
  String? selectedEmbeddingModel;
  bool loading = false;
  bool loadingModels = false;
  String? activeIndexingLabel;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSources();
    loadModels();
  }

  @override
  void dispose() {
    labelController.dispose();
    super.dispose();
  }

  Future<void> loadSources() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final nextSources = await widget.apiClient.getSources();
      if (!mounted) {
        return;
      }
      setState(() {
        sources = nextSources;
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

  Future<void> loadModels() async {
    setState(() {
      loadingModels = true;
    });

    try {
      final nextModels = await widget.apiClient.getEmbeddingModels();
      if (!mounted) {
        return;
      }
      setState(() {
        models = nextModels;
        if (selectedEmbeddingModel != null &&
            !nextModels.contains(selectedEmbeddingModel)) {
          selectedEmbeddingModel = null;
        }
        selectedEmbeddingModel ??= nextModels.isEmpty ? null : nextModels.first;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        models = [];
        selectedEmbeddingModel = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          loadingModels = false;
        });
      }
    }
  }

  Future<void> addFolder() async {
    if (models.isEmpty) {
      return;
    }

    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) {
      return;
    }
    await addSource(path);
  }

  Future<void> addFile() async {
    if (models.isEmpty) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'md', 'pdf', 'docx'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) {
      return;
    }
    await addSource(path);
  }

  Future<void> addSource(String path) async {
    final label = labelController.text.trim();
    if (label.isEmpty) {
      setState(() {
        errorMessage = 'Label is required';
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final source = await widget.apiClient.addSource(label: label, path: path);
      if (mounted) {
        setState(() {
          activeIndexingLabel = source.label;
        });
      }
      final result = await widget.apiClient.indexSource(
        source.id,
        embeddingModel: selectedEmbeddingModel,
      );
      await loadSources();
      labelController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.summary)));
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
          loading = false;
          activeIndexingLabel = null;
        });
      }
    }
  }

  Future<void> reindex(Source source) async {
    setState(() {
      indexingSourceIds.add(source.id);
      activeIndexingLabel = source.label;
      errorMessage = null;
    });

    try {
      final result = await widget.apiClient.indexSource(
        source.id,
        embeddingModel: selectedEmbeddingModel,
      );
      await loadSources();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.summary)));
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
          indexingSourceIds.remove(source.id);
          if (indexingSourceIds.isEmpty) {
            activeIndexingLabel = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageHeader(
            title: 'Sources',
            subtitle: 'Connect local folders and files for retrieval.',
            loading: loading,
            onRefresh: loadSources,
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppPalette.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            child: _AddSourcePanel(
              controller: labelController,
              loading: loading,
              onAddFolder: addFolder,
              onAddFile: addFile,
              models: models,
              selectedModel: selectedEmbeddingModel,
              loadingModels: loadingModels,
              hasModels: models.isNotEmpty,
              onModelChanged: (model) {
                setState(() {
                  selectedEmbeddingModel = model;
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                if (errorMessage != null) ...[
                  _ErrorBanner(message: errorMessage!),
                ],
                if (activeIndexingLabel != null) ...[
                  const SizedBox(height: 16),
                  _IndexingBanner(label: activeIndexingLabel!),
                ],
                const SizedBox(height: 24),
                if (loading && sources.isEmpty)
                  const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sources.isEmpty)
                  const SizedBox(height: 360, child: _EmptySources())
                else
                  ...sources.map((source) {
                    final indexing = indexingSourceIds.contains(source.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SourceCard(
                        source: source,
                        indexing: indexing,
                        onReindex: indexing ? null : () => reindex(source),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AddSourcePanel extends StatelessWidget {
  const _AddSourcePanel({
    required this.controller,
    required this.loading,
    required this.onAddFolder,
    required this.onAddFile,
    required this.models,
    required this.selectedModel,
    required this.loadingModels,
    required this.hasModels,
    required this.onModelChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onAddFolder;
  final VoidCallback onAddFile;
  final List<String> models;
  final String? selectedModel;
  final bool loadingModels;
  final bool hasModels;
  final ValueChanged<String?> onModelChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Source label',
                    hintText: 'Research, notes, project docs',
                  ),
                  onSubmitted: (_) {
                    if (hasModels && !loading) {
                      onAddFolder();
                    }
                  },
                ),
              ),
              FilledButton.icon(
                onPressed: loading || !hasModels ? null : onAddFolder,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Add folder'),
              ),
              OutlinedButton.icon(
                onPressed: loading || !hasModels ? null : onAddFile,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add file'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.text,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ModelDropdown(
          models: models,
          selectedModel: selectedModel,
          loading: loadingModels,
          tooltip: 'Embedding model',
          maxWidth: 240,
          onChanged: onModelChanged,
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.indexing,
    required this.onReindex,
  });

  final Source source;
  final bool indexing;
  final VoidCallback? onReindex;

  @override
  Widget build(BuildContext context) {
    final lastIndexed = source.lastIndexedAt == null
        ? 'Not indexed'
        : 'Indexed ${_formatTimestamp(source.lastIndexedAt!)}';

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.dustGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder_open_outlined),
        ),
        title: Text(
          source.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${source.path}\n$lastIndexed',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppPalette.mutedText, height: 1.35),
        ),
        trailing: IconButton.filledTonal(
          tooltip: 'Re-index',
          onPressed: onReindex,
          style: IconButton.styleFrom(
            backgroundColor: AppPalette.alabasterGrey,
            foregroundColor: AppPalette.gunmetal,
            disabledBackgroundColor: AppPalette.alabasterGrey,
            disabledForegroundColor:
                AppPalette.gunmetal.withValues(alpha: 0.45),
          ),
          icon: indexing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
        ),
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

class _IndexingBanner extends StatelessWidget {
  const _IndexingBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.dustGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Indexing $label. Large PDFs can take several minutes.',
              style: const TextStyle(color: AppPalette.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySources extends StatelessWidget {
  const _EmptySources();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: EmptyStateIcon(icon: Icons.folder_open_outlined),
      title: 'No sources yet',
      subtitle: 'Add a labelled folder or file to start indexing.',
    );
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
