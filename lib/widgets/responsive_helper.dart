import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && 
      MediaQuery.of(context).size.width < 1024;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 400) {
      return const EdgeInsets.all(12.0);
    } else if (width < 600) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  static double getFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return baseSize * 0.9;
    } else if (width < 400) {
      return baseSize * 0.95;
    } else {
      return baseSize;
    }
  }

  static double getButtonHeight(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) {
      return 44.0;
    } else if (width < 400) {
      return 48.0;
    } else {
      return 52.0;
    }
  }

  static double getMaxContentWidth(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 600) {
      return width - 32; // Mobile: full width minus padding
    } else if (width < 1024) {
      return 500; // Tablet: constrained width
    } else {
      return 600; // Desktop: more constrained width
    }
  }
}

class ResponsiveWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveWidget({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? ResponsiveHelper.getScreenPadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? ResponsiveHelper.getMaxContentWidth(context),
          ),
          child: child,
        ),
      ),
    );
  }
}
