import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/features/booking/screens/booking_history_screen.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/services/notification_service.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';
import 'package:shuttlecourt/web/web_owner_dashboard_page.dart';
import 'package:shuttlecourt/web/web_admin_dashboard_page.dart';
class WebNotificationPage extends StatefulWidget {
  final Function(int)? onTabChange;
  const WebNotificationPage({super.key, this.onTabChange});

  @override
  State<WebNotificationPage> createState() => _WebNotificationPageState();
}

class _WebNotificationPageState extends State<WebNotificationPage>
    with SingleTickerProviderStateMixin {
  List<SystemNotification> _notifs = [];
  bool _isLoading = true;
  String _activeFilter = 'all';
  final Set<int> _respondingIds = {};
  late AnimationController _animCtrl;

  static const _filters = <String, _FilterMeta>{
    'all':         _FilterMeta('Tất cả',         Icons.inbox_rounded),
    'unread':      _FilterMeta('Chưa đọc',       Icons.mark_email_unread_rounded),
    'booking':     _FilterMeta('Đặt sân',        Icons.calendar_today_rounded),
    'order':       _FilterMeta('Đơn hàng',       Icons.shopping_bag_rounded),
    'match':       _FilterMeta('Ghép sân',       Icons.people_alt_rounded),
    'system':      _FilterMeta('Hệ thống',       Icons.settings_rounded),
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fetch();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final list = await NotificationService.getNotifications(auth.user!.id.toString());
    if (mounted) {
      setState(() { _notifs = list; _isLoading = false; });
      _animCtrl.forward(from: 0);
    }
  }

  List<SystemNotification> get _filtered {
    switch (_activeFilter) {
      case 'unread':
        return _notifs.where((n) => !n.isRead).toList();
      case 'booking':
        return _notifs.where((n) => n.type == 'booking' || n.type == 'booking_status').toList();
      case 'order':
        return _notifs.where((n) => n.type == 'order' || n.type == 'order_status').toList();
      case 'match':
        return _notifs.where((n) => n.type.startsWith('match_')).toList();
      case 'system':
        return _notifs.where((n) => n.type == 'system' || n.type == 'general').toList();
      default:
        return _notifs;
    }
  }

  int _countByFilter(String key) {
    switch (key) {
      case 'all': return _notifs.length;
      case 'unread': return _notifs.where((n) => !n.isRead).length;
      case 'booking': return _notifs.where((n) => n.type == 'booking' || n.type == 'booking_status').length;
      case 'order': return _notifs.where((n) => n.type == 'order' || n.type == 'order_status').length;
      case 'match': return _notifs.where((n) => n.type.startsWith('match_')).length;
      case 'system': return _notifs.where((n) => n.type == 'system' || n.type == 'general').length;
      default: return 0;
    }
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WebOwnerDashboardPage(initialTab: 2))); // Tab 2: Lịch Đặt
        break;
      case 'booking_status':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen())); // User side, keep as is
        break;
      case 'order':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WebOwnerDashboardPage(initialTab: 5))); // Tab 5: Đơn Hàng
        break;
      case 'match_join_success':
      case 'match_join_rejected':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
        break;
      case 'system':
        final auth = Provider.of<AuthService>(context, listen: false);
        if (auth.user?.role == 'admin') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WebAdminDashboardPage()));
        }
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
        if (action == 'accept') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
        }
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
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW >= 960;

    return Material(
      color: WebStyles.bg,
      child: Column(
        children: [
          WebNavbar(
            selectedIndex: -1,
            onNavTap: (index) {
              Navigator.pop(context);
              widget.onTabChange?.call(index);
            },
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSidebar(),
                            const SizedBox(width: 24),
                            Expanded(child: _buildMainContent()),
                          ],
                        )
                      : Column(
                          children: [
                            _buildMobileHeader(),
                            const SizedBox(height: 16),
                            _buildHorizontalFilters(),
                            const SizedBox(height: 16),
                            Expanded(child: _buildNotifList()),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar (desktop) ─────────────────────────────────────────────────────

  Widget _buildSidebar() {
    final unreadCount = _notifs.where((n) => !n.isRead).length;

    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: WebStyles.darkBannerGrad,
              borderRadius: BorderRadius.circular(WebStyles.rLg),
              boxShadow: WebStyles.brandShadow(0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        unreadCount > 0 ? Icons.mark_email_unread_rounded : Icons.done_all_rounded,
                        size: 16,
                        color: unreadCount > 0 ? WebStyles.cta : WebStyles.brandLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          unreadCount > 0
                              ? '$unreadCount thông báo chưa đọc'
                              : 'Tất cả đã đọc',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filters
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WebStyles.surface,
                borderRadius: BorderRadius.circular(WebStyles.rLg),
                border: Border.all(color: WebStyles.border),
                boxShadow: WebStyles.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'BỘ LỌC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: WebStyles.inkFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ..._filters.entries.map((e) => _buildFilterItem(e.key, e.value)),
                  const Spacer(),
                  // Mark all as read button
                  if (_notifs.any((n) => !n.isRead))
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label: const Text('Đánh dấu đã đọc tất cả'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: WebStyles.brand,
                          side: BorderSide(color: WebStyles.brand.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String key, _FilterMeta meta) {
    final isActive = _activeFilter == key;
    final count = _countByFilter(key);
    final color = _filterColor(key);

    return _HoverableFilterItem(
      isActive: isActive,
      onTap: () => setState(() => _activeFilter = key),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: color.withValues(alpha: 0.2))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.12) : WebStyles.dark100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(meta.icon, size: 16, color: isActive ? color : WebStyles.inkFaint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meta.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? color : WebStyles.inkMid,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? color.withValues(alpha: 0.15) : WebStyles.dark200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? color : WebStyles.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Main content (desktop) ────────────────────────────────────────────────

  Widget _buildMainContent() {
    final filtered = _filtered;
    final filterMeta = _filters[_activeFilter]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: WebStyles.surface,
            borderRadius: BorderRadius.circular(WebStyles.rLg),
            border: Border.all(color: WebStyles.border),
            boxShadow: WebStyles.shadowSm,
          ),
          child: Row(
            children: [
              Icon(filterMeta.icon, size: 20, color: _filterColor(_activeFilter)),
              const SizedBox(width: 10),
              Text(
                filterMeta.label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: WebStyles.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _filterColor(_activeFilter).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filtered.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _filterColor(_activeFilter),
                  ),
                ),
              ),
              const Spacer(),
              // Refresh button
              _WebIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Làm mới',
                onTap: _fetch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(child: _buildNotifList()),
      ],
    );
  }

  // ── Mobile header ─────────────────────────────────────────────────────────

  Widget _buildMobileHeader() {
    final unreadCount = _notifs.where((n) => !n.isRead).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: WebStyles.darkBannerGrad,
        borderRadius: BorderRadius.circular(WebStyles.rLg),
        boxShadow: WebStyles.brandShadow(0.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                Text(
                  unreadCount > 0 ? '$unreadCount chưa đọc' : 'Tất cả đã đọc',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white70),
              label: const Text('Đọc hết', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          _WebIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Làm mới',
            onTap: _fetch,
            lightMode: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filters.entries.map((e) {
          final isActive = _activeFilter == e.key;
          final count = _countByFilter(e.key);
          final color = _filterColor(e.key);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.1) : WebStyles.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? color.withValues(alpha: 0.3) : WebStyles.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.value.icon, size: 14, color: isActive ? color : WebStyles.inkFaint),
                    const SizedBox(width: 6),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? color : WebStyles.inkLight,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive ? color.withValues(alpha: 0.15) : WebStyles.dark200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? color : WebStyles.inkFaint),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Notification list ─────────────────────────────────────────────────────

  Widget _buildNotifList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: WebStyles.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(color: WebStyles.brand, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(
              'Đang tải thông báo...',
              style: TextStyle(color: WebStyles.inkFaint, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final items = _filtered;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    // Group by date
    final grouped = <String, List<SystemNotification>>{};
    for (final n in items) {
      final key = _dateGroupKey(n.createdAt);
      grouped.putIfAbsent(key, () => []).add(n);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: grouped.length,
      itemBuilder: (_, groupIdx) {
        final entry = grouped.entries.elementAt(groupIdx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: WebStyles.dark100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: WebStyles.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 11, color: WebStyles.inkFaint),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: WebStyles.inkLight, letterSpacing: -0.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(color: WebStyles.border, height: 1)),
                ],
              ),
            ),
            // Items
            ...entry.value.asMap().entries.map((e) {
              final idx = e.key;
              return AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, child) {
                  final delay = (groupIdx * entry.value.length + idx) * 0.05;
                  final t = (_animCtrl.value - delay).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 12 * (1 - t)),
                    child: Opacity(opacity: t, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WebNotifCard(
                    notif: e.value,
                    isResponding: _respondingIds.contains(e.value.id),
                    onTap: () => _markAndNavigate(e.value),
                    onAccept: () => _respondToMatch(e.value, 'accept'),
                    onReject: () => _respondToMatch(e.value, 'reject'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final filterMeta = _filters[_activeFilter]!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [WebStyles.dark100, WebStyles.dark50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: WebStyles.border, width: 2),
            ),
            child: Icon(
              _activeFilter == 'all'
                  ? Icons.notifications_off_rounded
                  : filterMeta.icon,
              size: 42,
              color: WebStyles.dark300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _activeFilter == 'all' ? 'Chưa có thông báo nào' : 'Không có thông báo ${filterMeta.label.toLowerCase()}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: WebStyles.inkMid,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _activeFilter == 'all'
                ? 'Thông báo sẽ xuất hiện ở đây khi có cập nhật mới'
                : 'Thử chọn bộ lọc khác để xem thông báo',
            style: TextStyle(fontSize: 13, color: WebStyles.inkFaint, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Làm mới'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WebStyles.brand,
              side: BorderSide(color: WebStyles.brand.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _filterColor(String key) {
    switch (key) {
      case 'all': return WebStyles.brand;
      case 'unread': return const Color(0xFF3B82F6);
      case 'booking': return const Color(0xFFF59E0B);
      case 'order': return const Color(0xFF8B5CF6);
      case 'match': return const Color(0xFF06B6D4);
      case 'system': return WebStyles.inkLight;
      default: return WebStyles.brand;
    }
  }

  String _dateGroupKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    if (diff < 7) return '$diff ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _FilterMeta {
  final String label;
  final IconData icon;
  const _FilterMeta(this.label, this.icon);
}

// ── Hoverable Filter Item ────────────────────────────────────────────────────

class _HoverableFilterItem extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;
  final Widget child;
  const _HoverableFilterItem({required this.isActive, required this.onTap, required this.child});

  @override
  State<_HoverableFilterItem> createState() => _HoverableFilterItemState();
}

class _HoverableFilterItemState extends State<_HoverableFilterItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: (!widget.isActive && _hovered) ? WebStyles.dark50 : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Web Icon Button ──────────────────────────────────────────────────────────

class _WebIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool lightMode;
  const _WebIconButton({required this.icon, required this.tooltip, required this.onTap, this.lightMode = true});

  @override
  State<_WebIconButton> createState() => _WebIconButtonState();
}

class _WebIconButtonState extends State<_WebIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.lightMode ? WebStyles.dark100 : Colors.white.withValues(alpha: 0.15))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.lightMode ? WebStyles.inkLight : Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification Card ────────────────────────────────────────────────────────

class _WebNotifCard extends StatefulWidget {
  final SystemNotification notif;
  final bool isResponding;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _WebNotifCard({
    required this.notif,
    required this.isResponding,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_WebNotifCard> createState() => _WebNotifCardState();
}

class _WebNotifCardState extends State<_WebNotifCard> {
  bool _hovered = false;

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking': return const Color(0xFFF59E0B);
      case 'booking_status': return AppTheme.success;
      case 'match_join_request': return const Color(0xFF3B82F6);
      case 'match_join_success': return AppTheme.success;
      case 'match_join_rejected': return AppTheme.error;
      case 'order': return const Color(0xFFF59E0B);
      case 'order_status': return const Color(0xFF8B5CF6);
      default: return WebStyles.brand;
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
        return (icon: Icons.notifications_rounded, color: WebStyles.brand);
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

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final isMatchRequest = n.type == 'match_join_request';
    final typeColor = _getTypeColor(n.type);
    final cfg = _iconConfig(n.type);

    return MouseRegion(
      cursor: isMatchRequest ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isMatchRequest ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: n.isRead
                ? (_hovered ? WebStyles.dark50 : WebStyles.surface)
                : (_hovered ? const Color(0xFFF0F4FF) : const Color(0xFFF5F7FF)),
            borderRadius: BorderRadius.circular(WebStyles.rLg),
            border: Border.all(
              color: !n.isRead
                  ? typeColor.withValues(alpha: 0.2)
                  : (_hovered ? WebStyles.borderMid : WebStyles.border),
            ),
            boxShadow: _hovered ? WebStyles.shadowSm : [],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                if (!n.isRead)
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor, typeColor.withValues(alpha: 0.4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(n.isRead ? 18 : 14, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: n.isRead
                                    ? LinearGradient(colors: [WebStyles.dark100, WebStyles.dark50])
                                    : LinearGradient(
                                        colors: [cfg.color, cfg.color.withValues(alpha: 0.75)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: n.isRead
                                    ? []
                                    : [BoxShadow(color: cfg.color.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Icon(cfg.icon, color: n.isRead ? WebStyles.dark400 : Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            // Text content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: n.isRead ? WebStyles.ink : typeColor,
                                            fontSize: 14,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      if (!n.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            color: typeColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [BoxShadow(color: typeColor.withValues(alpha: 0.4), blurRadius: 6)],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.message,
                                    style: TextStyle(
                                      color: WebStyles.inkLight,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      // Time chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: WebStyles.dark100,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: WebStyles.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.access_time_rounded, size: 11, color: WebStyles.inkFaint),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTime(n.createdAt),
                                              style: TextStyle(fontSize: 11, color: WebStyles.inkLight, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      // Navigation hint
                                      if (!isMatchRequest && _hasNavigation(n.type) && _hovered)
                                        AnimatedOpacity(
                                          opacity: _hovered ? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Xem chi tiết',
                                                style: TextStyle(
                                                  color: typeColor.withValues(alpha: 0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 14, color: typeColor.withValues(alpha: 0.8)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Match request buttons
                        if (isMatchRequest) ...[
                          const SizedBox(height: 14),
                          Divider(height: 1, color: WebStyles.border),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: widget.isResponding ? null : widget.onReject,
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  label: const Text('Từ chối'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: const BorderSide(color: AppTheme.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: widget.isResponding ? null : widget.onAccept,
                                  icon: widget.isResponding
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.check_rounded, size: 16),
                                  label: widget.isResponding ? const Text('') : const Text('Chấp nhận'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WebStyles.brand,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    elevation: 0,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
