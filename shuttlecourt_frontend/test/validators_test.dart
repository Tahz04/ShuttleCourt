import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/utils/validators.dart';

/// ============================================================
/// UNIT TEST: Validators (Email, Password, Phone, FullName)
/// File gốc: lib/utils/validators.dart
/// ============================================================
void main() {
  // ────────────────────────────────────────────────────────────
  // 1. TEST VALIDATE EMAIL
  // ────────────────────────────────────────────────────────────
  group('Validators.validateEmail', () {
    test('Email null → trả về lỗi "không được để trống"', () {
      expect(Validators.validateEmail(null), 'Email không được để trống');
    });

    test('Email rỗng → trả về lỗi "không được để trống"', () {
      expect(Validators.validateEmail(''), 'Email không được để trống');
    });

    test('Email hợp lệ cơ bản → trả về null', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
    });

    test('Email có dấu chấm trong local part → hợp lệ', () {
      expect(Validators.validateEmail('user.name@gmail.com'), isNull);
    });

    test('Email có dấu + → hợp lệ', () {
      expect(Validators.validateEmail('user+tag@domain.org'), isNull);
    });

    test('Email domain nhiều phần → hợp lệ', () {
      expect(Validators.validateEmail('user@domain.co.uk'), isNull);
    });

    test('Email thiếu @ → không hợp lệ', () {
      expect(Validators.validateEmail('userexample.com'), 'Email không hợp lệ');
    });

    test('Email thiếu domain → không hợp lệ', () {
      expect(Validators.validateEmail('user@'), 'Email không hợp lệ');
    });

    test('Email thiếu local part → không hợp lệ', () {
      expect(Validators.validateEmail('@domain.com'), 'Email không hợp lệ');
    });

    test('Email thiếu TLD → không hợp lệ', () {
      expect(Validators.validateEmail('user@domain'), 'Email không hợp lệ');
    });

    test('Email có khoảng trắng → không hợp lệ', () {
      expect(Validators.validateEmail('user @domain.com'), 'Email không hợp lệ');
    });

    test('Email TLD chỉ 1 ký tự → không hợp lệ', () {
      expect(Validators.validateEmail('user@domain.c'), 'Email không hợp lệ');
    });
  });

  // ────────────────────────────────────────────────────────────
  // 2. TEST VALIDATE PASSWORD LOGIN
  // ────────────────────────────────────────────────────────────
  group('Validators.validatePasswordLogin', () {
    test('Password null → trả về lỗi', () {
      expect(
        Validators.validatePasswordLogin(null),
        'Mật khẩu không được để trống',
      );
    });

    test('Password rỗng → trả về lỗi', () {
      expect(
        Validators.validatePasswordLogin(''),
        'Mật khẩu không được để trống',
      );
    });

    test('Password 5 ký tự → trả về lỗi (< 6)', () {
      expect(
        Validators.validatePasswordLogin('12345'),
        'Mật khẩu phải ít nhất 6 ký tự',
      );
    });

    test('Password đúng 6 ký tự → hợp lệ', () {
      expect(Validators.validatePasswordLogin('123456'), isNull);
    });

    test('Password 10 ký tự → hợp lệ', () {
      expect(Validators.validatePasswordLogin('1234567890'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 3. TEST VALIDATE PASSWORD REGISTER (Nâng cao)
  // ────────────────────────────────────────────────────────────
  group('Validators.validatePasswordRegister', () {
    test('Password null → trả về lỗi', () {
      expect(
        Validators.validatePasswordRegister(null),
        'Mật khẩu không được để trống',
      );
    });

    test('Password rỗng → trả về lỗi', () {
      expect(
        Validators.validatePasswordRegister(''),
        'Mật khẩu không được để trống',
      );
    });

    test('Password 3 ký tự → trả về lỗi (< 8)', () {
      expect(
        Validators.validatePasswordRegister('Ab1'),
        'Mật khẩu phải ít nhất 8 ký tự',
      );
    });

    test('Password không có chữ HOA → trả về lỗi', () {
      expect(
        Validators.validatePasswordRegister('abcdefg1'),
        'Mật khẩu phải chứa ít nhất 1 chữ cái in hoa',
      );
    });

    test('Password không có chữ thường → trả về lỗi', () {
      expect(
        Validators.validatePasswordRegister('ABCDEFG1'),
        'Mật khẩu phải chứa ít nhất 1 chữ cái thường',
      );
    });

    test('Password không có chữ số → trả về lỗi', () {
      expect(
        Validators.validatePasswordRegister('AbcDefGh'),
        'Mật khẩu phải chứa ít nhất 1 chữ số',
      );
    });

    test('Password "Test@1234" → hợp lệ', () {
      expect(Validators.validatePasswordRegister('Test@1234'), isNull);
    });

    test('Password đúng 8 ký tự "Aa1bCd2e" → hợp lệ', () {
      expect(Validators.validatePasswordRegister('Aa1bCd2e'), isNull);
    });

    test('Password dài phức tạp → hợp lệ', () {
      expect(Validators.validatePasswordRegister('MyP@ssw0rd123!!'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 4. TEST VALIDATE CONFIRM PASSWORD
  // ────────────────────────────────────────────────────────────
  group('Validators.validateConfirmPassword', () {
    test('Confirm null → trả về lỗi', () {
      expect(
        Validators.validateConfirmPassword('Test@1234', null),
        'Xác nhận mật khẩu không được để trống',
      );
    });

    test('Confirm rỗng → trả về lỗi', () {
      expect(
        Validators.validateConfirmPassword('Test@1234', ''),
        'Xác nhận mật khẩu không được để trống',
      );
    });

    test('Confirm khớp → hợp lệ (null)', () {
      expect(
        Validators.validateConfirmPassword('Test@1234', 'Test@1234'),
        isNull,
      );
    });

    test('Confirm không khớp → trả về lỗi', () {
      expect(
        Validators.validateConfirmPassword('Test@1234', 'Test@12345'),
        'Mật khẩu xác nhận không khớp',
      );
    });

    test('Confirm khác case → trả về lỗi (case-sensitive)', () {
      expect(
        Validators.validateConfirmPassword('Test@1234', 'test@1234'),
        'Mật khẩu xác nhận không khớp',
      );
    });
  });

  // ────────────────────────────────────────────────────────────
  // 5. TEST VALIDATE FULL NAME
  // ────────────────────────────────────────────────────────────
  group('Validators.validateFullName', () {
    test('Họ tên null → trả về lỗi', () {
      expect(
        Validators.validateFullName(null),
        'Họ tên không được để trống',
      );
    });

    test('Họ tên rỗng → trả về lỗi', () {
      expect(Validators.validateFullName(''), 'Họ tên không được để trống');
    });

    test('Họ tên 2 ký tự (sau trim) → trả về lỗi', () {
      expect(
        Validators.validateFullName('AB'),
        'Họ tên phải ít nhất 3 ký tự',
      );
    });

    test('Họ tên toàn khoảng trắng "  " → trả về lỗi', () {
      expect(
        Validators.validateFullName('  '),
        'Họ tên phải ít nhất 3 ký tự',
      );
    });

    test('Họ tên 3 ký tự → hợp lệ', () {
      expect(Validators.validateFullName('ABC'), isNull);
    });

    test('Họ tên tiếng Việt → hợp lệ', () {
      expect(Validators.validateFullName('Nguyễn Văn A'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 6. TEST VALIDATE PHONE NUMBER (Việt Nam)
  // ────────────────────────────────────────────────────────────
  group('Validators.validatePhoneNumber', () {
    test('SĐT null → trả về lỗi', () {
      expect(
        Validators.validatePhoneNumber(null),
        'Số điện thoại không được để trống',
      );
    });

    test('SĐT rỗng → trả về lỗi', () {
      expect(
        Validators.validatePhoneNumber(''),
        'Số điện thoại không được để trống',
      );
    });

    test('SĐT hợp lệ "0912345678" → null', () {
      expect(Validators.validatePhoneNumber('0912345678'), isNull);
    });

    test('SĐT đầu 08 "0812345678" → hợp lệ', () {
      expect(Validators.validatePhoneNumber('0812345678'), isNull);
    });

    test('SĐT đầu 07 "0712345678" → hợp lệ', () {
      expect(Validators.validatePhoneNumber('0712345678'), isNull);
    });

    test('SĐT không bắt đầu 0 → không hợp lệ', () {
      final result = Validators.validatePhoneNumber('1234567890');
      expect(result, isNotNull);
    });

    test('SĐT 9 số (thiếu) → không hợp lệ', () {
      final result = Validators.validatePhoneNumber('091234567');
      expect(result, isNotNull);
    });

    test('SĐT 11 số (thừa) → không hợp lệ', () {
      final result = Validators.validatePhoneNumber('09123456789');
      expect(result, isNotNull);
    });

    test('SĐT chứa chữ → không hợp lệ', () {
      final result = Validators.validatePhoneNumber('091234abcd');
      expect(result, isNotNull);
    });

    test('SĐT format quốc tế "+84..." → không hợp lệ', () {
      final result = Validators.validatePhoneNumber('+84912345678');
      expect(result, isNotNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // 7. TEST VALIDATE TERMS AGREEMENT
  // ────────────────────────────────────────────────────────────
  group('Validators.validateTermsAgreement', () {
    test('Chưa đồng ý → trả về lỗi', () {
      expect(
        Validators.validateTermsAgreement(false),
        'Bạn phải đồng ý với Điều khoản & Chính sách',
      );
    });

    test('Đã đồng ý → hợp lệ (null)', () {
      expect(Validators.validateTermsAgreement(true), isNull);
    });
  });
}
