import 'package:flutter/material.dart';

/// CarotidCheck logo - vascular/medical branding with CAROTIDCHECK text
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
        AppLogo(height: logoHeight, showInAppBar: true, color: Colors.white),
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
    final image = Image.asset(
      'assets/logo_carotidcheck.png',
      height: height,
      width: height * 1.2,
      fit: BoxFit.contain,
    );
    if (color != null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: image,
      );
    }
    return image;
  }
}
