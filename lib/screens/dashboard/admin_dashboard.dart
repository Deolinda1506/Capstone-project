import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/user_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/sync_status_indicator.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Level 3: Admin/Researcher (ALU/RBC)
/// Focus: Anonymized stats → System Health → AI Accuracy Monitoring
class AdminDashboard extends StatelessWidget {
  final UserModel user;
  final SyncService syncService;

  const AdminDashboard({
    super.key,
    required this.user,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: navBackButton(context),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(height: 36, showInAppBar: true),
            const SizedBox(width: 8),
            Text(context.l10n.t('adminDashboard')),
          ],
        ),
        actions: [
          SyncStatusIndicator(syncService: syncService, showLabel: false),
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${user.fullName ?? "Admin"}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'ALU / RBC • System oversight',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              _SectionTitle(title: context.l10n.t('anonymizedStatistics')),
              const SizedBox(height: 12),
              _StatCard(
                title: context.l10n.t('totalScans'),
                value: '1,247',
                subtitle: context.l10n.t('last30Days'),
                icon: Icons.analytics,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 12),
              _StatCard(
                title: context.l10n.t('highRiskReferrals'),
                value: '89',
                subtitle: context.l10n.t('imtThreshold'),
                icon: Icons.warning_amber,
                color: AppTheme.riskHigh,
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: context.l10n.t('systemHealth')),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.health_and_safety,
                title: context.l10n.t('systemStatus'),
                subtitle: context.l10n.t('apiDbSyncStatus'),
                color: Colors.blue,
                onTap: () => context.push('/admin/health'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.cloud,
                title: context.l10n.t('syncOverview'),
                subtitle: context.l10n.t('pendingUploadsByDistrict'),
                color: AppTheme.accentTeal,
                onTap: () => context.push('/admin/sync'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: context.l10n.t('aiAccuracy')),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.precision_manufacturing,
                title: context.l10n.t('modelPerformance'),
                subtitle: context.l10n.t('swinUnetrMetrics'),
                color: Colors.purple,
                onTap: () => context.push('/admin/ai-metrics'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.approval,
                title: context.l10n.t('accountApprovals'),
                subtitle: context.l10n.t('pendingChwClinician'),
                color: AppTheme.riskModerate,
                onTap: () => context.push('/admin/approvals'),
              ),
            ],
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
