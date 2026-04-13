import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background accent element
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.1), AppTheme.accent.withOpacity(0.05)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo / Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.glowShadow,
                      ),
                      child: const Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Center(
                    child: Text(
                      'ShuttleCourt',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Hệ thống đặt sân chuyên nghiệp',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vui lòng nhập thông tin tài khoản của bạn',
                    style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Email Field
                  _buildTextField(
                    label: 'Email',
                    hint: 'yourname@email.com',
                    icon: Icons.alternate_email_rounded,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password Field
                  _buildTextField(
                    label: 'Mật khẩu',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Error Message
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      if (auth.errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Login Button
                  Consumer<AuthService>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                              : const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Register Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Chưa có tài khoản? ', style: TextStyle(color: AppTheme.textSecondary)),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
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

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w400),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.login(_emailController.text, _passwordController.text);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
