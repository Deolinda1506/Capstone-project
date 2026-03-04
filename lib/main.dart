import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/sync_service.dart';
import 'core/l10n/locale_provider.dart';
import 'core/router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CarotidCheckApp());
}

class CarotidCheckApp extends StatefulWidget {
  const CarotidCheckApp({super.key});

  @override
  State<CarotidCheckApp> createState() => _CarotidCheckAppState();
}

class _CarotidCheckAppState extends State<CarotidCheckApp> {
  late final AuthService _authService;
  late final SyncService _syncService;
  late final LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _syncService = SyncService();
    _localeProvider = LocaleProvider();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider.value(value: _syncService),
        ChangeNotifierProvider.value(value: _localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          // Material/Cupertino delegates don't support Kinyarwanda (rw).
          // Use 'en' as fallback for system widgets; our AppLocalizations still uses rw.
          final systemLocale = localeProvider.locale.languageCode == 'rw'
              ? const Locale('en')
              : localeProvider.locale;
          return MaterialApp.router(
            title: 'CarotidCheck',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: systemLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
              Locale('rw'),
            ],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: createAppRouter(_authService, _syncService),
          );
        },
      ),
    );
  }
}
