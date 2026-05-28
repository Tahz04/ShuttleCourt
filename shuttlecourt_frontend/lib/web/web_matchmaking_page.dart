import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/features/matchmaking/screens/create_match_screen.dart';
import 'package:shuttlecourt/web/web_navbar.dart';
import 'package:shuttlecourt/web/web_styles.dart';

class WebMatchmakingPage extends StatefulWidget {
  final Function(int)? onTabChange;
  const WebMatchmakingPage({super.key, this.onTabChange});

  @override
  State<WebMatchmakingPage> createState() => _WebMatchmakingPageState();
}

class _WebMatchmakingPageState extends State<WebMatchmakingPage> {
  String _selectedLevel = 'Tất cả';
  late Future<List<MatchModel>> _matchesFuture;

  static const _levels = ['Tất cả', 'Mới chơi', 'Trung bình', 'Khá', 'Pro'];

  @override
  void initState() {
    super.initState();
    _refreshMatches();
  }

  void _refreshMatches() {
    setState(() {
      _matchesFuture = MatchmakingService.getAllMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WebStyles.bg,
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 4,
            onNavTap: (i) => widget.onTabChange?.call(i),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHero(),
                  _buildFilterBar(),
                  FutureBuilder<List<MatchModel>>(
                    future: _matchesFuture,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: CircularProgressIndicator(color: WebStyles.brand),
                          ),
                        );
                      }
                      final all = snap.data ?? [];
                      final filtered = _selectedLevel == 'Tất cả'
                          ? all
                          : all.where((m) => m.level == _selectedLevel).toList();
                      if (filtered.isEmpty) return _buildEmpty();
                      return _buildGrid(filtered);
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [WebStyles.dark900, WebStyles.dark800, Color(0xFF0C4A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(40, 52, 40, 52),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: WebStyles.brand.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: WebStyles.brand.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.people_rounded, size: 13, color: WebStyles.brandLight),
                          SizedBox(width: 6),
                          Text('GHÉP SÂN', style: WebStyles.eyebrow),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tìm Kèo\nCầu Lông',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.08,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kết nối với đồng đội có cùng trình độ — tìm kèo\nphù hợp và tham gia ngay hôm nay.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              _buildHeroStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroStats() {
    return FutureBuilder<List<MatchModel>>(
      future: _matchesFuture,
      builder: (ctx, snap) {
        final matches = snap.data ?? [];
        final open = matches.where((m) {
          final fill = m.joinedCount / m.capacity;
          return fill < 1.0;
        }).length;
        return Row(
          children: [
            _StatBox(label: 'Kèo mở', value: '$open', icon: Icons.sports_tennis_rounded),
            const SizedBox(width: 16),
            _StatBox(label: 'Tổng kèo', value: '${matches.length}', icon: Icons.groups_rounded),
          ],
        );
      },
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: const BoxDecoration(
        color: WebStyles.surface,
        border: Border(bottom: BorderSide(color: WebStyles.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                const Text(
                  'Trình độ:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: WebStyles.inkLight,
                  ),
                ),
                const SizedBox(width: 12),
                ..._levels.map((lv) {
                  final active = _selectedLevel == lv;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedLevel = lv),
                      borderRadius: BorderRadius.circular(WebStyles.rSm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: WebStyles.chip(active: active),
                        child: Text(
                          lv,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? Colors.white : WebStyles.inkMid,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────────
  Widget _buildGrid(List<MatchModel> matches) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: WebStyles.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${matches.length} kèo',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: WebStyles.inkFaint,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (ctx, bc) {
                  final cols = bc.maxWidth > 1100
                      ? 4
                      : bc.maxWidth > 760
                          ? 3
                          : bc.maxWidth > 500
                              ? 2
                              : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: matches.length,
                    itemBuilder: (ctx, i) => _MatchCard(
                      match: matches[i],
                      onJoin: () => _handleJoin(matches[i]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WebStyles.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: WebStyles.brand),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có kèo nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: WebStyles.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tạo kèo mới để mời người chơi cùng',
              style: TextStyle(fontSize: 14, color: WebStyles.inkFaint),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
        );
        if (result == true) _refreshMatches();
      },
      backgroundColor: WebStyles.brand,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Tạo Kèo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  // ── Join handler ─────────────────────────────────────────────────────────────
  void _handleJoin(MatchModel match) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnack('Vui lòng đăng nhập để tham gia kèo!', isError: true);
      return;
    }
    if (auth.user!.id == match.hostId.toString()) {
      _showSnack('Bạn là chủ kèo này rồi!', isError: true);
      return;
    }
    final ok = await MatchmakingService.requestJoin(
      userId: int.parse(auth.user!.id),
      matchId: match.id,
      hostId: match.hostId,
      senderName: auth.user!.fullName,
      courtName: match.courtName,
    );
    if (mounted) {
      _showSnack(ok ? '✅ Yêu cầu đã gửi!' : '❌ Lỗi, vui lòng thử lại', isError: !ok);
      if (ok) _refreshMatches();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : WebStyles.brand,
    ));
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(WebStyles.rLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: WebStyles.brandLight),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────
class _MatchCard extends StatefulWidget {
  final MatchModel match;
  final VoidCallback onJoin;
  const _MatchCard({required this.match, required this.onJoin});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _hovered = false;

  static const _levelColor = {
    'Mới chơi': Color(0xFF059669),
    'Trung bình': Color(0xFF0284C7),
    'Khá': Color(0xFFF59E0B),
    'Pro': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final fill = m.joinedCount / m.capacity;
    final full = fill >= 1.0;
    final isLocked = full || m.isExpired;
    final levelC = m.isExpired ? const Color(0xFFDC2626) : (_levelColor[m.level] ?? WebStyles.brand);
    final dateStr = DateFormat('dd/MM/yyyy').format(m.matchDate);
    final timeStr = m.startTime.substring(0, 5);

    return MouseRegion(
      cursor: isLocked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: _hovered && !isLocked
            ? WebStyles.cardActive(levelC)
            : WebStyles.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: levelC.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(WebStyles.rLg)),
                border: Border(bottom: BorderSide(color: levelC.withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: levelC.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(WebStyles.rSm),
                    ),
                    child: Text(
                      m.joinedCount >= m.capacity
                          ? 'ĐÃ CHỐT SỔ'
                          : (m.isExpired ? 'ĐÃ KHÓA' : m.level.toUpperCase()),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: levelC,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${NumberFormat('#,###').format(m.price)}đ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: isLocked ? Colors.grey : levelC,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.courtName,
                      style: WebStyles.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text: '$dateStr • $timeStr',
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      text: 'Chủ: ${m.hostName}',
                    ),
                    const SizedBox(height: 10),

                    // Progress
                    Row(
                      children: [
                        const Icon(Icons.people_rounded, size: 13, color: WebStyles.inkFaint),
                        const SizedBox(width: 5),
                        Text(
                          '${m.joinedCount}/${m.capacity} người',
                          style: const TextStyle(
                            fontSize: 12,
                            color: WebStyles.inkLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(fill * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: levelC,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fill,
                        minHeight: 5,
                        backgroundColor: WebStyles.border,
                        valueColor: AlwaysStoppedAnimation<Color>(levelC),
                      ),
                    ),

                    if (m.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        m.description,
                        style: const TextStyle(fontSize: 12, color: WebStyles.inkFaint, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Join button ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: isLocked ? null : widget.onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked ? WebStyles.border : levelC,
                    foregroundColor: isLocked ? WebStyles.inkFaint : Colors.white,
                    disabledBackgroundColor: WebStyles.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WebStyles.rMd),
                    ),
                  ),
                  child: Text(
                    m.joinedCount >= m.capacity
                        ? 'Đã đầy'
                        : (m.isExpired ? 'Đã khóa' : 'Tham gia'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: WebStyles.inkFaint),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: WebStyles.inkLight, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
