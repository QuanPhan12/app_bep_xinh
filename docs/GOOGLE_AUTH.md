# Đăng nhập Google trong app Bếp Xinh

## Luồng

`GoogleSignInButton → LoginCubit.submitGoogleLogin → AccountGuardAuthService →
FirebaseAuthService → GoogleAuthClient → Firebase Authentication`.

Nút nằm ở form đăng nhập, dùng lại asset Google và AppTapHandler. Google và mật khẩu
dùng chung trạng thái loading để chặn thao tác trùng; form giữ email/password đã nhập.
Hủy bộ chọn Google hoặc đóng popup trả lại form, không hiện thông báo lỗi.

- Web dùng `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`, yêu cầu chọn tài khoản.
- Android/iOS dùng `google_sign_in` 7.2, lấy ID token và trao đổi bằng
  `FirebaseAuth.signInWithCredential`; không yêu cầu quyền đọc Contacts/Drive.
- Sau xác thực, `FirestoreUserStore.ensureAccount()` tạo hồ sơ nếu chưa có hoặc đọc
  lại hồ sơ cũ, không ghi đè name/bio/role/status. UID từ Firebase là định danh duy nhất.
- Guard chỉ công bố UID sau khi server xác nhận hồ sơ active; tài khoản locked không
  thể vượt qua bước chặn bằng đăng nhập Google. Lúc xác minh vẫn giữ form loading.
- Đăng xuất xóa phiên Firebase và phiên Google SDK native đã khởi tạo. Không revoke
  quyền Google của người dùng hoặc gọi disconnect toàn bộ grant.

Không tạo collection mới. Email/provider/credential nằm trong Firebase Auth, không
lưu mật khẩu Google hay ID/access token vào `users`. Không tự liên kết tài khoản
bằng so khớp email ở client; liên kết/trùng provider do Firebase xử lý.

## Cấu hình đã đối chiếu

Project `bepxinh-b0be7`, Google provider đã enabled. Web OAuth client:
`955775168150-mt01o910npu5rf06ckbn3hcqb3c5qnlg.apps.googleusercontent.com`.
Các client ID là định danh công khai; không đưa OAuth client secret vào app.

### Web

Firebase Web config và authDomain lấy từ `firebase_options.dart`. Domain localhost
và `bepxinh-b0be7.web.app` đã nằm trong authorized domains. Khi chạy local nên dùng
`localhost`; domain khác phải được đăng ký trước. Trình duyệt cần cho phép popup
từ trang app. Popup blocked/unauthorized domain có thông báo riêng.

### Android

Package `com.example.app_bep_xinh`; Firebase app ID
`1:955775168150:android:5eb936809cf6100b329cb7`.
Đã đăng ký SHA của debug keystore trên máy phát triển này:

```text
SHA-1:   C5:76:F5:6C:DD:64:69:09:F7:4E:13:9B:89:DB:C3:B8:B9:5A:57:6B
SHA-256: 70:02:EE:FD:33:AA:6A:9F:21:7E:8A:EA:38:9D:BB:60:08:37:38:0C:17:DA:92:D4:5C:78:59:B4:18:E4:80:53
```

`android/app/google-services.json` đã được tải lại và xác minh đúng project/app/package,
có OAuth client Android (`client_type: 1`) và Web (`client_type: 3`). Nếu thay keystore,
đổi máy có debug key khác hoặc dùng Play App Signing, đăng ký SHA của chứng chỉ thực
sự ký bản app đó và tải lại cấu hình. Không dùng SHA debug thay cho chứng chỉ release.

### iOS

Client ID từ Firebase iOS config:
`955775168150-jsju1g6j7alecatk52jn1n6qcidubtfu.apps.googleusercontent.com`.
`Info.plist` có `GIDClientID` và URL scheme đảo ngược tương ứng; đã đối chiếu với
config tải từ Firebase. Firebase vẫn khởi tạo bằng options Dart hiện có.
Cần macOS/Xcode và thiết bị/simulator để xác minh native iOS.

## Chạy và kiểm tra

Đây là thay đổi có plugin native: chạy `flutter pub get`, dừng app và chạy lại;
Hot Reload không cài plugin mới. Ví dụ `flutter run -d chrome` cho web.

Test kiểm tra lựa chọn popup/native, trao đổi token, thiếu token/hủy, đợi tạo hồ sơ,
khóa tài khoản, chống submit trùng và giữ form sau hủy. Test giả lập không chứng minh
đăng nhập OAuth thật trên thiết bị. Kiểm tra thủ công với Google account của người dùng:
chọn tài khoản, xác nhận về Home, đăng xuất/đăng nhập lại giữ UID; admin khóa tài khoản
rồi thử Google để xác nhận màn khóa và lý do. Không dùng tài khoản production để seed test.

Tham khảo: [Firebase Flutter Google Auth](https://firebase.google.com/docs/auth/flutter/federated-auth),
[plugin chính thức](https://pub.dev/packages/google_sign_in),
[Android](https://pub.dev/packages/google_sign_in_android),
[iOS](https://pub.dev/packages/google_sign_in_ios).
