import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n {
    try {
      final provider = Provider.of<LocaleProvider>(this, listen: false);
      return AppLocalizations(provider.locale);
    } catch (_) {
      return AppLocalizations(Localizations.localeOf(this));
    }
  }
}
