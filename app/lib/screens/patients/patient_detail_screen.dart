import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/patient_model.dart';
import '../../core/widgets/responsive_layout.dart';

/// Summary for a patient from the list before starting a carotid scan.
class PatientDetailScreen extends StatelessWidget {
  final PatientModel patient;

  const PatientDetailScreen({super.key, required this.patient});

  String get _headline {
    final id = patient.identifier?.trim();
    if (id != null && id.isNotEmpty) return id;
    final n = patient.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    return patient.id ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('patientDetails')),
      ),
      body: SafeArea(
        child: ListView(
          padding: responsivePadding(context),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headline,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (patient.name != null &&
                        patient.name!.trim().isNotEmpty &&
                        patient.name!.trim() != _headline) ...[
                      const SizedBox(height: 8),
                      _row(context, l10n.t('patient'), patient.name!.trim()),
                    ],
                    if (patient.age != null)
                      _row(context, l10n.t('age'), '${patient.age}'),
                    if (patient.email != null && patient.email!.trim().isNotEmpty)
                      _row(context, l10n.t('email'), patient.email!.trim()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/scan', extra: patient),
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(l10n.t('carotidScan')),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
