import 'package:flutter/material.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

/// Web-optimized responsive scaffold with top navigation bar and optional sidebar
/// Automatically adapts layout for different screen sizes
class WebResponsiveScaffold extends StatefulWidget {
  final Widget? topNavigationBar;
  final Widget body;
  final bool showSidebar;
  final Widget? sidebar;
  final int? selectedSidebarIndex;
  final Function(int)? onSidebarItemTap;

  const WebResponsiveScaffold({
    super.key,
    this.topNavigationBar,
    required this.body,
    this.showSidebar = false,
    this.sidebar,
    this.selectedSidebarIndex,
    this.onSidebarItemTap,
  });

  @override
  State<WebResponsiveScaffold> createState() => _WebResponsiveScaffoldState();
}

class _WebResponsiveScaffoldState extends State<WebResponsiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          // Top Navigation Bar
          if (widget.topNavigationBar != null) widget.topNavigationBar!,

          // Main Content Area
          Expanded(
            child: Row(
              children: [
                // Optional Sidebar
                if (widget.showSidebar && widget.sidebar != null)
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      border: const Border(
                        right: BorderSide(
                          color: AppTheme.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: widget.sidebar,
                  ),

                // Main Content
                Expanded(
                  child: Container(
                    color: AppTheme.scaffoldLight,
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive container that adjusts max-width for web
class WebContentContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const WebContentContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth > maxWidth ? maxWidth : screenWidth - 40;

    return Center(
      child: Container(width: width, padding: padding, child: child),
    );
  }
}

/// Web-optimized grid that adapts column count based on screen width
class WebResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double maxChildWidth;
  final double horizontalSpacing;
  final double verticalSpacing;

  const WebResponsiveGrid({
    super.key,
    required this.children,
    this.maxChildWidth = 320,
    this.horizontalSpacing = 24,
    this.verticalSpacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount =
        ((screenWidth - 80) / (maxChildWidth + horizontalSpacing)).floor();
    crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
    crossAxisCount = crossAxisCount > 4 ? 4 : crossAxisCount;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: horizontalSpacing,
      mainAxisSpacing: verticalSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
