import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/login_screen.dart';
import 'package:shuttlecourt/auth/register_screen.dart';
import 'package:shuttlecourt/auth/profile_screen.dart';
import 'package:shuttlecourt/features/notifications/notification_screen.dart';
import 'package:shuttlecourt/services/notification_service.dart';

/// Modern sticky top navigation bar — web only
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
    if (mounted)
      setState(() => _unreadCount = list.where((n) => !n.isRead).length);
  }

  static const List<_NavItem> _navItems = [
    _NavItem('Trang chủ', Icons.home_rounded, 0),
    _NavItem('Tìm sân', Icons.search_rounded, 1),
    _NavItem('Bản đồ', Icons.map_rounded, 2),
    _NavItem('Đặt lịch', Icons.calendar_month_rounded, 3),
    _NavItem('Ghép sân', Icons.people_rounded, 4),
    _NavItem('Tài khoản', Icons.person_rounded, 5),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: Row(
          children: [
            // ── Logo ──────────────────────────────────────────
            _buildLogo(),

            // ── Nav Links (center) ────────────────────────────
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _navItems
                        .map(
                          (item) => _NavLink(
                            item: item,
                            isActive: widget.selectedIndex == item.index,
                            onTap: () => widget.onNavTap(item.index),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),

            // ── Right Actions ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notifications bell
                  if (auth.isAuthenticated) ...[
                    _NotificationBell(
                      unreadCount: _unreadCount,
                      onTap: () async {
                        final nav = Navigator.of(context);
                        await nav.push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                        if (mounted) _fetchNotifications();
                      },
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Auth area
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
    );
  }

  Widget _buildLogo() {
    return InkWell(
      onTap: onLogoTap ?? () => widget.onNavTap(0),
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ShuttleCourt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Court Booking',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
            foregroundColor: AppTheme.textSecondary,
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
            backgroundColor: AppTheme.highlight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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

  Widget _buildUserMenu(AuthService auth) {
    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 4),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          onTap: () => Future.delayed(
            const Duration(milliseconds: 100),
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              SizedBox(width: 10),
              Text('Hồ sơ của tôi'),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
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
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  auth.user?.role == 'owner' ? 'Chủ sân' : 'Người dùng',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? get onLogoTap => widget.onLogoTap;
}

class _NavItem {
  final String label;
  final IconData icon;
  final int index;
  const _NavItem(this.label, this.icon, this.index);
}

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isActive
                    ? AppTheme.primary
                    : (_hovered
                          ? AppTheme.primary.withOpacity(0.3)
                          : Colors.transparent),
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            widget.item.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
              color: widget.isActive
                  ? AppTheme.primary
                  : (_hovered ? AppTheme.primary : AppTheme.textSecondary),
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

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
                color: AppTheme.scaffoldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.primary,
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
