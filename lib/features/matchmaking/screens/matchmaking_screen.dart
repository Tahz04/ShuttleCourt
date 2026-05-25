import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/features/matchmaking/screens/create_match_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with TickerProviderStateMixin {
  String selectedLevel = 'Tất cả';
  late final AnimationController _animController;
  late Future<List<MatchModel>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _refreshMatches();
  }

  void _refreshMatches() {
    setState(() {
      _matchesFuture = MatchmakingService.getAllMatches();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(child: _buildWelcomeHeader()),
              SliverToBoxAdapter(child: _buildFilterSection()),
              FutureBuilder<List<MatchModel>>(
                future: _matchesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
                    );
                  }
                  
                  final matches = snapshot.data ?? [];
                  final filteredMatches = selectedLevel == 'Tất cả' 
                      ? matches 
                      : matches.where((m) => m.level == selectedLevel).toList();

                  if (filteredMatches.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('Chưa có kèo nào được đăng.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final delay = index * 0.1;
                          return _buildAnimatedCard(filteredMatches[index], delay);
                        },
                        childCount: filteredMatches.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Kèo Ghép Cầu Lông',
        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sẵn sàng ra sân?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary, letterSpacing: -0.8),
          ),
          const SizedBox(height: 4),
          Text(
            'Tìm đồng đội cùng trình độ và đam mê ngay hôm nay',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final levels = ['Tất cả', 'Mới chơi', 'Trung bình', 'Khá', 'Pro'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: levels.map((level) {
            final bool isSelected = selectedLevel == level;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.matchmakingGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected ? AppTheme.glowShadowColor(const Color(0xFF2196F3)) : [],
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade100, width: 1.5),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(MatchModel match, double delay) {
    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(delay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        child: _buildMatchCard(match),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    final bool isPro = match.level == 'Pro' || match.level == 'Khá';
    final String dateStr = DateFormat('dd/MM').format(match.matchDate);
    final String timeStr = match.startTime.substring(0, 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isPro ? AppTheme.warning : AppTheme.success).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        match.level.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isPro ? AppTheme.warning : AppTheme.success),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(match.price)}đ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  match.courtName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 14, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      '$dateStr lúc $timeStr',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      'Đã có ${match.joinedCount}/${match.capacity}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldLight.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusXl)),
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_pin_rounded, size: 20, color: AppTheme.accent),
                const SizedBox(width: 10),
                Text('Host: ${match.hostName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _handleJoinMatch(match),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppTheme.accent,
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Tham gia', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateMatchScreen()));
              if (result == true) _refreshMatches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_location_alt_rounded),
                SizedBox(width: 12),
                Text('TẠO KÈO GHÉP MỚI', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleJoinMatch(MatchModel match) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tham gia kèo!')),
      );
      return;
    }

    if (auth.user!.id == match.hostId.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn là chủ kèo này rồi!')),
      );
      return;
    }

    final success = await MatchmakingService.requestJoin(
      userId: int.parse(auth.user!.id),
      matchId: match.id,
      hostId: match.hostId,
      senderName: auth.user!.fullName,
      courtName: match.courtName,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? 'Đã gửi yêu cầu ghép kèo! Đang chờ chủ sân phê duyệt.' 
            : 'Gửi yêu cầu thất bại. Vui lòng thử lại.'),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }
}