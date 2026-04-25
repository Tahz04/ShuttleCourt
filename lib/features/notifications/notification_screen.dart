import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/features/booking/screens/booking_history_screen.dart';
import 'package:quynh/features/matchmaking/screens/matchmaking_screen.dart';
import 'package:quynh/features/matchmaking/services/matchmaking_service.dart';
import 'package:quynh/features/owner/screens/owner_booking_management_screen.dart';
import 'package:quynh/features/shop/screens/owner_order_management_screen.dart';
import 'package:quynh/services/notification_service.dart';
import 'package:quynh/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<SystemNotification> _notifs = [];
  bool _isLoading = true;
  final Set<int> _respondingIds = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final list = await NotificationService.getNotifications(auth.user!.id.toString());
    if (mounted) setState(() { _notifs = list; _isLoading = false; });
  }

  Future<void> _markAndNavigate(SystemNotification n) async {
    if (!n.isRead) {
      await NotificationService.markAsRead(n.id);
      setState(() {
        final idx = _notifs.indexWhere((x) => x.id == n.id);
        if (idx != -1) {
          _notifs[idx] = SystemNotification(
            id: n.id, title: n.title, message: n.message, isRead: true,
            type: n.type, senderId: n.senderId, senderName: n.senderName,
            relatedId: n.relatedId, createdAt: n.createdAt,
          );
        }
      });
    }
    if (!mounted) return;
    _navigateByType(n);
  }

  void _navigateByType(SystemNotification n) {
    switch (n.type) {
      case 'booking':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBookingManagementScreen()));
        break;
      case 'booking_status':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
        break;
      case 'order':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerOrderManagementScreen()));
        break;
      case 'match_join_success':
      case 'match_join_rejected':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
        break;
      case 'match_join_request':
      case 'order_status':
      case 'general':
        break;
    }
  }

  Future<void> _respondToMatch(SystemNotification n, String action) async {
    if (n.senderId == null || n.relatedId == null) return;
    setState(() => _respondingIds.add(n.id));

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await MatchmakingService.respondToRequest(
      notificationId: n.id,
      requesterId: n.senderId!,
      matchId: n.relatedId!,
      action: action,
      hostName: auth.user!.fullName,
    );

    if (mounted) {
      setState(() => _respondingIds.remove(n.id));
      if (success) {
        final msg = action == 'accept' ? '🎉 Đã chấp nhận ghép kèo!' : '🚫 Đã từ chối yêu cầu';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: action == 'accept' ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ));
        _fetch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Có lỗi xảy ra, vui lòng thử lại'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await NotificationService.markAllAsRead(auth.user!.id.toString());
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifs.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
                child: Text('$unreadCount mới', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Đọc hết', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _fetch,
              color: AppTheme.primary,
              child: _notifs.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _notifs.length,
                      itemBuilder: (_, i) => _buildItem(_notifs[i]),
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Column(
          children: [
            Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Chưa có thông báo nào', style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Kéo xuống để làm mới', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildItem(SystemNotification n) {
    final isMatchRequest = n.type == 'match_join_request';
    final isResponding = _respondingIds.contains(n.id);

    return GestureDetector(
      onTap: isMatchRequest ? null : () => _markAndNavigate(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : AppTheme.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead ? AppTheme.borderLight : AppTheme.primary.withOpacity(0.2),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: n.isRead ? [] : [
            BoxShadow(color: AppTheme.primary.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeIcon(n.type, n.isRead),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: n.isRead ? AppTheme.textPrimary : AppTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(n.createdAt),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (!n.isRead)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(top: 4, left: 4),
                      decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                    ),
                ],
              ),

              // Accept / Reject cho match_join_request
              if (isMatchRequest) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isResponding ? null : () => _respondToMatch(n, 'reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('TỪ CHỐI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isResponding ? null : () => _respondToMatch(n, 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: isResponding
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('CHẤP NHẬN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],

              // Tap hint cho các type có navigation
              if (!isMatchRequest && _hasNavigation(n.type)) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Nhấn để xem chi tiết',
                      style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.primary.withOpacity(0.6)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type, bool isRead) {
    final cfg = _iconConfig(type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (isRead ? Colors.grey.shade100 : cfg.color.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(cfg.icon, color: isRead ? Colors.grey.shade400 : cfg.color, size: 22),
    );
  }

  ({IconData icon, Color color}) _iconConfig(String type) {
    switch (type) {
      case 'booking':
        return (icon: Icons.calendar_today_rounded, color: const Color(0xFFF59E0B));
      case 'booking_status':
        return (icon: Icons.check_circle_rounded, color: AppTheme.success);
      case 'match_join_request':
        return (icon: Icons.people_alt_rounded, color: const Color(0xFF3B82F6));
      case 'match_join_success':
        return (icon: Icons.sports_tennis_rounded, color: AppTheme.success);
      case 'match_join_rejected':
        return (icon: Icons.block_rounded, color: AppTheme.error);
      case 'order':
        return (icon: Icons.shopping_bag_rounded, color: const Color(0xFFF59E0B));
      case 'order_status':
        return (icon: Icons.local_shipping_rounded, color: const Color(0xFF8B5CF6));
      default:
        return (icon: Icons.notifications_rounded, color: AppTheme.accent);
    }
  }

  bool _hasNavigation(String type) {
    return ['booking', 'booking_status', 'order', 'match_join_success', 'match_join_rejected'].contains(type);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}
