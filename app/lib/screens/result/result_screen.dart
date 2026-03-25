import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page_appbar.dart';
import '../../core/widgets/responsive_layout.dart';

class ResultScreen extends StatefulWidget {
  final String scanId;
  final Map<String, dynamic>? initialData;

  const ResultScreen({
    super.key,
    required this.scanId,
    this.initialData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = _normalizeData(widget.initialData!);
      _loading = false;
    }
    if (widget.scanId.isNotEmpty) {
      _load();
    } else if (_data == null) {
      setState(() {
        _loading = false;
        _error = 'No scan ID';
      });
    }
  }

  Map<String, dynamic> _normalizeData(Map<String, dynamic> raw) {
    return {
      'risk': ((raw['risk_level'] ?? raw['risk']) as String? ?? 'low').toString().toLowerCase(),
      'imt': () {
        final v = raw['imt_mm'] ?? raw['imt'];
        if (v is num) return v.toDouble();
        return null;
      }(),
      'stenosisPct': (raw['stenosis_pct'] ?? raw['stenosisPct']) as num?,
      'stenosisSource': (raw['stenosis_source'] ?? raw['stenosisSource']) as String?,
      'plaqueDetected': (raw['plaque_detected'] ?? raw['plaqueDetected']) as bool?,
      'patientName': raw['patientName'] as String?,
      'patientIdentifier': (raw['patient_identifier'] ?? raw['patientIdentifier']) as String?,
      'patientAge': (raw['patient_age'] ?? raw['patientAge']) as int?,
      'analyzedAt': (raw['created_at'] ?? raw['analyzedAt']) as String?,
      'segmentationOverlayBase64': raw['segmentationOverlayBase64'] as String?,
      'originalImageBase64': raw['originalImageBase64'] as String?,
      'hasAiOverlay': raw['hasAiOverlay'] as bool? ?? false,
    };
  }

  Future<void> _load() async {
    if (widget.scanId.isEmpty) return;
    final auth = context.read<AuthService>();
    final res = await auth.api.getScanResult(widget.scanId);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final normalized = _normalizeData(res.data!);
      setState(() {
        _data = {...?_data, ...normalized};
        _loading = false;
        _error = null;
      });
      if (res.data!['has_image'] == true &&
          (_data == null || _data!['segmentationOverlayBase64'] == null)) {
        final imgRes = await auth.api.getScanImage(widget.scanId);
        if (!mounted) return;
        if (imgRes.success && imgRes.data != null) {
          setState(() {
            _data = {...(_data ?? {}), 'segmentationOverlayBase64': imgRes.data, 'hasAiOverlay': true};
          });
        }
      }
    } else {
      setState(() {
        _loading = false;
        _error = res.error ?? 'Failed to load result';
      });
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return AppTheme.riskHigh;
      case 'moderate':
        return AppTheme.riskModerate;
      case 'unknown':
        return Colors.blueGrey;
      default:
        return AppTheme.riskLow;
    }
  }

  String _riskLabel(BuildContext context, String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return context.l10n.t('riskHigh');
      case 'moderate':
        return context.l10n.t('riskModerate');
      case 'unknown':
        return context.l10n.t('riskUnknown');
      default:
        return context.l10n.t('riskLow');
    }
  }

  String _riskExplanation(BuildContext context, String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return context.l10n.t('riskHighExplained');
      case 'moderate':
        return context.l10n.t('riskModerateExplained');
      case 'unknown':
        return context.l10n.t('riskUnknownExplained');
      default:
        return context.l10n.t('riskLowExplained');
    }
  }

  void _shareReferralSlip(BuildContext context) {
    final d = _data;
    if (d == null) return;
    final analyzedAt = d['analyzedAt'] as String?;
    final patientIdentifier = d['patientIdentifier'] as String?;
    final patientName = d['patientName'] as String?;
    final risk = d['risk'] as String? ?? 'low';
    final imt = (d['imt'] as num?)?.toDouble();
    final dateStr = analyzedAt != null
        ? DateFormat('MMM d, y • HH:mm').format(DateTime.parse(analyzedAt))
        : '';
    final slip = '''
CarotidCheck – Referral Slip
============================

Patient ID: ${patientIdentifier ?? '—'}
${patientName != null ? 'Name: $patientName' : ''}
IMT: ${imt != null ? '${imt.toStringAsFixed(1)} mm' : context.l10n.t('imtNotAvailable')}
Risk level: ${risk.toUpperCase()}
Date: $dateStr

Referral hospital: Gasabo District Hospital, Kimironko

Please present this slip (or your Patient ID) when you arrive at the hospital.
''';
    Share.share(slip, subject: 'CarotidCheck Referral – ${patientIdentifier ?? "Patient"}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return Scaffold(
        appBar: appPageAppBar(
          context,
          title: context.l10n.t('analysisResult'),
          fallbackPath: '/analyses',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(context.l10n.t('loadingAnalyses'), style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    if (_error != null && _data == null) {
      return Scaffold(
        appBar: appPageAppBar(
          context,
          title: context.l10n.t('analysisResult'),
          fallbackPath: '/analyses',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: Text(context.l10n.t('retry'))),
              ],
            ),
          ),
        ),
      );
    }
    final d = _data!;
    final risk = d['risk'] as String? ?? 'low';
    final imt = (d['imt'] as num?)?.toDouble();
    final stenosisPct = (d['stenosisPct'] as num?)?.toDouble();
    final stenosisSource = d['stenosisSource'] as String?;
    final plaqueDetected = d['plaqueDetected'] as bool?;
    final patientName = d['patientName'] as String?;
    final patientIdentifier = d['patientIdentifier'] as String?;
    final analyzedAt = d['analyzedAt'] as String?;
    final segmentationOverlayBase64 = d['segmentationOverlayBase64'] as String?;
    final originalImageBase64 = d['originalImageBase64'] as String?;
    final hasAiOverlay = d['hasAiOverlay'] as bool? ?? false;
    final dateStr = analyzedAt != null
        ? DateFormat('MMM d, y • HH:mm').format(DateTime.parse(analyzedAt))
        : null;
    return Scaffold(
      appBar: appPageAppBar(
        context,
        title: context.l10n.t('analysisResult'),
        fallbackPath: '/analyses',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((segmentationOverlayBase64 ?? originalImageBase64) != null) ...[
                  Text(
                    hasAiOverlay
                        ? context.l10n.t('aiMeasurementOverlay')
                        : context.l10n.t('originalScan'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(segmentationOverlayBase64 ?? originalImageBase64!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: 300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (patientName != null || patientIdentifier != null || dateStr != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (patientIdentifier != null)
                          Text(
                            '${context.l10n.t('patientId')}: $patientIdentifier',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                          ),
                        if (patientName != null)
                          Text(
                            patientName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (dateStr != null)
                          Text(
                            dateStr,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _riskColor(risk).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _riskColor(risk), width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.health_and_safety, size: 64, color: _riskColor(risk)),
                      const SizedBox(height: 16),
                      Text(
                        _riskLabel(context, risk),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _riskColor(risk),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        imt != null
                            ? 'IMT: ${imt.toStringAsFixed(1)} mm'
                            : context.l10n.t('imtNotAvailable'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (imt != null && (d['patientAge'] as int?) != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.t('ageSpecificThresholds', {'age': '${d['patientAge']}'}),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                      if (imt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.t('imtExplained'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _riskExplanation(context, risk),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _riskColor(risk),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (stenosisPct != null) ...[
                  _DetailRow(
                    icon: Icons.bloodtype,
                    label: context.l10n.t('stenosis'),
                    value: '${stenosisPct.toStringAsFixed(1)}%'
                        + (stenosisSource == 'nascet' ? ' (NASCET)' : ''),
                  ),
                  const SizedBox(height: 12),
                ],
                _DetailRow(
                  icon: Icons.analytics,
                  label: context.l10n.t('plaqueDetected'),
                  value: plaqueDetected == true ? context.l10n.t('yes') : (plaqueDetected == false ? context.l10n.t('no') : context.l10n.t('unknown')),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: context.l10n.t('riskLevel'),
                  value: _riskLabel(context, risk),
                  valueColor: _riskColor(risk),
                ),
                if (risk.toLowerCase() == 'high') ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.riskHigh.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.riskHigh),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.t('immediateReferralToHospital'),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (patientIdentifier != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.t('showThisAtHospital'),
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patientIdentifier,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primaryBlue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _shareReferralSlip(context),
                    icon: const Icon(Icons.share),
                    label: Text(context.l10n.t('shareReferralSlip')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.push('/referrals'),
                  child: Text(risk.toLowerCase() == 'high' ? context.l10n.t('referToHospital') : context.l10n.t('viewReferralOptions')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
