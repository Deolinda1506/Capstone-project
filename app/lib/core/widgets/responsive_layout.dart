import 'package:flutter/material.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;
  static bool isTabletOrLarger(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = padding?.horizontal ?? 24.0;
    final useConstraint = width > maxWidth + horizontalPadding * 2;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: useConstraint ? maxWidth : double.infinity),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: _responsivePadding(context),
            vertical: 16,
          ),
          child: child,
        ),
      ),
    );
  }

  double _responsivePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.mobile) return 16;
    if (width < Breakpoints.tablet) return 24;
    return 32;
  }
}

EdgeInsets responsivePadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width < Breakpoints.mobile ? 16.0 : (width < Breakpoints.tablet ? 24.0 : 32.0);
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: 16);
}

double responsiveHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < Breakpoints.mobile) return 16;
  if (width < Breakpoints.tablet) return 24;
  return 32;
}
