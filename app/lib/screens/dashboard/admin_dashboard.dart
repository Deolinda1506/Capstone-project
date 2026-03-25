import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/user_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/responsive_layout.dart';

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
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppLogo(height: 36, showInAppBar: true),
            Expanded(
              child: Text(
                context.l10n.t('adminDashboard'),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
          ],
        ),
        actions: [navNextButton(context)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${user.fullName ?? "Admin"}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'ALU / RBC • System oversight',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              _SectionTitle(title: context.l10n.t('clinicalValidation')),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.insights,
                title: context.l10n.t('analyses'),
                subtitle: context.l10n.t('analysesSubtitle'),
                color: AppTheme.accentTeal,
                onTap: () => context.go('/analyses'),
              ),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.medical_services,
                title: context.l10n.t('referrals'),
                subtitle: context.l10n.t('referralsSubtitle'),
                color: AppTheme.riskModerate,
                onTap: () => context.go('/referrals'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: context.l10n.t('anonymizedStatistics')),
              const SizedBox(height: 14),
              _StatCard(
                title: context.l10n.t('totalScans'),
                value: '1,247',
                subtitle: context.l10n.t('last30Days'),
                icon: Icons.insights,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 14),
              _StatCard(
                title: context.l10n.t('highRiskReferrals'),
                value: '89',
                subtitle: context.l10n.t('imtThreshold'),
                icon: Icons.warning_amber_rounded,
                color: AppTheme.riskHigh,
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: context.l10n.t('systemHealth')),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.health_and_safety,
                title: context.l10n.t('systemStatus'),
                subtitle: context.l10n.t('apiDbSyncStatus'),
                color: AppTheme.softBlue,
                onTap: () => context.push('/admin/health'),
              ),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.cloud_sync,
                title: context.l10n.t('syncOverview'),
                subtitle: context.l10n.t('pendingUploadsByDistrict'),
                color: AppTheme.accentTeal,
                onTap: () => context.push('/admin/sync'),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: context.l10n.t('aiAccuracy')),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.monitor_heart,
                title: context.l10n.t('modelPerformance'),
                subtitle: context.l10n.t('attentionUnetMetrics'),
                color: AppTheme.primaryBlue,
                onTap: () => context.push('/admin/ai-metrics'),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom + 88),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
    );
  }
}
