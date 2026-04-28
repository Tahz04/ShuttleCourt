import 'package:flutter/material.dart';
import 'package:shuttlecourt/features/notifications/notification_screen.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

/// Web-optimized notifications page wrapper
class WebNotificationPage extends StatelessWidget {
  final Function(int)? onTabChange;

  const WebNotificationPage({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WebNavbar(
          selectedIndex: -1, // No highlight since this is a modal-like page
          onNavTap: (index) {
            Navigator.pop(context);
            onTabChange?.call(index);
          },
        ),
        Expanded(child: const NotificationScreen()),
      ],
    );
  }
}
