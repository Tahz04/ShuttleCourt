import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/web/web_styles.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/login_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/web/web_profile_page.dart';
import 'package:shuttlecourt/services/notification_service.dart';
import 'package:shuttlecourt/web/web_notification_page.dart';

/// Dark glassmorphism sticky top navigation bar — web only
class WebNavbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onNavTap;
  final VoidCallback? onLogoTap;

  const WebNavbar({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
    this.onLogoTap,
  });

  @override
  State<WebNavbar> createState() => _WebNavbarState();
}

class _WebNavbarState extends State<WebNavbar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) return;
    final list = await NotificationService.getNotifications(
      auth.user!.id.toString(),
    );
    if (mounted) {
      setState(() => _unreadCount = list.where((n) => !n.isRead).length);
    }
  }

  static const List<_NavItem> _navItems = [
    _NavItem('Trang chủ', Icons.home_rounded, 0),
    _NavItem('Tìm sân', Icons.search_rounded, 1),
    _NavItem('Bản đồ', Icons.map_rounded, 2),
    _NavItem('Đặt lịch', Icons.calendar_month_rounded, 3),
    _NavItem('Ghép sân', Icons.people_rounded, 4),
    _NavItem('Cửa hàng', Icons.shopping_bag_rounded, 5),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: WebStyles.dark900,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              _buildLogo(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _navItems
                          .map((item) => _NavLink(
                                item: item,
                                isActive: widget.selectedIndex == item.index,
                                onTap: () => widget.onNavTap(item.index),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (auth.isAuthenticated) ...[
                      _NotificationBell(
                        unreadCount: _unreadCount,
                        onTap: () async {
                          final nav = Navigator.of(context);
                          await nav.push(MaterialPageRoute(
                            builder: (_) => WebNotificationPage(
                              onTabChange: (i) => widget.onNavTap(i),
                            ),
                          ));
                          if (mounted) _fetchNotifications();
                        },
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (!auth.isAuthenticated)
                      _buildGuestActions()
                    else
                      _buildUserMenu(auth),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return InkWell(
      onTap: widget.onLogoTap ?? () => widget.onNavTap(0),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: WebStyles.brandGrad,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Shuttle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Court',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: WebStyles.brandLight,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text(
            'Đăng nhập',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: WebStyles.brand,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Đăng kí ngay',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildProfileMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    int tabIndex,
  ) {
    return PopupMenuItem(
      value: 'tab_$tabIndex',
      onTap: () => Future.delayed(
        const Duration(milliseconds: 100),
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebProfilePage(
              initialTab: tabIndex,
              onTabChange: widget.onNavTap,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildUserMenu(AuthService auth) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 4),
      itemBuilder: (context) => [
        _buildProfileMenuItem(context, 'Tổng quan', Icons.dashboard_outlined, 0),
        _buildProfileMenuItem(context, 'Lịch sử đặt sân', Icons.calendar_month_outlined, 1),
        _buildProfileMenuItem(context, 'Lịch sử ghép sân', Icons.people_outline, 2),
        _buildProfileMenuItem(context, 'Cài đặt', Icons.settings_outlined, 3),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          onTap: () => Future.delayed(
            const Duration(milliseconds: 100),
            () => auth.logout(),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, size: 18, color: AppTheme.error),
              SizedBox(width: 10),
              Text('Đăng xuất', style: TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: WebStyles.brandGrad,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user?.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  auth.user?.role == 'owner' ? 'Chủ sân' : 'Người dùng',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem(this.label, this.icon, this.index);
}

// ── Nav Link ──────────────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavLink({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? WebStyles.brand
                  : (_hovered
                      ? WebStyles.brand.withValues(alpha: 0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive
                    ? Colors.white
                    : (_hovered
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.75)),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification Bell ─────────────────────────────────────────────────────────

class _NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  const _NotificationBell({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
