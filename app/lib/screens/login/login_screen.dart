import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../screens/onboarding/onboarding_screen.dart' as onboarding;
import '../../core/services/sync_service.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final SyncService syncService;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.syncService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await widget.authService.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );
    if (ok && mounted) {
      context.go('/');
    }
  }

  Future<void> _goToOnboarding() async {
    await onboarding.clearOnboardingComplete();
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToOnboarding,
          tooltip: context.l10n.t('back'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlueLight,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: responsiveHorizontalPadding(context),
          ),
          child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 48),
                        const AppLogo(height: 88, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                        context.l10n.t('tagline'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Builder(
                        builder: (context) {
                          final l10n = context.l10n;
                          return TextFormField(
                            key: const ValueKey('e2e-login-identifier'),
                            controller: _identifierController,
                            decoration: InputDecoration(
                              labelText: l10n.t('districtId'),
                              hintText: l10n.t('districtIdHint'),
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return l10n.t('required');
                              return null;
                            },
                          );
                        },
                        ),
                        const SizedBox(height: 16),
                        Builder(
                        builder: (context) {
                          final l10n = context.l10n;
                          return TextFormField(
                            key: const ValueKey('e2e-login-password'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.t('password'),
                              hintText: l10n.t('passwordHint'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return l10n.t('required');
                              return null;
                            },
                          );
                        },
                        ),
                        if (widget.authService.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.authService.error!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ],
                        const SizedBox(height: 32),
                        Builder(
                        builder: (context) {
                          final l10n = context.l10n;
                          return FilledButton(
                            key: const ValueKey('e2e-login-submit'),
                            onPressed: widget.authService.isLoading ? null : _onSubmit,
                            child: widget.authService.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.t('login')),
                          );
                        },
                        ),
                        const SizedBox(height: 24),
                        Builder(
                        builder: (context) => TextButton(
                          onPressed: () => context.push('/register'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: Text(context.l10n.t('dontHaveAccount')),
                        ),
                        ),
                        ],
                    ),
                  ),
                ),
          ),
        ),
      );
  }
}
