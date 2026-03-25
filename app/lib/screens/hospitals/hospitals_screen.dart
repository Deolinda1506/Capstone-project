import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/hospital_constants.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/referral_list_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';
import '../referral/referral_map_widget.dart';

class HospitalsScreen extends StatelessWidget {
  /// When the user opened this flow from a specific analysis result, record it so the result screen can hide repeat referral.
  final String? referringScanId;

  const HospitalsScreen({super.key, this.referringScanId});

  Future<void> _addReferral(BuildContext context, HospitalInfo hospital) async {
    final service = ReferralListService();
    final sid = referringScanId?.trim();
    await service.addReferral(ReferralEntry(
      hospitalName: hospital.name,
      district: hospital.district,
      referredAt: DateTime.now(),
      scanId: (sid != null && sid.isNotEmpty) ? sid : null,
    ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('addedToReferralList')),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      context.go('/referrals');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('hospitalsByDistrict')),
        leading: navBackButton(context),
        actions: [
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.riskModerate.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: AppTheme.riskModerate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.t('immediateReferralRecommended'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.l10n.t('referralsSubtitle'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),
              ...districtHospitals.map((h) => _HospitalCard(
                    hospital: h,
                    onRefer: () => _addReferral(context, h),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalInfo hospital;
  final VoidCallback onRefer;

  const _HospitalCard({required this.hospital, required this.onRefer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onRefer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_hospital, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          hospital.district,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          hospital.address,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.t('referToThisHospital'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (hospital.phone != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:${hospital.phone}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text(context.l10n.t('contact')),
                      ),
                    ),
                  if (hospital.phone != null) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openDirectionsToHospital(
                        lat: hospital.lat,
                        lng: hospital.lng,
                      ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: Text(context.l10n.t('getDirections')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
