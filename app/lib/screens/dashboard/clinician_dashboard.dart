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
                context.l10n.t('clinicianLocation'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 28),
              _SectionTitle(title: context.l10n.t('reviewValidation')),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.insights,
                title: context.l10n.t('analyses'),
                subtitle: context.l10n.t('pastScanResults'),
                color: AppTheme.accentTeal,
                onTap: () => context.go('/analyses'),
              ),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.verified_user,
                title: context.l10n.t('clinicalValidation'),
                subtitle: context.l10n.t('confirmOverrideAi'),
                color: AppTheme.primaryBlue,
                onTap: () => context.push('/clinician/validate'),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: context.l10n.t('treatment')),
              const SizedBox(height: 14),
              QuickActionCard(
                icon: Icons.medical_information,
                title: context.l10n.t('treatmentPlans'),
                subtitle: context.l10n.t('createManagePlans'),
                color: AppTheme.softBlue,
                onTap: () => context.push('/clinician/plans'),
              ),
              const SizedBox(height: 14),
              QuickActionCard(
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

