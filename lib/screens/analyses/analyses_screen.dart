import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/models/analysis_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Analyses list - past carotid scan results from backend
class AnalysesScreen extends StatefulWidget {
  const AnalysesScreen({super.key});

  @override
  State<AnalysesScreen> createState() => _AnalysesScreenState();
}

class _AnalysesScreenState extends State<AnalysesScreen> {
  List<AnalysisModel> _analyses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final res = await auth.api.listScansWithResults();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final list = res.data as List;
      setState(() {
        _analyses = list.map((e) {
          final m = e as Map<String, dynamic>;
          return AnalysisModel(
            id: m['scan_id'] as String? ?? '',
            patientId: m['patient_id'] as String?,
            patientName: m['patient_identifier'] as String?,
            analyzedAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'] as String) ?? DateTime.now() : DateTime.now(),
            risk: (m['risk_level'] as String? ?? 'low').toLowerCase(),
            imt: (m['imt_mm'] as num?)?.toDouble() ?? 0.0,
            plaqueDetected: m['plaque_detected'] as bool?,
          );
        }).toList();
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _analyses = [];
        _loading = false;
        _error = res.error ?? l10n.t('failedToLoadAnalyses');
      });
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return AppTheme.riskHigh;
      case 'moderate':
        return AppTheme.riskModerate;
      default:
        return AppTheme.riskLow;
    }
  }

  String _riskLabel(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return 'High';
      case 'moderate':
        return 'Moderate';
      default:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('analyses')),
        leading: navBackButton(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
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
                  )
                : SingleChildScrollView(
                    padding: responsivePadding(context),
                    child: ResponsiveContainer(
                      maxWidth: 600,
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _analyses.isEmpty ? context.l10n.t('noAnalysesYet') : context.l10n.t('analysesSubtitle'),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 20),
                          ..._analyses.map((a) => _AnalysisCard(
                                analysis: a,
                                riskColor: _riskColor(a.risk),
                                riskLabel: _riskLabel(a.risk),
                                onTap: () => context.push('/result', extra: {
                                  'risk': a.risk,
                                  'imt': a.imt,
                                  'plaqueDetected': a.plaqueDetected,
                                  'patientName': a.patientName,
                                  'analyzedAt': a.analyzedAt.toIso8601String(),
                                  'fromAnalyses': true,
                                }),
                              )),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AnalysisModel analysis;
  final Color riskColor;
  final String riskLabel;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.analysis,
    required this.riskColor,
    required this.riskLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y • HH:mm').format(analysis.analyzedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: riskColor.withOpacity(0.2),
          child: Icon(Icons.analytics, color: riskColor),
        ),
        title: Text(
          analysis.patientName ?? 'Unknown patient',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateStr\nIMT: ${analysis.imt.toStringAsFixed(1)} mm • $riskLabel risk',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
