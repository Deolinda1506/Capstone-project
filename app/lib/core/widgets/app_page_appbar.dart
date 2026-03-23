import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_logo.dart';
import '../l10n/l10n_extension.dart';

PreferredSizeWidget appPageAppBar(
  BuildContext context, {
  required String title,
  String fallbackPath = '/',
  List<Widget>? actions,
  Widget? leading,
  double titleSpacing = 14,
}) {
  return AppBar(
    title: AppLogo.titleWithLogo(
      context,
      title,
      spacing: titleSpacing,
    ),
    leading: leading ??
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: context.l10n.t('back'),
          onPressed: () => context.canPop() ? context.pop() : context.go(fallbackPath),
        ),
    actions: actions,
  );
}
