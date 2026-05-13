import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController baseUrlController;

  @override
  void initState() {
    super.initState();
    baseUrlController = TextEditingController(
      text: ref.read(apiBaseUrlProvider),
    );
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = ref.watch(apiBaseUrlProvider);

    if (baseUrlController.text != baseUrl) {
      baseUrlController.text = baseUrl;
      baseUrlController.selection = TextSelection.collapsed(
        offset: baseUrl.length,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              controller: baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => save(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void save() {
    final nextUrl = baseUrlController.text.trim();
    if (nextUrl.isEmpty) {
      return;
    }
    ref.read(apiBaseUrlProvider.notifier).state = nextUrl;
  }
}
