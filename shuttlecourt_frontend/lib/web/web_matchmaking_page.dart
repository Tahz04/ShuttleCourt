import 'package:flutter/material.dart';
import 'package:shuttlecourt/theme/app_theme.dart';
import 'package:shuttlecourt/models/match_model.dart';
import 'package:shuttlecourt/features/matchmaking/services/matchmaking_service.dart';
import 'package:shuttlecourt/features/matchmaking/screens/create_match_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/web/web_navbar.dart';

/// Web-optimized matchmaking/Find Match page with compact grid layout
class WebMatchmakingPage extends StatefulWidget {
  final Function(int)? onTabChange;

  const WebMatchmakingPage({super.key, this.onTabChange});

  @override
  State<WebMatchmakingPage> createState() => _WebMatchmakingPageState();
}

class _WebMatchmakingPageState extends State<WebMatchmakingPage> {
  String selectedLevel = 'Tất cả';
  late Future<List<MatchModel>> _matchesFuture;

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
      backgroundColor: AppTheme.scaffoldLight,
      body: Column(
        children: [
          WebNavbar(
            selectedIndex: 4,
            onNavTap: (index) => widget.onTabChange?.call(index),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tìm Kèo Ghép Cầu Lông',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kết nối với những đồng đội có cùng đam mê cầu lông',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter chips
                  _buildFilterSection(),

                  // Matches grid
                  FutureBuilder<List<MatchModel>>(
                    future: _matchesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                            ),
                          ),
                        );
                      }

                      final matches = snapshot.data ?? [];
                      final filteredMatches = selectedLevel == 'Tất cả'
                          ? matches
                          : matches
                                .where((m) => m.level == selectedLevel)
                                .toList();

                      if (filteredMatches.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 56,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có kèo nào được đăng',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: filteredMatches.length,
                          itemBuilder: (context, index) {
                            return _buildCompactMatchCard(
                              filteredMatches[index],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildCreateMatchFab(),
    );
  }

  Widget _buildFilterSection() {
    final levels = ['Tất cả', 'Mới chơi', 'Trung bình', 'Khá', 'Pro'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: levels.map((level) {
            final isSelected = selectedLevel == level;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => setState(() => selectedLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.matchmakingGradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
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

  Widget _buildCompactMatchCard(MatchModel match) {
    final bool isPro = match.level == 'Pro' || match.level == 'Khá';
    final String dateStr = DateFormat('dd/MM').format(match.matchDate);
    final String timeStr = match.startTime.substring(0, 5);
    final double capacity = match.capacity.toDouble();
    final double joined = match.joinedCount.toDouble();
    final double fillPercent = joined / capacity;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with level and price
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isPro ? AppTheme.warning : AppTheme.success)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.level.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isPro ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(match.price)}đ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // Court name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              match.courtName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 8),

          // Date/time and capacity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 13,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$dateStr • $timeStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 13,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${match.joinedCount}/${match.capacity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillPercent,
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            fillPercent > 0.8
                                ? Colors.orange
                                : fillPercent > 0.5
                                ? AppTheme.accent
                                : AppTheme.success,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Host and join button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chủ: ${match.hostName}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => _handleJoinMatch(match),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tham gia',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateMatchFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppTheme.accent,
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
        );
        if (result == true) _refreshMatches();
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Tạo Kèo',
        style: TextStyle(fontWeight: FontWeight.w700),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bạn là chủ kèo này rồi!')));
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
          content: Text(
            success ? '✅ Yêu cầu đã gửi!' : '❌ Lỗi, vui lòng thử lại',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
      if (success) _refreshMatches();
    }
  }
}
