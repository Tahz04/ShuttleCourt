import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/features/booking/screens/booking_history_screen.dart';
import 'package:shuttlecourt/features/matchmaking/screens/matchmaking_screen.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/features/owner/screens/owner_booking_management_screen.dart';
import 'package:shuttlecourt/features/shop/screens/owner_order_management_screen.dart';
import 'package:shuttlecourt/services/notification_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  final bool showAppBar;
  const NotificationScreen({super.key, this.showAppBar = true});

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
        final msg = action == 'accept' ? 'Đã chấp nhận ghép kèo!' : 'Đã từ chối yêu cầu';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: action == 'accept' ? AppTheme.success : AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    if (!widget.showAppBar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWebHeader(unreadCount),
          Expanded(child: _buildBody()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: _buildAppBar(unreadCount),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(int unreadCount) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      ),
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const Text(
            'Thông báo',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.highlight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount mới',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: Colors.white70),
              label: const Text(
                'Đọc hết',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWebHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông báo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount > 0 ? '$unreadCount thông báo chưa đọc' : 'Tất cả đã đọc',
                style: TextStyle(
                  fontSize: 13,
                  color: unreadCount > 0 ? AppTheme.accent : AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (unreadCount > 0)
            ElevatedButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('Đọc tất cả', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return _isLoading
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
                const SizedBox(height: 16),
                Text(
                  'Đang tải thông báo...',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          )
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
          );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 44,
                  color: AppTheme.primary.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chưa có thông báo nào',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kéo xuống để làm mới',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(SystemNotification n) {
    final isMatchRequest = n.type == 'match_join_request';
    final isResponding = _respondingIds.contains(n.id);
    final typeColor = _getTypeColor(n.type);

    return GestureDetector(
      onTap: isMatchRequest ? null : () => _markAndNavigate(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFF7F8FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar for unread
            if (!n.isRead)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(n.isRead ? 16 : 12, 14, 14, 14),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: n.isRead ? AppTheme.textPrimary : AppTheme.primary,
                                        fontSize: 14,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (!n.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 8, top: 4),
                                      decoration: BoxDecoration(color: typeColor, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              _buildTimeChip(n.createdAt),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Accept / Reject for match_join_request
                    if (isMatchRequest) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 12),
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
                              child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isResponding ? null : () => _respondToMatch(n, 'accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                              ),
                              child: isResponding
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Chấp nhận', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Navigation hint
                    if (!isMatchRequest && _hasNavigation(n.type)) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: n.isRead ? AppTheme.textMuted : typeColor.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: n.isRead ? AppTheme.textMuted : typeColor.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type, bool isRead) {
    final cfg = _iconConfig(type);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: isRead
            ? LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade50])
            : LinearGradient(
                colors: [cfg.color, cfg.color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isRead
            ? []
            : [BoxShadow(color: cfg.color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Icon(cfg.icon, color: isRead ? Colors.grey.shade400 : Colors.white, size: 22),
    );
  }

  Widget _buildTimeChip(DateTime dt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.borderLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time_rounded, size: 11, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            _formatTime(dt),
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking': return const Color(0xFFF59E0B);
      case 'booking_status': return AppTheme.success;
      case 'match_join_request': return const Color(0xFF3B82F6);
      case 'match_join_success': return AppTheme.success;
      case 'match_join_rejected': return AppTheme.error;
      case 'order': return const Color(0xFFF59E0B);
      case 'order_status': return const Color(0xFF8B5CF6);
      default: return AppTheme.accent;
    }
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
