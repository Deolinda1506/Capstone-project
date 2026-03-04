import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/login/login_screen.dart';
import '../../screens/register/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/patient/patient_capture_screen.dart';
import '../../screens/patient/patient_consent_screen.dart';
import '../../screens/scan/scan_screen.dart';
import '../../screens/analyses/analyses_screen.dart';
import '../../screens/result/result_screen.dart';
import '../../screens/referral/referral_screen.dart';
import '../../screens/hospitals/hospitals_screen.dart';
import '../../screens/patients/patients_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/dashboard/chw_dashboard.dart';
import '../../screens/dashboard/clinician_dashboard.dart';
import '../../screens/dashboard/admin_dashboard.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../widgets/main_shell.dart';
import '../../screens/onboarding/onboarding_screen.dart' as onboarding;

GoRouter createAppRouter(AuthService authService, SyncService syncService) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authService,
    redirect: (context, state) async {
      final isLoggedIn = authService.isAuthenticated;
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isForgotRoute = state.matchedLocation == '/forgot-password';
      final isResetRoute = state.matchedLocation.startsWith('/reset-password');

      if (isLoggedIn && (isOnboarding || isLoginRoute)) return '/';
      if (isOnboarding && await onboarding.hasCompletedOnboarding()) return '/login';
      if (!isLoggedIn &&
          !isOnboarding &&
          !isLoginRoute &&
          !isRegisterRoute &&
          !isForgotRoute &&
          !isResetRoute) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          authService: authService,
          syncService: syncService,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          authService: authService,
          syncService: syncService,
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider.value(
          value: authService,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => ForgotPasswordScreen(authService: authService),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(
            authService: authService,
            tokenFromUrl: token,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) {
                  final user = authService.currentUser!;
                  return _RoleDashboard(
                    user: user,
                    syncService: syncService,
                    authService: authService,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analyses',
                builder: (context, state) => const AnalysesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patients',
                builder: (context, state) => const PatientsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/referrals',
                builder: (context, state) => const ReferralScreen(),
                routes: [
                  GoRoute(
                    path: 'hospitals',
                    builder: (context, state) => const HospitalsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/patient/capture',
        builder: (context, state) => const PatientCaptureScreen(),
      ),
      GoRoute(
        path: '/patient/consent',
        builder: (context, state) {
          final patient = state.extra as PatientModel? ?? const PatientModel();
          return PatientConsentScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          final patient = state.extra as PatientModel?;
          return ScanScreen(patient: patient);
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ResultScreen(
            risk: extra['risk'] as String? ?? 'low',
            imt: (extra['imt'] as num?)?.toDouble() ?? 0.0,
            plaqueDetected: extra['plaqueDetected'] as bool?,
            patientName: extra['patientName'] as String?,
            analyzedAt: extra['analyzedAt'] as String?,
            fromAnalyses: extra['fromAnalyses'] as bool? ?? false,
            segmentationOverlayBase64: extra['segmentationOverlayBase64'] as String?,
            originalImageBase64: extra['originalImageBase64'] as String?,
            hasAiOverlay: extra['hasAiOverlay'] as bool? ?? false,
          );
        },
      ),
    ],
  );
}

class _RoleDashboard extends StatelessWidget {
  final UserModel user;
  final SyncService syncService;
  final AuthService authService;

  const _RoleDashboard({
    required this.user,
    required this.syncService,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authService,
      child: switch (user.role) {
        UserRole.chw => ChwDashboard(user: user, syncService: syncService),
        UserRole.clinician => ClinicianDashboard(user: user, syncService: syncService),
        UserRole.admin => AdminDashboard(user: user, syncService: syncService),
      },
    );
  }
}
