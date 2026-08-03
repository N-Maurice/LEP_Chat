import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lep_app/models/api_models.dart';
import 'package:lep_app/widgets/shared_widgets.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('LepPill renders its label', (tester) async {
    await tester.pumpWidget(wrap(const LepPill(label: 'VERIFIED')));
    expect(find.text('VERIFIED'), findsOneWidget);
  });

  testWidgets('VerifiedStamp shows the Verified label', (tester) async {
    await tester.pumpWidget(wrap(const VerifiedStamp()));
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('LepFormField shows its label and hint, and accepts input', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(LepFormField(label: 'Full name', controller: controller, hint: 'Johnathan Doe')));

    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('Johnathan Doe'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Jean-Luc');
    expect(controller.text, 'Jean-Luc');
  });

  testWidgets('LepPrimaryButton fires onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(LepPrimaryButton(label: 'Continue', onPressed: () => tapped = true)));

    await tester.tap(find.text('Continue'));
    expect(tapped, isTrue);
  });

  testWidgets('LepPrimaryButton shows a spinner and ignores taps while loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(LepPrimaryButton(label: 'Continue', loading: true, onPressed: () => tapped = true)));

    expect(find.text('Continue'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(tapped, isFalse);
  });

  testWidgets('LepSecondaryButton fires onPressed when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(LepSecondaryButton(label: 'Sign in with Google', onPressed: () => tapped = true)));

    await tester.tap(find.text('Sign in with Google'));
    expect(tapped, isTrue);
  });

  testWidgets('LepErrorBanner renders the given message', (tester) async {
    await tester.pumpWidget(wrap(const LepErrorBanner(message: 'Invalid credentials')));
    expect(find.text('Invalid credentials'), findsOneWidget);
  });

  group('ApiCitationBlockWidget', () {
    testWidgets('renders the quote and law reference when present', (tester) async {
      const citation = ApiCitation(
        source: 'vat_law.pdf',
        quote: 'VAT is charged at 18 percent.',
        lawNumber: '49',
        lawYear: '2023',
        domain: 'Tax',
      );
      await tester.pumpWidget(wrap(const ApiCitationBlockWidget(citation: citation)));

      expect(find.textContaining('VAT is charged at 18 percent.'), findsOneWidget);
      expect(find.text('vat_law.pdf'), findsOneWidget);
      expect(find.text('Law No. 49 of 2023'), findsOneWidget);
      expect(find.text('Tax'), findsOneWidget);
    });

    testWidgets('omits the quote block when there is no quote', (tester) async {
      const citation = ApiCitation(source: 'unknown.pdf');
      await tester.pumpWidget(wrap(const ApiCitationBlockWidget(citation: citation)));

      expect(find.text('unknown.pdf'), findsOneWidget);
      expect(find.textContaining('Law No.'), findsNothing);
    });
  });
}
