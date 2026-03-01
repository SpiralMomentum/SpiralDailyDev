import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.compactBody,
    this.expandedBody,
    this.breakpoint = 600,
  });

  final Widget compactBody;
  final Widget? expandedBody;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint && expandedBody != null) {
          return expandedBody!;
        }
        return compactBody;
      },
    );
  }

  static bool isExpanded(BuildContext context, {double breakpoint = 600}) {
    return MediaQuery.sizeOf(context).width >= breakpoint;
  }
}
