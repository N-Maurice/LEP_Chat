import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lep_app/screens/report_violation_screen.dart';

void main() {
  testWidgets('step 1 shows the category grid and description field', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportViolationScreen()));

    expect(find.text('Select Category'), findsOneWidget);
    expect(find.text('Corruption'), findsOneWidget);
    expect(find.text('Labour Abuse'), findsOneWidget);
    expect(find.text('Fraud'), findsOneWidget);
    expect(find.text('GBV'), findsOneWidget);
  });

  testWidgets('blocks advancing to step 2 without a category and description', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportViolationScreen()));

    // The Continue button sits below the fold — the ListView's sliver only
    // builds it once scrolled into view.
    await tester.scrollUntilVisible(find.text('Continue'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Select a category and describe the incident.'), findsOneWidget);
    expect(find.text('Where did this happen?'), findsNothing);
  });

  testWidgets('advances to the Location step once a category and description are set', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReportViolationScreen()));

    await tester.tap(find.text('Corruption'));
    await tester.enterText(find.byType(TextField), 'A bribe was requested at the district office.');
    await tester.scrollUntilVisible(find.text('Continue'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Where did this happen?'), findsOneWidget);
  });
}
