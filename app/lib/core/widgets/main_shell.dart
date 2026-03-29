import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n_extension.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Branch 0 nests routes under `/` (analyses, patients, etc.). Tapping Home
          // while already on branch 0 is a no-op unless we reset to the branch root.
          navigationShell.goBranch(
            index,
            initialLocation: index == 0,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.t('settings'),
          ),
        ],
      ),
    );
  }
}
