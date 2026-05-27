import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_macos_page.dart';
import 'features/history/history_macos_page.dart';
import 'features/settings/settings_macos_page.dart';
import 'features/sources/sources_macos_page.dart';
import 'services/api_providers.dart';
import 'widgets/local_lm_logo.dart';

class LocalLMMacosApp extends StatelessWidget {
  const LocalLMMacosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLM',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: CupertinoColors.label,
            fontSize: 15,
            letterSpacing: 0,
          ),
        ),
      ),
      home: MacosHomePage(),
    );
  }
}

class MacosHomePage extends ConsumerStatefulWidget {
  const MacosHomePage({super.key});

  @override
  ConsumerState<MacosHomePage> createState() => _MacosHomePageState();
}

class _MacosHomePageState extends ConsumerState<MacosHomePage> {
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
      MacSourcesPage(apiClient: apiClient),
      MacChatPage(
        key: ValueKey(chatSessionKey),
        apiClient: apiClient,
      ),
      MacHistoryPage(apiClient: apiClient),
      const MacSettingsPage(),
    ];

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _MacSidebar(
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
      ),
    );
  }
}

class _MacSidebar extends StatelessWidget {
  const _MacSidebar({
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
      width: 212,
      decoration: const BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        border: Border(
          right: BorderSide(color: CupertinoColors.separator, width: 0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 18, 14, 12),
            child: Row(
              children: [
                SizedBox(width: 30, height: 30, child: LocalLmLogo(size: 30)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'LocalLM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(8),
              onPressed: onNewChat,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 18),
                  SizedBox(width: 6),
                  Text('New chat'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _MacSidebarItem(
                    icon: CupertinoIcons.folder,
                    label: 'Sources',
                    selected: selectedIndex == 0,
                    onTap: () => onDestinationSelected(0),
                  ),
                  _MacSidebarItem(
                    icon: CupertinoIcons.chat_bubble_2,
                    label: 'Chat',
                    selected: selectedIndex == 1,
                    onTap: () => onDestinationSelected(1),
                  ),
                  _MacSidebarItem(
                    icon: CupertinoIcons.clock,
                    label: 'History',
                    selected: selectedIndex == 2,
                    onTap: () => onDestinationSelected(2),
                  ),
                  const Spacer(),
                  _MacSidebarItem(
                    icon: CupertinoIcons.gear,
                    label: 'Settings',
                    selected: selectedIndex == 3,
                    onTap: () => onDestinationSelected(3),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacSidebarItem extends StatelessWidget {
  const _MacSidebarItem({
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? CupertinoColors.systemBlue.withValues(alpha: 0.14)
                : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? CupertinoColors.systemBlue
                    : CupertinoColors.secondaryLabel,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.label,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
