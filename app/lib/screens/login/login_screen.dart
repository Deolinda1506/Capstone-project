import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';

/// Login: District ID + password
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveHorizontalPadding(context),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const AppLogo(height: 80),
                      const SizedBox(height: 24),
                      Text(
                        'CarotidCheck',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Builder(
                        builder: (context) {
                          final l10n = context.l10n;
                          return TextFormField(
                            controller: _identifierController,
                            decoration: InputDecoration(
                              labelText: l10n.t('districtId'),
                              hintText: l10n.t('districtIdHint'),
                              prefixIcon: const Icon(Icons.badge),
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
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: l10n.t('password'),
                              hintText: l10n.t('passwordHint'),
                              prefixIcon: const Icon(Icons.lock),
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
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.authService.error!,
                                  style: TextStyle(color: Colors.red[700], fontSize: 13),
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
                          child: Text(context.l10n.t('dontHaveAccount')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
