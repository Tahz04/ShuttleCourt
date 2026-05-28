import 'package:flutter/material.dart';
import 'package:shuttlecourt/booking/booking_screen.dart';
import 'package:shuttlecourt/models/badminton_court.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

/// Shows a centered court-detail dialog on web.
/// Pass [distanceKm] = 0 to hide the distance badge.
void showCourtDetailDialog(
  BuildContext context,
  BadmintonCourt court, {
  double distanceKm = 0,
}) {
  showDialog(
    context: context,
    builder: (_) => WebCourtDetailDialog(
      court: court,
      distanceKm: distanceKm,
      onBook: () {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookingScreen(initialCourt: court)),
        );
      },
    ),
  );
}

class WebCourtDetailDialog extends StatelessWidget {
  final BadmintonCourt court;
  final double distanceKm;
  final VoidCallback onBook;

  static const String _placeholder =
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=70';

  const WebCourtDetailDialog({
    super.key,
    required this.court,
    required this.distanceKm,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final isMaintenance = court.status == 'maintenance';
    final imageUrl = (court.mainImage != null && court.mainImage!.isNotEmpty)
        ? court.mainImage!
        : _placeholder;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image Header ──────────────────────────────────
              Stack(
                children: [
                  // Court image (200px tall, full width)
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppTheme.primary, strokeWidth: 2),
                              ),
                            ),
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        child: const Center(
                          child: Icon(Icons.sports_tennis_rounded,
                              size: 60, color: AppTheme.primary),
                        ),
                      ),
                    ),
                  ),
                  // Gradient overlay bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    bottom: 14,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${(court.pricePerHour / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const TextSpan(
                              text: '/giờ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    bottom: 14,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 4),
                          Text(
                            court.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Content ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            court.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMaintenance
                                ? AppTheme.error.withValues(alpha: 0.1)
                                : AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isMaintenance ? 'Bảo trì' : 'Hoạt động',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isMaintenance
                                  ? AppTheme.error
                                  : AppTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Address + distance
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            court.address,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.4),
                          ),
                        ),
                        if (distanceKm > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Reviews row
                    Row(
                      children: [
                        const Icon(Icons.reviews_outlined,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          '${court.reviews} đánh giá',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                        ),
                      ],
                    ),

                    // Amenities
                    if (court.amenities.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'TIỆN ÍCH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: court.amenities
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],

                    // Additional images
                    if ((court.descImage1 != null && court.descImage1!.isNotEmpty) ||
                        (court.descImage2 != null && court.descImage2!.isNotEmpty)) ...[
                      const SizedBox(height: 18),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      const SizedBox(height: 16),
                      const Text(
                        'ẢNH SÂN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (court.descImage1 != null && court.descImage1!.isNotEmpty)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  court.descImage1!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          if (court.descImage1 != null &&
                              court.descImage1!.isNotEmpty &&
                              court.descImage2 != null &&
                              court.descImage2!.isNotEmpty)
                            const SizedBox(width: 8),
                          if (court.descImage2 != null && court.descImage2!.isNotEmpty)
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  court.descImage2!,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(
                                  color: AppTheme.borderLight),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Đóng',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isMaintenance ? null : onBook,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.highlight,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.textMuted,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Đặt ngay',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
