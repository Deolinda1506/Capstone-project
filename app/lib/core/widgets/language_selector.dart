import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';

/// Dropdown or popup to select app language (English, French, Kinyarwanda)
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final current = localeProvider.locale;

    if (compact) {
      return IconButton(
        icon: const Icon(Icons.language),
        tooltip: AppLocalizations(current).t('language'),
        onPressed: () => _showMenu(context, localeProvider, current),
      );
    }

    return PopupMenuButton<Locale>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 4),
          Text(
            AppLocalizations(current).t('language'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      onSelected: (locale) => localeProvider.setLocale(locale),
      itemBuilder: (context) => AppLocalizations.supportedLocales
          .map((locale) => PopupMenuItem<Locale>(
                value: locale,
                child: Text(AppLocalizations.localeName(locale)),
              ))
          .toList(),
    );
  }

  void _showMenu(BuildContext context, LocaleProvider provider, Locale current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations(current).t('language'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
}
