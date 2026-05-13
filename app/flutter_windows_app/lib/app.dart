import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_page.dart';
import 'features/history/history_page.dart';
import 'features/settings/settings_page.dart';
import 'features/sources/sources_page.dart';
import 'services/api_providers.dart';
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
          seedColor: const Color(0xFF10A37F),
          brightness: Brightness.light,
          surface: const Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        fontFamily: 'Segoe UI',
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF10A37F), width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10A37F),
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
      backgroundColor: const Color(0xFFFFFFFF),
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
        color: Color(0xFFF7F7F8),
        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
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
                    color: Color(0xFF111827),
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
                            color: Color(0xFF6B7280),
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
        foregroundColor: const Color(0xFF111827),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
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
        color: selected ? const Color(0xFFECECF1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF374151)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF111827),
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
