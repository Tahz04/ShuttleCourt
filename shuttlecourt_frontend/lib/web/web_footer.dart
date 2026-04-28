import 'package:flutter/material.dart';
import 'package:shuttlecourt/theme/app_theme.dart';

/// Clean web footer with links and branding
class WebFooter extends StatelessWidget {
  final Function(int)? onNavTap;
  const WebFooter({super.key, this.onNavTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Top row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand col
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.sports_tennis_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'ShuttleCourt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nền tảng đặt sân cầu lông\nhàng đầu Việt Nam.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white60,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SocialIcon(Icons.public, () {}),
                            const SizedBox(width: 10),
                            _SocialIcon(Icons.message, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick links
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điều hướng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FooterLink('Trang chủ', () => onNavTap?.call(0)),
                        _FooterLink('Tìm sân', () => onNavTap?.call(1)),
                        _FooterLink('Bản đồ', () => onNavTap?.call(2)),
                        _FooterLink('Đặt lịch', () => onNavTap?.call(3)),
                        _FooterLink('Ghép sân', () => onNavTap?.call(4)),
                        _FooterLink('Cửa hàng', () => onNavTap?.call(5)),
                      ],
                    ),
                  ),

                  // Support
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hỗ trợ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FooterLink('Câu hỏi thường gặp', null),
                        _FooterLink('Liên hệ hỗ trợ', null),
                        _FooterLink('Chính sách bảo mật', null),
                        _FooterLink('Điều khoản dịch vụ', null),
                      ],
                    ),
                  ),

                  // Contact
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Liên hệ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 14),
                        _ContactItem(
                          Icons.email_outlined,
                          'support@shuttlecourt.vn',
                        ),
                        SizedBox(height: 8),
                        _ContactItem(Icons.phone_outlined, '1900 xxx xxx'),
                        SizedBox(height: 8),
                        _ContactItem(
                          Icons.location_on_outlined,
                          'Hà Nội, Việt Nam',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(color: Colors.white24, thickness: 1, height: 1),
              const SizedBox(height: 20),

              // Bottom row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '© 2025 ShuttleCourt. All rights reserved.',
                    style: TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sports_tennis_rounded,
                        size: 14,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Made with ❤️ for badminton lovers',
                        style: TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink(this.label, this.onTap);

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
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
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : Colors.white60,
              fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.white60),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialIcon(this.icon, this.onTap);

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.25)
                : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
