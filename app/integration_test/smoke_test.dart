import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Lightweight integration smoke: binding + widget tree (no full CarotidCheck app).
/// Run from `app/`: `flutter test integration_test/smoke_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('integration binding: pump basic MaterialApp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('CarotidCheck test harness')),
        ),
      ),
    );
    expect(find.text('CarotidCheck test harness'), findsOneWidget);
  });
}
