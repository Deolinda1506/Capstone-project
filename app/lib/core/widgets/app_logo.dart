import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  static Widget titleWithLogo(
    BuildContext context,
    String text, {
    double logoHeight = 36,
    double spacing = 10,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(height: logoHeight, showInAppBar: true, color: Colors.white),
        SizedBox(width: spacing),
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
    final logoColor = color ?? AppTheme.primaryBlue;
    final fontSize = height * 0.6;
    return Text(
      'CarotidCheck',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: logoColor,
        letterSpacing: -0.5,
      ),
    );
  }
}
