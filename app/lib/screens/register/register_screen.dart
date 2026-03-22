import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/district_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _approvalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _obscurePassword = true;
  DistrictOption? _selectedDistrict;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _approvalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
    final approvalCode = _approvalCodeController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final result = await authService.registerWithId(
      _passwordController.text,
      _nameController.text.trim(),
      districtId: _selectedDistrict!.idCode,
      approvalCode: approvalCode.isEmpty ? null : approvalCode,
      phone: phone.isEmpty ? null : phone,
      email: email.isEmpty ? null : email,
    );
    if (result != null && mounted) {
      _showSuccessDialog(result, phone.isNotEmpty);
    }
  }

  void _showSuccessDialog(String id, bool sentToPhone) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('createAccount')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.t('accountCreated', {'id': id})),
            if (sentToPhone) ...[
              const SizedBox(height: 12),
              Text(
                l10n.t('idSentToPhone'),
                style: TextStyle(
                  color: AppTheme.accentTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: id));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.t('copyId')}: $id')),
                );
              }
            },
            icon: const Icon(Icons.copy),
            label: Text(l10n.t('copyId')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: Text(l10n.t('goToLogin')),
          ),
        ],
      ),
    );
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
                      controller: _approvalCodeController,
                      decoration: InputDecoration(
                        labelText: l10n.t('approvalCode'),
                        hintText: l10n.t('approvalCodeHint'),
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        helperText: l10n.t('approvalCodeHelper'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.t('phone'),
                        hintText: l10n.t('phoneHint'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        helperText: l10n.t('phoneOptionalHint'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    return TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.t('emailOptional'),
                        hintText: l10n.t('emailHint'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        helperText: l10n.t('emailOptionalHint'),
                      ),
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
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      authService.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                if (authService.isLoading) ...[
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.t('registering'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.t('registeringSlowHint'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else
                  FilledButton(
                    onPressed: _onSubmit,
                    child: Text(context.l10n.t('createAccount')),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
