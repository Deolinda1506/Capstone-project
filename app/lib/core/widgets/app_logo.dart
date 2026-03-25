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

  /// App bar: wordmark on the left, [text] right-aligned in the remaining title width.
  static Widget titleWithLogo(
    BuildContext context,
    String text, {
    double logoHeight = 36,
  }) {
    final titleStyle =
        Theme.of(context).appBarTheme.titleTextStyle ?? Theme.of(context).textTheme.titleLarge;
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppLogo(height: logoHeight, showInAppBar: true, color: Colors.white),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
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
