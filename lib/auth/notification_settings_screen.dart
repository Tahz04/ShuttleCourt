import 'package:flutter/material.dart';
import 'package:quynh/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _matchReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        title: const Text('Cài đặt thông báo', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildToggleTile('Thông báo đẩy', 'Nhận thông báo về kèo mới và tin nhắn', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
          const SizedBox(height: 16),
          _buildToggleTile('Email thông báo', 'Gửi cập nhật quan trọng qua email', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
          const SizedBox(height: 16),
          _buildToggleTile('Nhắc nhở trận đấu', 'Thông báo 1 tiếng trước khi trận đấu bắt đầu', _matchReminders, (v) => setState(() => _matchReminders = v)),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
      ),
    );
  }
}
