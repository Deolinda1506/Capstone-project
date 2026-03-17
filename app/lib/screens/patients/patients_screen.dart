import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/models/patient_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/widgets/responsive_layout.dart';

/// Patients list - village-filtered (from backend)
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    final res = await auth.api.listPatients();
    if (!mounted) return;
    if (res.success && res.data != null) {
      final list = res.data as List;
      setState(() {
        _patients = list.map((e) => e as Map<String, dynamic>).toList();
        _loading = false;
        _error = null;
      });
    } else {
      setState(() {
        _patients = [];
        _loading = false;
        _error = res.error ?? l10n.t('failedToLoadPatients');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, context.l10n.t('myPatients')),
        leading: navBackButton(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
          navNextButton(context),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.t('loadingPatients'),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: Text(context.l10n.t('retry')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _patients.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(context.l10n.t('noPatientsYet'), textAlign: TextAlign.center),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: responsivePadding(context),
                          itemCount: _patients.length,
                          itemBuilder: (context, i) {
                            final p = _patients[i];
                            final id = p['identifier'] as String? ?? p['id'] as String? ?? '-';
                            final facility = p['facility'] as String? ?? '';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                                title: Text(
                                  id,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: facility.isNotEmpty ? Text(facility) : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/scan', extra: PatientModel(id: id)),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
