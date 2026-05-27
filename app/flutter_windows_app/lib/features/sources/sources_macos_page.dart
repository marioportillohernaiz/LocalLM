import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../../models/source.dart';
import '../../services/api_client.dart';
import '../../theme/app_palette.dart';
import '../macos_feature_widgets.dart';

class MacSourcesPage extends StatefulWidget {
  const MacSourcesPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacSourcesPage> createState() => _MacSourcesPageState();
}

class _MacSourcesPageState extends State<MacSourcesPage> {
  final labelController = TextEditingController();
  final indexingSourceIds = <int>{};
  List<Source> sources = [];
  List<String> models = [];
  String? selectedEmbeddingModel;
  bool loading = false;
  bool loadingModels = false;
  String? activeIndexingLabel;
  String? error;

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
      error = null;
    });

    try {
      final loaded = await widget.apiClient.getSources();
      if (!mounted) return;
      setState(() {
        sources = loaded;
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
        loading = false;
      });
    }
  }

  Future<void> loadModels() async {
    setState(() {
      loadingModels = true;
    });

    try {
      final loadedModels = await widget.apiClient.getEmbeddingModels();
      if (!mounted) return;
      setState(() {
        models = loadedModels;
        if (selectedEmbeddingModel != null &&
            !loadedModels.contains(selectedEmbeddingModel)) {
          selectedEmbeddingModel = null;
        }
        selectedEmbeddingModel ??=
            loadedModels.isEmpty ? null : loadedModels.first;
      });
    } catch (_) {
      if (!mounted) return;
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

  Future<void> refreshPage() async {
    await Future.wait([
      loadSources(),
      loadModels(),
    ]);
  }

  Future<void> addFolder() async {
    if (models.isEmpty) return;

    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await addSource(path);
  }

  Future<void> addFile() async {
    if (models.isEmpty) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf', 'docx'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await addSource(path);
  }

  Future<void> addSource(String path) async {
    final label = labelController.text.trim();
    if (label.isEmpty) {
      setState(() {
        error = 'Label is required';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
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
      labelController.clear();
      await loadSources();
      if (mounted) {
        await showMacMessage(
          context,
          title: 'Index complete',
          message: result.summary,
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
          loading = false;
          activeIndexingLabel = null;
        });
      }
    }
  }

  Future<void> indexSource(Source source) async {
    setState(() {
      indexingSourceIds.add(source.id);
      activeIndexingLabel = source.label;
      error = null;
    });

    try {
      final result = await widget.apiClient.indexSource(
        source.id,
        embeddingModel: selectedEmbeddingModel,
      );
      if (!mounted) return;
      await showMacMessage(
        context,
        title: 'Index complete',
        message: result.summary,
      );
      await loadSources();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
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
    return Column(
      children: [
        MacPageHeader(
          title: 'Sources',
          subtitle: 'Connect local folders and files for retrieval.',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: loading || loadingModels ? null : refreshPage,
            child: const Icon(CupertinoIcons.refresh, color: AppPalette.text),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppPalette.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: _MacAddSourcePanel(
            controller: labelController,
            loading: loading,
            hasModels: models.isNotEmpty,
            models: models,
            selectedModel: selectedEmbeddingModel,
            loadingModels: loadingModels,
            onAddFolder: addFolder,
            onAddFile: addFile,
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
              if (error != null) ...[
                MacError(message: error!),
                const SizedBox(height: 16),
              ],
              if (activeIndexingLabel != null) ...[
                _MacIndexingBanner(label: activeIndexingLabel!),
                const SizedBox(height: 16),
              ],
              if (loading && sources.isEmpty)
                const SizedBox(
                  height: 240,
                  child: MacLoading(label: 'Loading sources'),
                )
              else if (sources.isEmpty)
                const SizedBox(
                  height: 360,
                  child: MacEmptyState(
                    icon: CupertinoIcons.folder,
                    title: 'No sources yet',
                    message: 'Add a labelled folder or file to start indexing.',
                  ),
                )
              else
                ...sources.map((source) {
                  final indexing = indexingSourceIds.contains(source.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MacSourceCard(
                      source: source,
                      indexing: indexing,
                      onReindex: indexing ? null : () => indexSource(source),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacAddSourcePanel extends StatelessWidget {
  const _MacAddSourcePanel({
    required this.controller,
    required this.loading,
    required this.hasModels,
    required this.models,
    required this.selectedModel,
    required this.loadingModels,
    required this.onAddFolder,
    required this.onAddFile,
    required this.onModelChanged,
  });

  final TextEditingController controller;
  final bool loading;
  final bool hasModels;
  final List<String> models;
  final String? selectedModel;
  final bool loadingModels;
  final VoidCallback onAddFolder;
  final VoidCallback onAddFile;
  final ValueChanged<String?> onModelChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Source label',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppPalette.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.border),
            ),
            onSubmitted: (_) {
              if (hasModels && !loading) {
                onAddFolder();
              }
            },
          ),
        ),
        MacIconPrimaryButton(
          label: 'Add folder',
          icon: CupertinoIcons.folder_badge_plus,
          onPressed: loading || !hasModels ? null : onAddFolder,
        ),
        MacIconSecondaryButton(
          label: 'Add file',
          icon: CupertinoIcons.doc_text,
          onPressed: loading || !hasModels ? null : onAddFile,
        ),
        MacModelPicker(
          models: models,
          selectedModel: selectedModel,
          loading: loadingModels,
          width: 240,
          onChanged: onModelChanged,
        ),
      ],
    );
  }
}

class _MacSourceCard extends StatelessWidget {
  const _MacSourceCard({
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
        : 'Indexed ${formatMacDate(source.lastIndexedAt!)}';

    return MacCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppPalette.dustGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.folder,
              color: AppPalette.gunmetal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${source.path}\n$lastIndexed',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(34, 34),
            color: AppPalette.alabasterGrey,
            disabledColor: AppPalette.alabasterGrey,
            borderRadius: BorderRadius.circular(8),
            onPressed: onReindex,
            child: indexing
                ? const CupertinoActivityIndicator()
                : const Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    color: AppPalette.gunmetal,
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}

class _MacIndexingBanner extends StatelessWidget {
  const _MacIndexingBanner({required this.label});

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
          const CupertinoActivityIndicator(),
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
