import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/patient_model.dart';
import '../../core/services/patient_id_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';
import 'patient_consent_screen.dart';
import 'patient_scan_io.dart' if (dart.library.html) 'patient_scan_web.dart' as scan;

class PatientCaptureScreen extends StatefulWidget {
  const PatientCaptureScreen({super.key});

  @override
  State<PatientCaptureScreen> createState() => _PatientCaptureScreenState();
}

class _PatientCaptureScreenState extends State<PatientCaptureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String? _name;
  int? _age;
  String? _gender;
  String? _email;
  bool _isScanning = false;

  Future<void> _scanId() async {
    setState(() => _isScanning = true);
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (xfile == null || !mounted) return;
      final patient = await scan.scanId(xfile);
      if (mounted && patient != null) {
        setState(() {
          _name = patient.name;
          _age = patient.age;
          _gender = patient.gender;
        });
        if (patient.name != null || patient.age != null || patient.gender != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.t('idScannedVerify')),
              backgroundColor: AppTheme.primaryBlue,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('couldNotReadId')),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.t('scanFailed'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('newPatient')),
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
                Text(
                  context.l10n.t('newPatient'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter patient details. A unique ID (CC-XXXX) will be assigned on registration.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isScanning ? null : _scanId,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isScanning ? context.l10n.t('scanning') : context.l10n.t('scanIdOptional')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: ValueKey(_name),
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('fullName'),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true ? context.l10n.t('required') : null,
                  onSaved: (v) => _name = v?.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_age),
                  initialValue: _age?.toString(),
                  decoration: InputDecoration(
                    labelText: context.l10n.t('age'),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return context.l10n.t('required');
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 120) return context.l10n.t('validAgeRequired');
                    return null;
                  },
                  onSaved: (v) => _age = int.tryParse(v ?? '0'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: InputDecoration(labelText: context.l10n.t('gender')),
                  items: [
                    DropdownMenuItem(value: 'Male', child: Text(context.l10n.t('male'))),
                    DropdownMenuItem(value: 'Female', child: Text(context.l10n.t('female'))),
                    DropdownMenuItem(value: 'Other', child: Text(context.l10n.t('other'))),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                  validator: (v) => v == null ? context.l10n.t('required') : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey(_email),
                  initialValue: _email,
                  decoration: InputDecoration(
                    labelText: context.l10n.t('emailOptional'),
                    hintText: context.l10n.t('emailOptionalHint'),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onSaved: (v) => _email = v?.trim().isEmpty ?? true ? null : v?.trim(),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      final id = await PatientIdService.generateId();
                      final patient = PatientModel(
                        id: id,
                        name: _name,
                        age: _age,
                        gender: _gender,
                        email: _email,
                      );
                      if (context.mounted) {
                        context.push(
                          PatientConsentScreen.route,
                          extra: patient,
                        );
                      }
                    }
                  },
                  child: Text(context.l10n.t('continueToConsent')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
