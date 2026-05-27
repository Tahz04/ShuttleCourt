import 'package:flutter_test/flutter_test.dart';
import 'package:shuttlecourt/auth/auth_service.dart';

void main() {
  group('AuthService - State Management', () {
    late AuthService auth;

    setUp(() {
      auth = AuthService();
    });

    test('Ban đầu chưa đăng nhập', () {
      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);
      expect(auth.isLoading, isFalse);
      expect(auth.errorMessage, isNull);
    });

    test('Logout → xóa user và error', () {
      auth.logout();
      expect(auth.isAuthenticated, isFalse);
      expect(auth.user, isNull);
      expect(auth.errorMessage, isNull);
    });

    test('clearError → xóa errorMessage', () {
      auth.clearError();
      expect(auth.errorMessage, isNull);
    });

    test('Login email rỗng → set errorMessage', () async {
      final result = await auth.login('', 'password123');
      expect(result, isFalse);
      expect(auth.errorMessage, 'Email không được để trống');
    });

    test('Login email không hợp lệ → set errorMessage', () async {
      final result = await auth.login('invalid-email', 'password123');
      expect(result, isFalse);
      expect(auth.errorMessage, 'Email không hợp lệ');
    });

    test('Login password rỗng → set errorMessage', () async {
      final result = await auth.login('test@example.com', '');
      expect(result, isFalse);
      expect(auth.errorMessage, 'Mật khẩu không được để trống');
    });

    test('Login password quá ngắn → set errorMessage', () async {
      final result = await auth.login('test@example.com', '12345');
      expect(result, isFalse);
      expect(auth.errorMessage, 'Mật khẩu phải ít nhất 6 ký tự');
    });

    test('Register fullName rỗng → set errorMessage', () async {
      final result = await auth.register(
        'test@example.com', 'Test@1234', '', '0912345678',
      );
      expect(result, isFalse);
      expect(auth.errorMessage, 'Họ tên không được để trống');
    });

    test('Register email rỗng → set errorMessage', () async {
      final result = await auth.register(
        '', 'Test@1234', 'Nguyễn Văn A', '0912345678',
      );
      expect(result, isFalse);
      expect(auth.errorMessage, 'Email không được để trống');
    });

    test('Register phone không hợp lệ → set errorMessage', () async {
      final result = await auth.register(
        'test@example.com', 'Test@1234', 'Nguyễn Văn A', '12345',
      );
      expect(result, isFalse);
      expect(auth.errorMessage, isNotNull);
    });

    test('Register password yếu → set errorMessage', () async {
      final result = await auth.register(
        'test@example.com', 'weak', 'Nguyễn Văn A', '0912345678',
      );
      expect(result, isFalse);
      expect(auth.errorMessage, isNotNull);
    });

    test('upgradeToOwner khi chưa login → false', () async {
      final result = await auth.upgradeToOwner();
      expect(result, isFalse);
    });

    test('updatePassword khi chưa login → false', () async {
      final result = await auth.updatePassword('old', 'new');
      expect(result, isFalse);
    });

    test('Notify listeners khi state thay đổi', () {
      int notifyCount = 0;
      auth.addListener(() => notifyCount++);

      auth.logout();
      expect(notifyCount, 1);

      auth.clearError();
      expect(notifyCount, 2);
    });
  });
}
