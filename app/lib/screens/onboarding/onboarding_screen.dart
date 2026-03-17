import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';

const String _keyOnboardingComplete = 'onboarding_complete';

Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingComplete) ?? false;
}

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOnboardingComplete, true);
}

Future<void> clearOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyOnboardingComplete);
}

/// Onboarding: Page 1 = Logo, Page 2 = How it works, Page 3 = Intro (Meet CarotidCheck)
class OnboardingScreen extends StatefulWidget {
  final AuthService authService;
  final SyncService syncService;

  const OnboardingScreen({
    super.key,
    required this.authService,
    required this.syncService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _complete() async {
    await setOnboardingComplete();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                : [const Color(0xFF0D47A1), const Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _LogoPage(
                    onNext: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  _PurposePage(
                    onNext: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  _IntroPage(onComplete: _complete),
                ],
              ),
              if (_currentPage < 2)
                Positioned(
                  top: 8,
                  right: 16,
                  child: TextButton(
                    onPressed: _complete,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(context.l10n.t('skip')),
                  ),
                ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final active = i == _currentPage;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPage extends StatelessWidget {
  final VoidCallback onNext;

  const _LogoPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(height: 140, color: Colors.white),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => Text(
              context.l10n.t('tagline'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n.t('next')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurposePage extends StatelessWidget {
  final VoidCallback onNext;

  const _PurposePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.health_and_safety, size: 80, color: Colors.white),
          const SizedBox(height: 32),
          Builder(
            builder: (context) => Text(
              context.l10n.t('onboardingPurposeTitle'),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) => Text(
              context.l10n.t('onboardingPurposeDesc'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.l10n.t('next')),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final VoidCallback onComplete;

  const _IntroPage({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 56),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(height: 140, color: Colors.white),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final l10n = context.l10n;
                return Text(
                l10n.t('meetCarotidCheck'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) {
              final l10n = context.l10n;
              return Text(
                l10n.t('meetCarotidCheckDesc'),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 40),
          Builder(
            builder: (context) {
              final l10n = context.l10n;
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l10n.t('getStarted')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
