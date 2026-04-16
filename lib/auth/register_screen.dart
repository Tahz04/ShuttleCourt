import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quynh/auth/auth_service.dart';
import 'package:quynh/theme/app_theme.dart';
import 'package:quynh/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tham gia ngay',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tạo tài khoản để bắt đầu đặt sân và ghép kèo',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                label: 'Họ tên',
                hint: 'Nguyễn Văn A',
                icon: Icons.person_outline_rounded,
                controller: _fullNameController,
              ),
              const SizedBox(height: 18),

              _buildTextField(
                label: 'Email',
                hint: 'example@email.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailController,
              ),
              const SizedBox(height: 18),

              _buildTextField(
                label: 'Số điện thoại',
                hint: '09xxxxxxx',
                icon: Icons.phone_android_rounded,
                controller: _phoneController,
              ),
              const SizedBox(height: 18),

              _buildTextField(
                label: 'Mật khẩu',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                onToggleVisibility: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 18),

              _buildTextField(
                label: 'Xác nhận mật khẩu',
                hint: '••••••••',
                icon: Icons.lock_reset_rounded,
                controller: _confirmPasswordController,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreeTerms,
                      onChanged: (v) =>
                          setState(() => _agreeTerms = v ?? false),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tôi đồng ý với các Điều khoản & Chính sách',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Consumer<AuthService>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (auth.isLoading || !_agreeTerms)
                          ? null
                          : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : const Text(
                              'ĐĂNG KÝ TÀI KHOẢN',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
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
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey,
                      ),
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

  void _handleRegister() async {
    // Validation - Họ tên
    final fullNameError = Validators.validateFullName(_fullNameController.text);
    if (fullNameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fullNameError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation - Email
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation - Số điện thoại
    final phoneError = Validators.validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation - Mật khẩu
    final passwordError = Validators.validatePasswordRegister(
      _passwordController.text,
    );
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation - Xác nhận mật khẩu
    final confirmPasswordError = Validators.validateConfirmPassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (confirmPasswordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmPasswordError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validation - Đồng ý điều khoản
    final termsError = Validators.validateTermsAgreement(_agreeTerms);
    if (termsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(termsError),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.register(
      _emailController.text,
      _passwordController.text,
      _fullNameController.text,
      _phoneController.text,
    );
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
