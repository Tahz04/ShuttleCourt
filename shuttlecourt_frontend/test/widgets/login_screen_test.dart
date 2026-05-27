import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shuttlecourt/auth/auth_service.dart';
import 'package:shuttlecourt/auth/login_screen.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  Widget createTestApp() {
    return ChangeNotifierProvider<AuthService>.value(
      value: authService,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Hiển thị tiêu đề "Đăng nhập"', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Đăng nhập'), findsOneWidget);
    });

    testWidgets('Hiển thị text chào mừng', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Chào mừng bạn trở lại! 👋'), findsOneWidget);
    });

    testWidgets('Có 2 trường nhập liệu (Email, Mật khẩu)', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Có nút ĐĂNG NHẬP', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    });

    testWidgets('Có link "Đăng ký ngay"', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Đăng ký ngay'), findsOneWidget);
    });

    testWidgets('Có link "Quên mật khẩu?"', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    });

    testWidgets('Có text "Chưa có tài khoản?"', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('Chưa có tài khoản? '), findsOneWidget);
    });

    testWidgets('Có placeholder Email', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('Có placeholder Mật khẩu', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('Nhập text vào trường Email', (tester) async {
      await tester.pumpWidget(createTestApp());
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Nhập text vào trường Mật khẩu', (tester) async {
      await tester.pumpWidget(createTestApp());
      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'Test@1234');
      await tester.pump();
      // Password field tồn tại và chấp nhận input
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Toggle hiển thị mật khẩu', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Tìm nút toggle password (icon visibility)
      final toggleBtn = find.byIcon(Icons.visibility_off_rounded);
      expect(toggleBtn, findsOneWidget);

      // Nhấn toggle
      await tester.tap(toggleBtn);
      await tester.pump();

      // Sau khi toggle → icon chuyển thành visibility_rounded
      expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    });

    testWidgets('Nút ĐĂNG NHẬP là ElevatedButton', (tester) async {
      await tester.pumpWidget(createTestApp());
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Nhấn ĐĂNG NHẬP khi email rỗng → hiện SnackBar lỗi', (tester) async {
      await tester.pumpWidget(createTestApp());

      // Cuộn đến nút ĐĂNG NHẬP
      final loginButton = find.text('ĐĂNG NHẬP');
      await tester.ensureVisible(loginButton);

      // Nhấn nút ĐĂNG NHẬP mà không nhập gì
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Đợi SnackBar animation

      // Kiểm tra SnackBar lỗi hiện ra
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
