import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_localizations.dart';
import 'locale_provider.dart';

/// Extension to get app localizations. Uses LocaleProvider when available so
/// Kinyarwanda (rw) works even though Material/Cupertino delegates fall back
/// to English for system widgets.
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
