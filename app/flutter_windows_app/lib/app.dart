import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/chat/chat_page.dart';
import 'features/history/history_page.dart';
import 'features/sources/sources_page.dart';
import 'services/api_providers.dart';

class LocalLMApp extends StatelessWidget {
  const LocalLMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LocalLM',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF386A5F),
        scaffoldBackgroundColor: const Color(0xFFFAFBFA),
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

  @override
  Widget build(BuildContext context) {
    final apiClient = ref.watch(apiClientProvider);
    final pages = [
      SourcesPage(apiClient: apiClient),
      ChatPage(apiClient: apiClient),
      HistoryPage(apiClient: apiClient),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Sources'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('History'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
    );
  }
}
