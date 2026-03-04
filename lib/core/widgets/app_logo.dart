import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// CarotidCheck logo - uses SVG (carotid vessel icon); fallback to icon if SVG fails
class AppLogo extends StatelessWidget {
  final double height;
  final bool showInAppBar;
  final Color? color;

  const AppLogo({
    super.key,
    this.height = 80,
    this.showInAppBar = false,
    this.color,
  });

  /// App bar title: logo + text, for consistent branding across screens
  static Widget titleWithLogo(BuildContext context, String text, {double logoHeight = 36}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(height: logoHeight, showInAppBar: true),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).appBarTheme.titleTextStyle ?? Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? (showInAppBar ? Colors.white : null);
    final widget = SvgPicture.asset(
      'assets/logo_carotid.svg',
      height: height,
      width: height * (100 / 120),
      fit: BoxFit.contain,
      colorFilter: displayColor != null
          ? ColorFilter.mode(displayColor, BlendMode.srcIn)
          : null,
    );
    return widget;
  }
}
