import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/district_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

/// Registration: name, district, password. Community workers login with District ID.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  DistrictOption? _selectedDistrict;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('pleaseSelectDistrict')),
          backgroundColor: AppTheme.riskModerate,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final result = await authService.registerWithId(
      _passwordController.text,
      _nameController.text.trim(),
      districtId: _selectedDistrict!.idCode,
    );
    if (result != null && mounted) {
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('accountCreated', {'id': result})),
          backgroundColor: AppTheme.primaryBlue,
          duration: const Duration(seconds: 6),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) => AppLogo.titleWithLogo(context, context.l10n.t('register')),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return Text(
                      l10n.t('createAccountTitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.t('fullName'),
                        hintText: l10n.t('fullNameHint'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (v) => v?.trim().isEmpty ?? true ? l10n.t('required') : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return DropdownButtonFormField<DistrictOption>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: l10n.t('district'),
                        hintText: l10n.t('selectDistrict'),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                      items: rwandaDistricts.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(l10n.t('districtFormat', {'name': d.name, 'id': d.idCode, 'province': d.province})),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedDistrict = v),
                      validator: (v) => v == null ? l10n.t('required') : null,
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
                        hintText: l10n.t('passwordMinHint'),
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
                        if (v.length < 6) return l10n.t('passwordMinHint');
                        return null;
                      },
                    );
                  },
                ),
                if (authService.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authService.error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return FilledButton(
                      onPressed: authService.isLoading ? null : _onSubmit,
                      child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.t('createAccount')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
