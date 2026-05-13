import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locallm/app.dart';

void main() {
  testWidgets('renders the desktop shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LocalLMApp()));

    expect(find.text('Sources'), findsWidgets);
    expect(find.text('Chat'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
  });
}
