import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lep_app/screens/auth/onboarding_screen.dart';

void main() {
  testWidgets('shows the welcome copy and stats', (tester) async {
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onGetStarted: () {}, onSignIn: () {})));

    expect(find.textContaining('Digital Justice'), findsOneWidget);
    expect(find.text('500k+'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('tapping Get Started fires onGetStarted', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onGetStarted: () => tapped = true, onSignIn: () {})));

    await tester.tap(find.text('Get Started'));
    expect(tapped, isTrue);
  });

  testWidgets('tapping "I already have an account" fires onSignIn', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onGetStarted: () {}, onSignIn: () => tapped = true)));

    await tester.tap(find.text('I already have an account'));
    expect(tapped, isTrue);
  });
}
