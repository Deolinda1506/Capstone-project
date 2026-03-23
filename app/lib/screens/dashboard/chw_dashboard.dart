import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/user_model.dart';
import '../../core/services/sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/responsive_layout.dart';

class ChwDashboard extends StatelessWidget {
  final UserModel user;
  final SyncService syncService;

  const ChwDashboard({
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
          children: [
            const AppLogo(height: 36, showInAppBar: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.t('appName'),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
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
            child: Builder(
              builder: (context) {
              final l10n = context.l10n;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.t('welcome', {'name': user.fullName ?? 'CHW'}),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('tagline'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentTeal,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (user.healthCenter != null)
                    Text(
                      user.healthCenter!.displayAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  const SizedBox(height: 28),
                  QuickActionCard(
                    icon: Icons.person_add_alt_1,
                    title: l10n.t('newPatient'),
                    subtitle: l10n.t('newPatientSubtitle'),
                    color: AppTheme.primaryBlue,
                    onTap: () => context.push('/patient/capture'),
                  ),
                  const SizedBox(height: 14),
                  QuickActionCard(
                    icon: Icons.monitor_heart,
                    title: l10n.t('scan'),
                    subtitle: l10n.t('scanSubtitle'),
                    color: AppTheme.accentTeal,
                    onTap: () => context.push('/scan'),
                  ),
                  const SizedBox(height: 14),
                  QuickActionCard(
                    icon: Icons.insights,
                    title: l10n.t('analyses'),
                    subtitle: l10n.t('analysesSubtitle'),
                    color: AppTheme.primaryBlue,
                    onTap: () => context.go('/analyses'),
                  ),
                  const SizedBox(height: 14),
                  QuickActionCard(
                    icon: Icons.people_alt,
                    title: l10n.t('myPatients'),
                    subtitle: l10n.t('myPatientsSubtitle'),
                    color: AppTheme.softBlue,
                    onTap: () => context.go('/patients'),
                  ),
                  const SizedBox(height: 14),
                  QuickActionCard(
                    icon: Icons.medical_services,
                    title: l10n.t('referrals'),
                    subtitle: l10n.t('referralsSubtitle'),
                    color: AppTheme.riskModerate,
                    onTap: () => context.go('/referrals'),
                  ),
                ],
              );
              },
            ),
          ),
        ),
      ),
    );
  }
}

