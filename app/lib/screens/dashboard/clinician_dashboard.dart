import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/user_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Level 2: Hospital Clinician - Advanced UI
/// Focus: Review AI Segmentation → Clinical Validation → Treatment Plan
class ClinicianDashboard extends StatelessWidget {
  final UserModel user;
  final SyncService syncService;

  const ClinicianDashboard({
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
            Text(context.l10n.t('clinicianDashboard')),
          ],
        ),
        actions: [
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: ResponsiveContainer(
            maxWidth: 600,
            padding: EdgeInsets.zero,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dr. ${user.fullName ?? "Clinician"}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                'Kigali • Gasabo District Hospital',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              _ActionCard(
                icon: Icons.dashboard,
                title: context.l10n.t('hospitalDashboard'),
                subtitle: context.l10n.t('incomingReferrals'),
                color: AppTheme.riskHigh,
                onTap: () => context.go('/hospital-dashboard'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: context.l10n.t('reviewValidation')),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.analytics,
                title: context.l10n.t('analyses'),
                subtitle: context.l10n.t('pastScanResults'),
                color: AppTheme.accentTeal,
                onTap: () => context.go('/analyses'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.check_circle_outline,
                title: context.l10n.t('clinicalValidation'),
                subtitle: context.l10n.t('confirmOverrideAi'),
                color: AppTheme.primaryBlue,
                onTap: () => context.push('/clinician/validate'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: context.l10n.t('treatment')),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.assignment,
                title: context.l10n.t('treatmentPlans'),
                subtitle: context.l10n.t('createManagePlans'),
                color: Colors.blue,
                onTap: () => context.push('/clinician/plans'),
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.local_hospital,
                title: context.l10n.t('referrals'),
                subtitle: context.l10n.t('incomingFromChws'),
                color: AppTheme.riskModerate,
                onTap: () => context.go('/referrals'),
              ),
            ],
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
