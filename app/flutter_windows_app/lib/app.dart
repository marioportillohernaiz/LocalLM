import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_page.dart';
import 'features/history/history_page.dart';
import 'features/settings/settings_page.dart';
import 'features/sources/sources_page.dart';
import 'services/api_providers.dart';
import 'theme/app_palette.dart';
import 'widgets/local_lm_logo.dart';

class LocalLMApp extends StatelessWidget {
  const LocalLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.richCerulean,
          brightness: Brightness.light,
          surface: AppPalette.panel,
          primary: AppPalette.richCerulean,
          secondary: AppPalette.frostedBlue,
        ),
        scaffoldBackgroundColor: AppPalette.surface,
        fontFamily: 'Segoe UI',
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppPalette.text,
              displayColor: AppPalette.text,
            ),
        iconTheme: const IconThemeData(color: AppPalette.richCerulean),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppPalette.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppPalette.richCerulean, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.richCerulean,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedIndex = 0;
  int chatSessionKey = 0;

  void startNewChat() {
    setState(() {
      selectedIndex = 1;
      chatSessionKey += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);
    final pages = [
      SourcesPage(apiClient: apiClient),
      ChatPage(
        key: ValueKey(chatSessionKey),
        apiClient: apiClient,
      ),
      HistoryPage(apiClient: apiClient),
      const SettingsPage(),
    ];

    return Scaffold(
      backgroundColor: AppPalette.surface,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
            onNewChat: startNewChat,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onNewChat,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final VoidCallback onNewChat;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      decoration: const BoxDecoration(
        color: AppPalette.surface,
        border: Border(right: BorderSide(color: AppPalette.frostedBlue)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _NewChatButton(
                onPressed: onNewChat,
              ),
              const SizedBox(height: 18),
              _SidebarItem(
                icon: Icons.folder_open_outlined,
                label: 'Sources',
                selected: selectedIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _SidebarItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                selected: selectedIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _SidebarItem(
                icon: Icons.history_outlined,
                label: 'History',
                selected: selectedIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              const Spacer(),
              const Divider(height: 24),
              _SidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  LocalLmLogo(
                    size: 38,
                    color: AppPalette.text,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LocalLM',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Local RAG assistant',
                          style: TextStyle(
                            color: AppPalette.mutedText,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 20),
      label: const Align(
        alignment: Alignment.centerLeft,
        child: Text('New chat'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.text,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppPalette.border),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppPalette.frostedBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppPalette.richCerulean),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppPalette.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
