import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/models/user_role.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/referral_list_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/nav_buttons.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/locale_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ReferralListService _referralService = ReferralListService();
  int _referralCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReferralCount();
  }

  Future<void> _loadReferralCount() async {
    final list = await _referralService.getReferrals();
    if (mounted) setState(() => _referralCount = list.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: AppLogo.titleWithLogo(context, l10n.t('settings')),
        leading: navBackButton(context),
        actions: [
          navNextButton(context),
        ],
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: l10n.t('preferences'),
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.t('theme')),
                subtitle: Text(l10n.t('themeSubtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.t('language')),
                subtitle: Text(l10n.t('languageSubtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguagePicker(context),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(l10n.t('analyses')),
                subtitle: Text(l10n.t('analysesSubtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/analyses'),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: Text(l10n.t('myPatients')),
                subtitle: Text(l10n.t('myPatientsSubtitle')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/patients'),
              ),
              ListTile(
                leading: const Icon(Icons.local_hospital),
                title: Text(l10n.t('myReferrals')),
                subtitle: Text(l10n.t('referralListSubtitle')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_referralCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$_referralCount', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => context.go('/referrals'),
              ),
            ],
          ),
          _SettingsSection(
            title: l10n.t('information'),
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.t('help')),
                subtitle: Text(l10n.t('faq')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showHelp(context),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.t('aboutCarotidCheck')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAbout(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.t('privacyPolicy')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacyPolicy(context),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.t('termsAndConditions')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTerms(context),
              ),
            ],
          ),
          _SettingsSection(
            children: [
              ListTile(
                leading: Icon(Icons.logout, color: AppTheme.riskHigh),
                title: Text(l10n.t('logout'), style: TextStyle(color: AppTheme.riskHigh, fontWeight: FontWeight.w600)),
                onTap: () => auth.logout(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final current = themeProvider.themeMode;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.t('theme'), style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: Icon(Icons.light_mode, color: current == ThemeMode.light ? AppTheme.primaryBlue : null),
              title: Text(context.l10n.t('themeLight')),
              trailing: current == ThemeMode.light ? const Icon(Icons.check_circle) : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode, color: current == ThemeMode.dark ? AppTheme.primaryBlue : null),
              title: Text(context.l10n.t('themeDark')),
              trailing: current == ThemeMode.dark ? const Icon(Icons.check_circle) : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.brightness_auto, color: current == ThemeMode.system ? AppTheme.primaryBlue : null),
              title: Text(context.l10n.t('themeSystem')),
              trailing: current == ThemeMode.system ? const Icon(Icons.check_circle) : null,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final provider = context.read<LocaleProvider>();
    final current = provider.locale;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.t('language'), style: Theme.of(context).textTheme.titleMedium),
            ),
            ...AppLocalizations.supportedLocales.map((locale) {
              final isSelected = locale == current;
              return ListTile(
                leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined),
                title: Text(AppLocalizations.localeName(locale)),
                onTap: () {
                  provider.setLocale(locale);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(l10n.t('aboutCarotidCheck'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: AppLogo(height: 80)),
                      const SizedBox(height: 24),
                      Text(
                        l10n.t('meetCarotidCheck'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.t('meetCarotidCheckDesc')),
                      const SizedBox(height: 24),
                      Text(
                        l10n.t('teamSection'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.t('teamDesc')),
                      const SizedBox(height: 20),
                      Text(
                        l10n.t('acknowledgments'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.t('acknowledgmentsDesc')),
                      const SizedBox(height: 24),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(l10n.t('help'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _FaqItem(question: l10n.t('faqWhatIsImt'), answer: l10n.t('faqWhatIsImtAnswer')),
                    const SizedBox(height: 16),
                    _FaqItem(question: l10n.t('faqWhatToDoHighRisk'), answer: l10n.t('faqWhatToDoHighRiskAnswer')),
                    const SizedBox(height: 16),
                    _FaqItem(question: l10n.t('faqScanQuality'), answer: l10n.t('faqScanQualityAnswer')),
                    const SizedBox(height: 16),
                    _FaqItem(question: l10n.t('faqDataStored'), answer: l10n.t('faqDataStoredAnswer')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showInfoSheet(
      context,
      title: context.l10n.t('privacyPolicy'),
      content: context.l10n.t('privacyPolicyContent'),
    );
  }

  void _showTerms(BuildContext context) {
    _showInfoSheet(
      context,
      title: context.l10n.t('termsAndConditions'),
      content: context.l10n.t('termsAndConditionsContent'),
    );
  }

  void _showInfoSheet(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(answer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SettingsSection({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: children),
        ),
      ],
    );
  }
}
