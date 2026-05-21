import 'package:flutter/material.dart';
import 'package:shuttlecourt/features/notifications/notification_screen.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

class WebNotificationPage extends StatelessWidget {
  final Function(int)? onTabChange;

  const WebNotificationPage({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.scaffoldLight,
      child: Column(
        children: [
          WebNavbar(
            selectedIndex: -1,
            onNavTap: (index) {
              Navigator.pop(context);
              onTabChange?.call(index);
            },
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: const NotificationScreen(showAppBar: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
