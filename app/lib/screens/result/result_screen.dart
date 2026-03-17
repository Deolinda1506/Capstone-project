import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/responsive_layout.dart';

/// Result screen - full analysis details, color-coded risk (CHW flow)
/// Shows segmentation overlay so CHW can see what the AI measured
class ResultScreen extends StatelessWidget {
  final String risk; // low, moderate, high
  final double imt;
  final bool? plaqueDetected;
  final String? patientName;
  final String? analyzedAt; // ISO string
  final bool fromAnalyses;
  /// Base64 PNG: ultrasound with green overlay showing AI segmentation (wall)
  final String? segmentationOverlayBase64;
  /// Fallback: original scan when overlay unavailable (e.g. demo mode)
  final String? originalImageBase64;
  /// True when segmentationOverlayBase64 is from AI (green mask)
  final bool hasAiOverlay;

  const ResultScreen({
    super.key,
    required this.risk,
    required this.imt,
    this.plaqueDetected,
    this.patientName,
    this.analyzedAt,
    this.fromAnalyses = false,
    this.segmentationOverlayBase64,
    this.originalImageBase64,
    this.hasAiOverlay = false,
  });

  Color get _riskColor {
    switch (risk.toLowerCase()) {
      case 'high':
        return AppTheme.riskHigh;
      case 'moderate':
        return AppTheme.riskModerate;
      default:
        return AppTheme.riskLow;
    }
  }

  String _riskLabel(BuildContext context) {
    switch (risk.toLowerCase()) {
      case 'high':
        return context.l10n.t('riskHigh');
      case 'moderate':
        return context.l10n.t('riskModerate');
      default:
        return context.l10n.t('riskLow');
    }
  }

  String _riskExplanation(BuildContext context) {
    switch (risk.toLowerCase()) {
      case 'high':
        return context.l10n.t('riskHighExplained');
      case 'moderate':
        return context.l10n.t('riskModerateExplained');
      default:
        return context.l10n.t('riskLowExplained');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = analyzedAt != null
        ? DateFormat('MMM d, y • HH:mm').format(DateTime.parse(analyzedAt!))
        : null;
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('analysisResult')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
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
                if (patientName != null || dateStr != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (patientName != null)
                          Text(
                            patientName!,
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
                    color: _riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _riskColor, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.health_and_safety, size: 64, color: _riskColor),
                      const SizedBox(height: 16),
                      Text(
                        _riskLabel(context),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _riskColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'IMT: ${imt.toStringAsFixed(1)} mm',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.t('imtExplained'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _riskExplanation(context),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _riskColor,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  icon: Icons.analytics,
                  label: context.l10n.t('plaqueDetected'),
                  value: plaqueDetected == true ? context.l10n.t('yes') : (plaqueDetected == false ? context.l10n.t('no') : context.l10n.t('unknown')),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: context.l10n.t('riskLevel'),
                  value: _riskLabel(context),
                  valueColor: _riskColor,
                ),
                if (risk == 'high') ...[
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
                ],
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.push('/referrals'),
                  child: Text(risk == 'high' ? context.l10n.t('referToHospital') : context.l10n.t('viewReferralOptions')),
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
