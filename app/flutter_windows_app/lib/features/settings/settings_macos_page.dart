import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_providers.dart';
import '../macos_feature_widgets.dart';

class MacSettingsPage extends ConsumerStatefulWidget {
  const MacSettingsPage({super.key});

  @override
  ConsumerState<MacSettingsPage> createState() => _MacSettingsPageState();
}

class _MacSettingsPageState extends ConsumerState<MacSettingsPage> {
  late final TextEditingController baseUrlController;
  List<String> chatModels = [];
  List<String> embeddingModels = [];
  bool loadingModels = false;
  String? error;

  @override
  void initState() {
    super.initState();
    baseUrlController = TextEditingController(
      text: ref.read(apiBaseUrlProvider),
    );
    loadModels();
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    super.dispose();
  }

  Future<void> loadModels() async {
    setState(() {
      loadingModels = true;
      error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final loadedChatModels = await apiClient.getChatModels();
      final loadedEmbeddingModels = await apiClient.getEmbeddingModels();
      if (!mounted) return;
      setState(() {
        chatModels = loadedChatModels;
        embeddingModels = loadedEmbeddingModels;
        loadingModels = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = cleanMacError(exception);
        loadingModels = false;
      });
    }
  }

  void saveBaseUrl() {
    final value = baseUrlController.text.trim();
    if (value.isEmpty) return;
    ref.read(apiBaseUrlProvider.notifier).state = value;
    showMacMessage(
      context,
      title: 'Settings saved',
      message: 'Backend URL updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MacPage(
      title: 'Settings',
      trailing:
          MacSecondaryButton(label: 'Refresh models', onPressed: loadModels),
      child: ListView(
        children: [
          MacCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MacSectionTitle('Backend'),
                const SizedBox(height: 10),
                MacTextField(
                  controller: baseUrlController,
                  placeholder: 'http://127.0.0.1:8000',
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: MacPrimaryButton(
                    label: 'Save',
                    onPressed: saveBaseUrl,
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            MacError(message: error!),
          ],
          const SizedBox(height: 12),
          MacCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MacSectionTitle('Installed chat models'),
                const SizedBox(height: 10),
                if (loadingModels)
                  const MacLoading(label: 'Loading models')
                else if (chatModels.isEmpty)
                  const Text('No chat models found.')
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: chatModels
                        .map((model) => MacPill(label: model))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MacCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MacSectionTitle('Installed embedding models'),
                const SizedBox(height: 10),
                if (loadingModels)
                  const MacLoading(label: 'Loading models')
                else if (embeddingModels.isEmpty)
                  const Text('No embedding models found.')
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: embeddingModels
                        .map((model) => MacPill(label: model))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
