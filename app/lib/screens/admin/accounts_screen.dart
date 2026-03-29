import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/models/user_role.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Lists organization team members and mobile self-registered CHW accounts (admin only).
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<Map<String, dynamic>> _team = [];
  List<Map<String, dynamic>> _mobile = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser?.role != UserRole.admin) {
      setState(() {
        _loading = false;
        _error = 'admin_only';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final teamRes = await auth.api.getTeam();
    final mobileRes = await auth.api.getMobileRegistrations();
    if (!mounted) return;
    if (!teamRes.success) {
      setState(() {
        _loading = false;
        _error = teamRes.error?.toString() ?? 'team';
      });
      return;
    }
    if (!mobileRes.success) {
      setState(() {
        _loading = false;
        _error = mobileRes.error?.toString() ?? 'mobile';
      });
      return;
    }
    setState(() {
      _loading = false;
      _team = [
        for (final e in (teamRes.data as List<dynamic>? ?? []))
          if (e is Map<String, dynamic>) e else if (e is Map) Map<String, dynamic>.from(e) else <String, dynamic>{},
      ];
      _mobile = [
        for (final e in (mobileRes.data as List<dynamic>? ?? []))
          if (e is Map<String, dynamic>) e else if (e is Map) Map<String, dynamic>.from(e) else <String, dynamic>{},
      ];
    });
  }

  String _fmtDate(Object? raw) {
    if (raw == null) return '—';
    DateTime? d;
    if (raw is String) {
      d = DateTime.tryParse(raw);
    }
    if (d == null) return '—';
    return DateFormat.yMMMd().add_Hm().format(d.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthService>();

    if (auth.currentUser?.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(
          title: AppLogo.titleWithLogo(context, l10n.t('accountsTitle')),
          leading: navBackButton(context),
        ),
        body: Padding(
          padding: responsivePadding(context),
          child: Center(
            child: Text(
              l10n.t('accountsAdminOnly'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, l10n.t('accountsTitle')),
        leading: navBackButton(context),
        actions: [navNextButton(context)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _error != 'admin_only'
                ? Center(
                    child: Padding(
                      padding: responsivePadding(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.t('accountsLoadError'),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: Text(l10n.t('retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: responsivePadding(context),
                      children: [
                        Text(
                          l10n.t('accountsSubtitle'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                        ),
                        const SizedBox(height: 20),
                        _SectionHeader(title: l10n.t('accountsOrgTeam')),
                        const SizedBox(height: 8),
                        if (_team.isEmpty)
                          Text(l10n.t('accountsEmptySection'))
                        else
                          ..._team.map((u) => _AccountTile(row: u, fmtDate: _fmtDate)),
                        const SizedBox(height: 24),
                        _SectionHeader(title: l10n.t('accountsMobileRegistrations')),
                        const SizedBox(height: 8),
                        if (_mobile.isEmpty)
                          Text(l10n.t('accountsEmptySection'))
                        else
                          ..._mobile.map((u) => _AccountTile(row: u, fmtDate: _fmtDate)),
                        SizedBox(height: MediaQuery.paddingOf(context).bottom + 24),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlue,
          ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final Map<String, dynamic> row;
  final String Function(Object?) fmtDate;

  const _AccountTile({required this.row, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final name = (row['display_name'] as String?)?.trim();
    final email = row['email'] as String? ?? '';
    final title = name != null && name.isNotEmpty ? name : email;
    final staffId = row['staff_id'] as String?;
    final role = (row['role'] as String? ?? '—').toString();
    final facility = row['facility'] as String?;
    final hospital = row['hospital_name'] as String?;
    final status = row['status'] as String? ?? '—';
    final created = row['created_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (staffId != null && staffId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${context.l10n.t('accountsColId')}: $staffId',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${context.l10n.t('accountsColRole')}: $role · ${context.l10n.t('accountsColStatus')}: $status',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[800]),
            ),
            if (facility != null && facility.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${context.l10n.t('accountsColDistrict')}: $facility',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (hospital != null && hospital.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                hospital,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              fmtDate(created),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
