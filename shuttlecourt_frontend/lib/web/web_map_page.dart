import 'package:flutter/material.dart';
import 'package:shuttlecourt/map/map_screen.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

class WebMapPage extends StatelessWidget {
  final String? searchQuery;
  final Function(int, {String? query})? onTabChange;

  const WebMapPage({super.key, this.searchQuery, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WebNavbar(
          selectedIndex: 2,
          onNavTap: (index) => onTabChange?.call(index),
        ),
        Expanded(
          child: MapScreen(searchQuery: searchQuery, isGlobalSearch: false),
        ),
      ],
    );
  }
}
