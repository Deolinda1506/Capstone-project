import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n_extension.dart';

/// Tab order for main shell navigation (Home, Settings only)
const List<String> _tabPaths = ['/', '/settings'];

int? _tabIndex(String location) {
  for (var i = 0; i < _tabPaths.length; i++) {
    if (location == _tabPaths[i] || location.startsWith('${_tabPaths[i]}/')) {
      return i;
    }
  }
  return null;
}

String? _nextPath(String location) {
  final idx = _tabIndex(location);
  if (idx == null) return null;
  final nextIdx = (idx + 1) % _tabPaths.length;
  return _tabPaths[nextIdx];
}

String? _prevPath(String location) {
  // Analyses, Patients, Referrals are reached from Settings - back goes to settings
  if (location.startsWith('/analyses') || location.startsWith('/patients') || location.startsWith('/referrals')) {
    return '/settings';
  }
  final idx = _tabIndex(location);
  if (idx == null || idx <= 0) return null;
  return _tabPaths[idx - 1];
}

/// True when on a nested route (e.g. /referrals/hospitals), not a top-level tab.
bool _isNestedRoute(String location) {
  for (final p in _tabPaths) {
    if (location != p && location.startsWith('$p/')) return true;
  }
  // /referrals/hospitals etc.
  final segments = location.split('/').where((s) => s.isNotEmpty).toList();
  return segments.length >= 2;
}

/// Back button - pops when on nested route, else goes to previous tab
Widget navBackButton(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  final prev = _prevPath(location);
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: context.l10n.t('back'),
    onPressed: () {
      if (_isNestedRoute(location) && context.canPop()) {
        context.pop();
      } else if (prev != null) {
        context.go(prev);
      } else {
        context.go('/');
      }
    },
  );
}

/// Next button - goes to next tab
Widget navNextButton(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;
  final next = _nextPath(location);
  return IconButton(
    icon: const Icon(Icons.arrow_forward),
    tooltip: context.l10n.t('next'),
    onPressed: next != null
        ? () => context.go(next)
        : null,
  );
}
