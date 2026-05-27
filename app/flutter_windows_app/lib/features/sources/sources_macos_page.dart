import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import '../../models/source.dart';
import '../../services/api_client.dart';
import '../macos_feature_widgets.dart';

class MacSourcesPage extends StatefulWidget {
  const MacSourcesPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<MacSourcesPage> createState() => _MacSourcesPageState();
}

class _MacSourcesPageState extends State<MacSourcesPage> {
  final labelController = TextEditingController();
  List<Source> sources = [];
  bool loading = true;
  bool adding = false;
  int? indexingId;
  String? error;

  @override
  void initState() {
    super.initState();
    loadSources();
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

  Future<void> addFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    await addSource(path);
  }

  Future<void> addFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf', 'docx'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await addSource(path);
  }

  Future<void> addSource(String path) async {
    final label = labelController.text.trim().isEmpty
        ? defaultMacSourceLabel(path)
        : labelController.text.trim();

    setState(() {
      adding = true;
      error = null;
    });

    try {
      await widget.apiClient.addSource(label: label, path: path);
      labelController.clear();
      await loadSources();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
      });
    } finally {
      if (mounted) {
        setState(() {
          adding = false;
        });
      }
    }
  }

  Future<void> indexSource(Source source) async {
    setState(() {
      indexingId = source.id;
      error = null;
    });

    try {
      final result = await widget.apiClient.indexSource(source.id);
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
          indexingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MacPage(
      title: 'Sources',
      trailing: MacSecondaryButton(label: 'Refresh', onPressed: loadSources),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MacCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MacSectionTitle('Add a source'),
                const SizedBox(height: 10),
                MacTextField(
                  controller: labelController,
                  placeholder: 'Label, optional',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MacPrimaryButton(
                      label: adding ? 'Adding...' : 'Add folder',
                      onPressed: adding ? null : addFolder,
                    ),
                    const SizedBox(width: 8),
                    MacSecondaryButton(
                      label: 'Add file',
                      onPressed: adding ? null : addFile,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            MacError(message: error!),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: loading
                ? const MacLoading(label: 'Loading sources')
                : sources.isEmpty
                    ? const MacEmptyState(
                        title: 'No sources yet',
                        message: 'Add a folder or file to start indexing.',
                      )
                    : ListView.separated(
                        itemCount: sources.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final source = sources[index];
                          return MacCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  CupertinoIcons.folder,
                                  color: CupertinoColors.systemBlue,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.label,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        source.path,
                                        style: const TextStyle(
                                          color: CupertinoColors.secondaryLabel,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        source.lastIndexedAt == null
                                            ? 'Not indexed yet'
                                            : 'Last indexed ${formatMacDate(source.lastIndexedAt!)}',
                                        style: const TextStyle(
                                          color: CupertinoColors.tertiaryLabel,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                MacSecondaryButton(
                                  label: indexingId == source.id
                                      ? 'Indexing...'
                                      : 'Index',
                                  onPressed: indexingId == null
                                      ? () => indexSource(source)
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
