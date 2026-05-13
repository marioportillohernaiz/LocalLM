import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/source.dart';
import '../../services/api_client.dart';

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  final labelController = TextEditingController();
  final indexingSourceIds = <int>{};
  List<Source> sources = [];
  bool loading = false;
  String? activeIndexingLabel;
  String? errorMessage;

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

  Future<void> addFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) {
      return;
    }
    await addSource(path);
  }

  Future<void> addFile() async {
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
      final result = await widget.apiClient.indexSource(source.id);
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
      final result = await widget.apiClient.indexSource(source.id);
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sources',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : loadSources,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => addFolder(),
                ),
              ),
              FilledButton.icon(
                onPressed: loading ? null : addFolder,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Folder'),
              ),
              OutlinedButton.icon(
                onPressed: loading ? null : addFile,
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('File'),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: errorMessage!),
          ],
          if (activeIndexingLabel != null) ...[
            const SizedBox(height: 16),
            _IndexingBanner(label: activeIndexingLabel!),
          ],
          const SizedBox(height: 20),
          Expanded(
            child: loading && sources.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sources.isEmpty
                    ? const _EmptySources()
                    : ListView.separated(
                        itemCount: sources.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final source = sources[index];
                          final indexing =
                              indexingSourceIds.contains(source.id);
                          return _SourceCard(
                            source: source,
                            indexing: indexing,
                            onReindex: indexing ? null : () => reindex(source),
                          );
                        },
                      ),
          ),
        ],
      ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: const Icon(Icons.folder_open_outlined),
        title: Text(source.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${source.path}\n$lastIndexed',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton.filledTonal(
          tooltip: 'Re-index',
          onPressed: onReindex,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
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
              style: TextStyle(color: colorScheme.onSecondaryContainer),
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
    return Center(
      child: Text(
        'No sources',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
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
