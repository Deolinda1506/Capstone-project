import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/services/referral_list_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

class ReferralScreen extends StatefulWidget {
  /// Carried from the analysis result screen so choosing a hospital records this scan as referred.
  final String? referringScanId;

  const ReferralScreen({super.key, this.referringScanId});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralListService _referralService = ReferralListService();
  List<ReferralEntry> _referrals = [];

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    final list = await _referralService.getReferrals();
    if (mounted) setState(() => _referrals = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('referrals')),
        leading: navBackButton(context),
        actions: [
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReferrals,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReferralListSection(referrals: _referrals),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () {
          final id = widget.referringScanId?.trim();
          final suffix = (id != null && id.isNotEmpty)
              ? '?scanId=${Uri.encodeQueryComponent(id)}'
              : '';
          context.push('/referrals/hospitals$suffix').then((_) {
            if (mounted) _loadReferrals();
          });
        },
        icon: const Icon(Icons.add),
        label: Text(context.l10n.t('findHospitals')),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}

class _ReferralListSection extends StatelessWidget {
  final List<ReferralEntry> referrals;

  const _ReferralListSection({required this.referrals});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.t('myReferrals'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.local_hospital_outlined, size: 48, color: Colors.grey[500]),
                const SizedBox(height: 12),
                Text(
                  context.l10n.t('noReferralsYet'),
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.t('tapFindHospitalsToAdd'),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...referrals.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.local_hospital, color: AppTheme.primaryBlue),
                  title: Text(r.hospitalName),
                  subtitle: Text(
                    '${r.district} • ${DateFormat.yMd().add_Hm().format(r.referredAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              )),
        const SizedBox(height: 80),
      ],
    );
  }
}
