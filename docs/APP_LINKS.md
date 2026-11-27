# Mở công thức trong app Android

## Contract

Link chia sẻ giữ dạng `https://bepxinh-b0be7.web.app/recipe/{id}`. Android đã cài
bản app có manifest mới và xác minh domain thành công sẽ chuyển link vào app.
Người chưa cài app dùng cùng URL để xem bản web. Đường dẫn đánh giá
`/recipe/{id}/reviews` cũng thuộc phạm vi này.

`AndroidManifest.xml` khai báo `VIEW`, `DEFAULT`, `BROWSABLE`, `autoVerify=true`,
HTTPS, đúng host trên và `pathPrefix=/recipe/`. `flutter_deeplinking_enabled=true`
để Flutter chuyển URL vào `GoRouter` của `AppBepXinh`, không thêm plugin xử lý link
thứ hai. `singleTop` tiếp tục nhận link khi app đang chạy. Router hiện có xử lý
đúng cả URL khởi động và URL mới; không ép link công khai về màn đăng nhập.

Luồng xem công thức công khai và guard xác thực hiện có giữ nguyên. Link không cấp
thêm quyền xem bài chờ duyệt/ẩn hoặc thực hiện thao tác cần đăng nhập. Không đổi
Firestore Rules, schema, Google sign-in hoặc nút share/copy. Phạm vi cấu hình lần
này là Android; iOS Universal Links chưa cấu hình. Không có deferred install link.

## Liên kết website và chữ ký app

File `web/.well-known/assetlinks.json` gắn website với package hiện tại
`com.example.app_bep_xinh`. SHA-256 đã đối chiếu lại bằng keytool và bằng
`apksigner verify --print-certs` trên APK debug build từ source mới:

```text
70:02:EE:FD:33:AA:6A:9F:21:7E:8A:EA:38:9D:BB:60:08:37:38:0C:17:DA:92:D4:5C:78:59:B4:18:E4:80:53
```

Gradle hiện ký cả bản release bằng debug key này. Khi chuyển sang chứng chỉ
release/Play App Signing, thêm SHA-256 thực tế vào mảng fingerprints và phát hành
lại file xác minh. Không thay applicationId hoặc cấu hình ký trong nhiệm vụ này.

Flutter build sao chép file từ `web/.well-known` vào `build/web/.well-known`.
Hosting bỏ mẫu ignore toàn bộ dotfile để không loại mất `.well-known`, vẫn loại
`.git`, `.DS_Store`, node_modules và firebase.json. Header riêng trả JSON và cache
300 giây. URL xác minh bắt buộc trả 200 trực tiếp, không redirect hoặc SPA HTML.

## Phát hành file xác minh riêng

Tool dùng phiên Firebase CLI đã đăng nhập, không nhận hoặc in token. Mặc định chỉ
đọc bản live và in kế hoạch. `--apply` sao chép bản live, thêm đúng assetlinks và
header cho file đó; đối chiếu hash toàn bộ các file còn lại trước khi phát hành.
Dừng nếu bản live thay đổi trong lúc chuẩn bị. Cách này giữ nội dung app web đang
live khi chỉ cần cập nhật liên kết Android. Bản clone chưa phát hành không tác động
người dùng; release chỉ tạo sau khi kiểm tra xong.

```powershell
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/deploy_app_links.cjs
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- node tool/deploy_app_links.cjs --apply
node tool/deploy_app_links.cjs --verify
```

Lần deploy Hosting đầy đủ sau này dùng `firebase.json` cùng artifact build mới;
không dùng một thư mục build cũ thiếu assetlinks. Cài APK mới để cập nhật intent
filter; hot reload/hot restart không thay manifest của app đã cài.

## Kiểm tra thiết bị

```powershell
flutter build apk --debug --no-pub
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell pm verify-app-links --re-verify com.example.app_bep_xinh
adb shell pm get-app-links com.example.app_bep_xinh
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://bepxinh-b0be7.web.app/recipe/RECIPE_ID"
```

Dùng ID công thức công khai có thật, đợi Android xác minh và kiểm tra domain có
trạng thái `verified`. Thử bấm link từ ứng dụng khác khi app đã đóng và đang chạy;
thử link khác khi đang xem món đầu. Chạy am start với package chỉ định chỉ kiểm
tra intent/router, không chứng minh domain được xác minh tự động. Khi gỡ app,
cùng URL phải tiếp tục mở được bản web. Lệnh adb không được tự ý ép trạng thái
verified để coi đó là kết quả xác minh thật.

Tham khảo: [Flutter App Links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links),
[Android website association](https://developer.android.com/training/app-links/configure-assetlinks),
[Firebase Hosting REST](https://firebase.google.com/docs/hosting/api-deploy).

## Kết quả ngày 27/11/2026

- APK debug mới build thành công ở `build/app/outputs/flutter-apk/app-debug.apk`.
  Kiểm tra packaged manifest có autoVerify, host/path và Flutter deep linking;
  `apksigner` xác nhận SHA-256 khớp file association.
- 7 test điều hướng/xác thực đạt: cold launch bằng HTTPS URL chia sẻ thật, nhận
  link món khác lúc đang chạy, khách xem công thức, private route vẫn yêu cầu
  đăng nhập và tiếp tục đúng đích sau xác thực.
- Analyzer không phát sinh issue mới; còn 5 issue có sẵn ở AI chat/login/kitchen
  overview/messages. Formatter, kiểm tra cú pháp tool và `git diff --check` đạt.
- Đã phát hành association lên Hosting, version `14bfacd35e7d999d`, từ bản live
  `adc9e56bb9ed8296`. Tool đối chiếu hash giữ nguyên 74 file hiện có trước release;
  thêm file xác minh và header của nó. GET công khai trả 200, JSON khớp source,
  không redirect.
- `adb devices` không có thiết bị đang kết nối. Chưa xác minh trạng thái verified
  trên Android hoặc thử bấm link từ ứng dụng khác; cần cài bản APK mới và thực hiện
  các lệnh ở trên. Kết quả test router và file công khai không thay thế kiểm tra này.
