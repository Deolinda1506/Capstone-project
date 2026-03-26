import 'package:carotid_check/main.dart';
import 'package:carotid_check/screens/onboarding/onboarding_screen.dart' as onboarding;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// macOS App Sandbox often returns `-34018` (missing Keychain entitlement) when the
/// Runner is unsigned (`CODE_SIGN_IDENTITY = -`). [deleteAll] is best-effort; the
/// test then detects a stale session and fails with a clear hint.
Future<void> _clearSecureStorageBestEffort() async {
  const storage = FlutterSecureStorage();
  try {
    await storage.deleteAll();
  } on PlatformException catch (e) {
    final msg = '${e.code} ${e.message}';
    if (msg.contains('34018')) return;
    rethrow;
  }
}

/// Real-network login E2E. Use a staff account that exists on the API targeted
/// by [ApiConfig] (default: deployed Render) or `--dart-define=API_BASE_URL=...`.
///
/// From `app/`:
/// ```bash
/// flutter test integration_test/login_real_api_test.dart -d macos \
///   --dart-define=E2E_IDENTIFIER='0102-001' \
///   --dart-define=E2E_PASSWORD='your-password'
/// ```
void main() {
  const e2eIdentifier = String.fromEnvironment('E2E_IDENTIFIER', defaultValue: '');
  const e2ePassword = String.fromEnvironment('E2E_PASSWORD', defaultValue: '');
  final shouldSkip = e2eIdentifier.isEmpty || e2ePassword.isEmpty;

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login reaches role dashboard (real API)', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await onboarding.setOnboardingComplete();
    await _clearSecureStorageBestEffort();

    await tester.pumpWidget(const CarotidCheckApp());
    await tester.pumpAndSettle(const Duration(seconds: 15));

    final loginField = find.byKey(const ValueKey('e2e-login-identifier'));
    final home = find.byKey(const ValueKey('e2e-post-login-home'));
    if (loginField.evaluate().isEmpty && home.evaluate().isNotEmpty) {
      expect(
        home,
        findsNothing,
        reason:
            'Dashboard appeared without going through login: a session is still in '
            'Keychain and could not be cleared (typical on unsigned macOS: err -34018). '
            'Remove Keychain items for this app, run the test on Android/iOS, or set a '
            'Development Team in Xcode and add keychain-access-groups to Runner entitlements.',
      );
    }
    expect(loginField, findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('e2e-login-identifier')),
      e2eIdentifier,
    );
    await tester.enterText(
      find.byKey(const ValueKey('e2e-login-password')),
      e2ePassword,
    );
    await tester.tap(find.byKey(const ValueKey('e2e-login-submit')));
    await tester.pumpAndSettle(const Duration(seconds: 45));

    expect(find.byKey(const ValueKey('e2e-post-login-home')), findsOneWidget);
  }, skip: shouldSkip);
}
