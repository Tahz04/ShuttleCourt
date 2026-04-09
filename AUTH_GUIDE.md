# Hướng Dẫn Tính Năng Đăng Nhập/Đăng Xuất

## Giới Thiệu
Tôi đã tạo một hệ thống đầy đủ cho tính năng đăng nhập/đăng xuất với các màn hình sau:

## 📁 Các File Tạo Mới

### 1. **auth_service.dart** - Quản lý xác thực
- Quản lý trạng thái đăng nhập của người dùng
- Hàm `login()` - Đăng nhập với email và mật khẩu
- Hàm `register()` - Đăng ký tài khoản mới
- Hàm `logout()` - Đăng xuất
- Sử dụng Provider (ChangeNotifier) để quản lý trạng thái

### 2. **login_screen.dart** - Trang đăng nhập
Tính năng:
- Nhập email và mật khẩu
- Hiển thị/ẩn mật khẩu
- Checkbox "Nhớ mật khẩu"
- Liên kết "Quên mật khẩu"
- Liên kết đến trang đăng ký
- Hiển thị lỗi xác thực
- Loading indicator khi đăng nhập

### 3. **register_screen.dart** - Trang đăng ký
Tính năng:
- Nhập thông tin: Họ tên, Email, Số điện thoại
- Nhập mật khẩu và xác nhận mật khẩu
- Checkbox đồng ý Điều khoản dịch vụ
- Kiểm tra mật khẩu khớp nhau
- Hiển thị lỗi xác thực
- Loading indicator khi đăng ký

### 4. **profile_screen.dart** - Trang tài khoản
Tính năng:
- **Nếu chưa đăng nhập:** Hiển thị màn hình khuyến khích đăng nhập/đăng ký
- **Nếu đã đăng nhập:**
  - Hiển thị thông tin người dùng (Họ tên, Email, Số điện thoại)
  - Các mục cài đặt: Thay đổi mật khẩu, Địa chỉ, Thông báo, Quyền riêng tư
  - Các mục khác: Trợ giúp, Về ứng dụng
  - Nút đăng xuất có xác nhận

## 🔧 Cập Nhật File Hiện Có

### pubspec.yaml
Đã thêm dependency:
```yaml
provider: ^6.0.0
```

### main.dart
- Nhập package `provider`
- Wrap ứng dụng với `ChangeNotifierProvider` cho `AuthService`
- Import `ProfileScreen` từ file `auth/profile_screen.dart`
- Xóa class `ProfileScreen` cũ

## 🚀 Cách Sử Dụng

### 1. Cập nhật Dependencies
Chạy lệnh này để cài đặt package provider:
```bash
flutter pub get
```

### 2. Kiểm Tra Quy Trình Đăng Nhập
- Mở ứng dụng và nhấn vào tab "Tài khoản"
- Bạn sẽ thấy màn hình khuyến khích đăng nhập
- Nhấn "Đăng Nhập" hoặc "Đăng Ký" để bắt đầu

### 3. Thử Đăng Nhập
**Dữ liệu mô phỏng:**
- Email: bất kỳ email có định dạng hợp lệ (ví dụ: test@example.com)
- Mật khẩu: bất kỳ (tối thiểu 6 ký tự)

### 4. Đăng Xuất
Sau khi đăng nhập thành công:
- Nhấn nút "Đăng Xuất" (màu đỏ)
- Xác nhận trong hộp thoại

## ✨ Tính Năng Chính

✅ **Đăng nhập với email/mật khẩu**
✅ **Đăng ký tài khoản mới**
✅ **Quản lý trạng thái xác thực bằng Provider**
✅ **Hiển thị thông tin người dùng sau khi đăng nhập**
✅ **Đăng xuất an toàn**
✅ **Xác thực dữ liệu nhập vào**
✅ **Hiển thị thông báo lỗi**
✅ **Giao diện đẹp và thân thiện**

## 🔐 Lưu Ý Bảo Mật

Hiện tại, hệ thống sử dụng **mô phỏng (mock)** để xác thực. Để sử dụng với API thực tế:

1. Thay thế hàm `login()` trong `auth_service.dart` bằng API call thực tế
2. Sử dụng package như `http` hoặc `dio` để gọi API
3. Lưu token/session ID an toàn (sử dụng `flutter_secure_storage`)
4. Thêm kiểm tra JWT token hoặc session khi khởi động ứng dụng

## 📝 Tùy Chỉnh

### Thêm Trường Mới vào Đăng Ký
Chỉnh sửa file `register_screen.dart` để thêm trường mới và cập nhật hàm `register()` trong `auth_service.dart`

### Thay Đổi Màu Sắc
Tất cả các màu sử dụng `Colors.green` - bạn có thể thay đổi thành màu khác nếu cần

### Thêm Xác Minh Email
Cải tiến hàm `register()` để gửi email xác minh

## 🐛 Khắc Phục Sự Cố

Nếu gặp lỗi import:
- Đảm bảo các thư mục `auth/` tồn tại
- Chạy `flutter pub get` để cập nhật dependencies
- Kiểm tra đường dẫn import đúng: `package:quynh/auth/...`

## 📞 Hỗ Trợ

Nếu có thắc mắc hoặc cần sửa đổi, vui lòng cho biết!

