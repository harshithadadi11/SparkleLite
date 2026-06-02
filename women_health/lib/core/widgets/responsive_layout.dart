import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget webBody;
  final double breakpoint;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.webBody,
    this.breakpoint = 800.0,
  });

  static bool isMobile(BuildContext context, {double breakpoint = 800.0}) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  static bool isWeb(BuildContext context, {double breakpoint = 800.0}) {
    return MediaQuery.of(context).size.width >= breakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return webBody;
        } else {
          return mobileBody;
        }
      },
    );
  }
}
