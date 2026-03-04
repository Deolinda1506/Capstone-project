import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/analysis_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Hospital Dashboard - high-risk referrals and quick actions for hospital staff
class HospitalDashboardScreen extends StatefulWidget {
  const HospitalDashboardScreen({super.key});

  @override
  State<HospitalDashboardScreen> createState() => _HospitalDashboardScreenState();
}

class _HospitalDashboardScreenState extends State<HospitalDashboardScreen> {
  List<AnalysisModel> _highRisk = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final res = await auth.api.listHighRiskReferrals(limit: 50);
    if (!mounted) return;
    if (res.success && res.data != null) {
      final list = res.data as List;
      setState(() {
        _highRisk = list.map((e) {
          final m = e as Map<String, dynamic>;
          return AnalysisModel(
            id: m['scan_id'] as String? ?? '',
            patientId: m['patient_id'] as String?,
            patientName: m['patient_identifier'] as String?,
            analyzedAt: m['created_at'] != null
                ? DateTime.tryParse(m['created_at'] as String) ?? DateTime.now()
                : DateTime.now(),
            risk: (m['risk_level'] as String? ?? 'high').toLowerCase(),
            imt: (m['imt_mm'] as num?)?.toDouble() ?? 0.0,
            plaqueDetected: m['plaque_detected'] as bool?,
          );
        }).toList();
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _highRisk = [];
        _loading = false;
        _error = res.error ?? context.l10n.t('failedToLoadAnalyses');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: navBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(height: 36, showInAppBar: true),
            const SizedBox(width: 8),
            Text(l10n.t('hospitalDashboard')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: responsivePadding(context),
            child: ResponsiveContainer(
              maxWidth: 600,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('incomingReferrals'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    l10n.t('highRiskPatientsSubtitle'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  _StatCard(
                    title: l10n.t('highRiskReferrals'),
                    value: '${_highRisk.length}',
                    subtitle: l10n.t('awaitingReview'),
                    icon: Icons.warning_amber,
                    color: AppTheme.riskHigh,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: l10n.t('recentHighRisk')),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: Text(l10n.t('retry')),
                          ),
                        ],
                      ),
                    )
                  else if (_highRisk.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          Text(
                            l10n.t('noHighRiskReferrals'),
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._highRisk.take(10).map((a) => _ReferralCard(
                          analysis: a,
                          onTap: () => context.push('/result', extra: {
                            'risk': a.risk,
                            'imt': a.imt,
                            'plaqueDetected': a.plaqueDetected,
                            'patientName': a.patientName,
                            'analyzedAt': a.analyzedAt.toIso8601String(),
                            'fromAnalyses': true,
                          }),
                        )),
                  const SizedBox(height: 24),
                  _SectionTitle(title: l10n.t('quickActions')),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.analytics,
                    title: l10n.t('analyses'),
                    subtitle: l10n.t('pastScanResults'),
                    color: AppTheme.accentTeal,
                    onTap: () => context.go('/analyses'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.local_hospital,
                    title: l10n.t('referrals'),
                    subtitle: l10n.t('incomingFromChws'),
                    color: AppTheme.riskModerate,
                    onTap: () => context.go('/referrals'),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.people,
                    title: l10n.t('myPatients'),
                    subtitle: l10n.t('myPatientsSubtitle'),
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/patients'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final AnalysisModel analysis;
  final VoidCallback onTap;

  const _ReferralCard({required this.analysis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y • HH:mm').format(analysis.analyzedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.riskHigh.withOpacity(0.2),
          child: Icon(Icons.warning_amber, color: AppTheme.riskHigh),
        ),
        title: Text(
          analysis.patientName ?? 'Unknown patient',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$dateStr\nIMT: ${analysis.imt.toStringAsFixed(1)} mm • High risk',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
