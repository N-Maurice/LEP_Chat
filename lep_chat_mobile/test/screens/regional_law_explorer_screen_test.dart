import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lep_app/screens/regional_law_explorer_screen.dart';

void main() {
  testWidgets('shows Rwanda and its jurisdiction links', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegionalLawExplorerScreen()));

    expect(find.text('Rwanda'), findsOneWidget);
    expect(find.text('Constitution'), findsOneWidget);
    expect(find.text('Labour Laws'), findsOneWidget);
    expect(find.text('Land Laws'), findsOneWidget);
  });
}
