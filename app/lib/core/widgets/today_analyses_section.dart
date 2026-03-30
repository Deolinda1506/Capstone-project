import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_extension.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Shows analyses completed **today** (local date) so the user sees recent work on every Home visit.
/// Refetches when the app returns to foreground ([AppLifecycleState.resumed]).
class TodayAnalysesSection extends StatefulWidget {
  const TodayAnalysesSection({super.key});

  @override
  State<TodayAnalysesSection> createState() => _TodayAnalysesSectionState();
}

class _TodayAnalysesSectionState extends State<TodayAnalysesSection> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _today = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await auth.api.listScansWithResults(limit: 100);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.error ?? context.l10n.t('failedToLoadAnalyses');
        _today = [];
      });
      return;
    }
    final list = res.data as List;
    final now = DateTime.now();
    final today = <Map<String, dynamic>>[];
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final created = m['created_at'] as String?;
      if (created == null) continue;
      final dt = DateTime.tryParse(created);
      if (dt == null) continue;
      final local = dt.toLocal();
      if (local.year == now.year && local.month == now.month && local.day == now.day) {
        today.add(m);
      }
    }
    setState(() {
      _today = today;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _openResult(BuildContext context, Map<String, dynamic> m) async {
    final id = m['scan_id'] as String? ?? '';
    if (id.isEmpty) return;
    String? imageBase64;
    if (m['has_image'] == true) {
      final auth = context.read<AuthService>();
      final res = await auth.api.getScanImage(id);
      if (res.success && res.data != null) imageBase64 = res.data;
    }
    if (!context.mounted) return;
    final risk = (m['risk_level'] as String? ?? 'low').toLowerCase();
    context.push('/result/$id', extra: {
      'risk': risk,
      'imt': (m['imt_mm'] as num?)?.toDouble(),
      'stenosisPct': (m['stenosis_pct'] as num?)?.toDouble(),
      'stenosisSource': m['stenosis_source'],
      'plaqueDetected': m['plaque_detected'],
      'patientName': m['patient_name'] ?? m['patient_identifier'],
      'patientIdentifier': m['patient_identifier'] ?? '',
      'analyzedAt': m['created_at'],
      if (imageBase64 != null) ...{
        'segmentationOverlayBase64': imageBase64,
        'hasAiOverlay': m['has_ai_overlay'] as bool? ?? false,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.t('loadingAnalyses'),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          _error!,
          style: TextStyle(color: AppTheme.riskHigh, fontSize: 13),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.t('todayAnalysesTitle'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/analyses'),
              child: Text(l10n.t('todayAnalysesSeeAll')),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_today.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.t('todayAnalysesEmpty'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          )
        else ...[
          ..._today.take(5).map(
                (m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.analytics_outlined, color: AppTheme.primaryBlue),
                    title: Text(
                      (m['patient_name'] as String?) ?? (m['patient_identifier'] as String?) ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${(m['risk_level'] as String? ?? '').toUpperCase()} • ${(m['imt_mm'] as num?)?.toStringAsFixed(1) ?? '—'} mm',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _openResult(context, m),
                  ),
                ),
              ),
          if (_today.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.t('todayAnalysesMore', {'count': '${_today.length - 5}'}),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
