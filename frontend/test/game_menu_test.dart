import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flying_maths/main.dart';

void main() {
  testWidgets('Game menu shows play without login option', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserState()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify initial state
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    
    // Verify difficulty selector is present
    expect(find.byType(DropdownButton), findsNWidgets(2)); // One for language, one for difficulty
    
    // Tap start game without login
    await tester.tap(find.text('Start Game'));
    await tester.pump();
    
    // Verify game starts
    expect(find.text('Score: 0'), findsOneWidget);
  });

  testWidgets('Login button appears in app bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserState()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify login button is in app bar
    expect(find.byIcon(Icons.login), findsOneWidget);
    
    // Verify it's clickable
    await tester.tap(find.byIcon(Icons.login));
    await tester.pump();
    
    // Verify login dialog appears
    expect(find.text('Login'), findsOneWidget);
  });
}