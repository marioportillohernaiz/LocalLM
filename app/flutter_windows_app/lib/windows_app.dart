import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_windows_page.dart';
import 'features/history/history_windows_page.dart';
import 'features/settings/settings_windows_page.dart';
import 'features/sources/sources_windows_page.dart';
import 'services/api_providers.dart';
import 'theme/app_palette.dart';
import 'widgets/local_lm_logo.dart';

class LocalLMWindowsApp extends StatelessWidget {
  const LocalLMWindowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLM',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.gunmetal,
          brightness: Brightness.light,
          surface: AppPalette.panel,
          primary: AppPalette.gunmetal,
          secondary: AppPalette.dustGrey,
        ),
        scaffoldBackgroundColor: AppPalette.surface,
        fontFamily: 'Segoe UI',
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppPalette.text,
              displayColor: AppPalette.text,
            ),
        iconTheme: const IconThemeData(color: AppPalette.gunmetal),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppPalette.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppPalette.panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppPalette.gunmetal, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.gunmetal,
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

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);
    final pages = [
      SourcesWindowsPage(apiClient: apiClient),
      ChatWindowsPage(
        key: ValueKey(chatSessionKey),
        apiClient: apiClient,
      ),
      HistoryWindowsPage(apiClient: apiClient),
      const SettingsWindowsPage(),
    ];

    return Scaffold(
      backgroundColor: AppPalette.surface,
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedIndex,
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
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      decoration: const BoxDecoration(
        color: AppPalette.panel,
        border: Border(right: BorderSide(color: AppPalette.dustGrey)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SidebarBrandHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppPalette.border)),
              ),
              padding: const EdgeInsets.all(8),
              child: _SidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: selectedIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarBrandHeader extends StatelessWidget {
  const _SidebarBrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: LocalLmLogo(size: 32),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'LocalLM',
              style: TextStyle(
                color: AppPalette.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
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
        color: selected ? AppPalette.dustGrey : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppPalette.gunmetal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 14,
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
