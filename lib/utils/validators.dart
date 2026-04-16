class Validators {
  // Kiểm tra email hợp lệ
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email không được để trống';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  // Kiểm tra mật khẩu (đăng nhập)
  static String? validatePasswordLogin(String? password) {
    if (password == null || password.isEmpty) {
      return 'Mật khẩu không được để trống';
    }

    if (password.length < 6) {
      return 'Mật khẩu phải ít nhất 6 ký tự';
    }

    return null;
  }

  // Kiểm tra mật khẩu (đăng ký) - nâng cao
  static String? validatePasswordRegister(String? password) {
    if (password == null || password.isEmpty) {
      return 'Mật khẩu không được để trống';
    }

    if (password.length < 8) {
      return 'Mật khẩu phải ít nhất 8 ký tự';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái in hoa';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái thường';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số';
    }

    return null;
  }

  // Kiểm tra xác nhận mật khẩu
  static String? validateConfirmPassword(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Xác nhận mật khẩu không được để trống';
    }

    if (password != confirmPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }

  // Kiểm tra họ tên
  static String? validateFullName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return 'Họ tên không được để trống';
    }

    if (fullName.trim().length < 3) {
      return 'Họ tên phải ít nhất 3 ký tự';
    }

    return null;
  }

  // Kiểm tra số điện thoại Việt Nam
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Số điện thoại không được để trống';
    }

    // Pattern cho số điện thoại Việt Nam: 09xxxxxxx, 08xxxxxxx, 07xxxxxxx, etc.
    final phoneRegex = RegExp(r'^0[0-9]{9}$');

    if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s'), ''))) {
      return 'Số điện thoại không hợp lệ (định dạng: 09xxxxxxx)';
    }

    return null;
  }

  // Kiểm tra checkbox đồng ý điều khoản
  static String? validateTermsAgreement(bool agreed) {
    if (!agreed) {
      return 'Bạn phải đồng ý với Điều khoản & Chính sách';
    }
    return null;
  }
}
