import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/patient_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_appbar.dart';
import '../../core/widgets/responsive_layout.dart';

class PatientConsentScreen extends StatefulWidget {
  static const String route = '/patient/consent';

  final PatientModel patient;

  const PatientConsentScreen({super.key, required this.patient});

  @override
  State<PatientConsentScreen> createState() => _PatientConsentScreenState();
}

class _PatientConsentScreenState extends State<PatientConsentScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  bool _consentGiven = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appPageAppBar(
        context,
        title: context.l10n.t('patientConsent'),
        fallbackPath: '/patient/capture',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.t('privacyConsent'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.t('privacyConsentDesc'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.patient.id != null)
                      Text('ID: ${widget.patient.id}', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                    Text('${context.l10n.t('patient')}: ${widget.patient.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${context.l10n.t('age')}: ${widget.patient.age} • ${widget.patient.gender}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.t('signBelowOrThumbprint'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _signatureController.clear(),
                    child: Text(context.l10n.t('clear')),
                  ),
                  const Spacer(),
                  // Thumbprint alternative
                  IconButton(
                    onPressed: () {
                      setState(() => _consentGiven = true);
                    },
                    icon: const Icon(Icons.fingerprint, size: 48, color: AppTheme.primaryBlue),
                    tooltip: context.l10n.t('thumbprintConsent'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _consentGiven,
                onChanged: (v) => setState(() => _consentGiven = v ?? false),
                title: Text(context.l10n.t('consentText')),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  if (!_consentGiven) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.t('pleaseConfirmConsent'))),
                    );
                    return;
                  }
                  final patient = widget.patient.copyWith(
                    consentGiven: true,
                    consentTimestamp: DateTime.now(),
                  );
                  // Navigate to scan
                  if (context.mounted) context.go('/scan', extra: patient);
                },
                child: Text(context.l10n.t('confirmConsentStartScan')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
