# Firebase Bếp Xinh

Project: `bepxinh-b0be7`, project number: `955775168150`.
Firestore mặc định: Native mode, Standard edition, vùng `asia-southeast1`.

## Cấu hình ứng dụng

- Android: `com.example.app_bep_xinh`.
- iOS: `com.example.appBepXinh`.
- Web: app ID `1:955775168150:web:f661fb103e9ed7cd329cb7`.
- `lib/firebase_options.dart` được sinh bằng FlutterFire CLI; `main.dart` khởi tạo Firebase trước UI.
- Android dùng Google Services plugin, file `android/app/google-services.json`, quyền Internet và minSdk 24.
- iOS truyền options từ Dart, deployment target hiện tại là iOS 15. Cần macOS/Xcode để build và xác minh iOS.
- Chưa cấu hình desktop Windows/macOS/Linux.

Các file cấu hình client chứa định danh công khai, không phải service-account key.
Không đưa refresh token, service-account JSON hoặc mật khẩu vào source/dart-define.

Chạy ứng dụng với project thật:

```powershell
flutter pub get
flutter run -d chrome
```

Nếu đổi bundle/application ID hoặc thêm platform, chạy lại:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure --project=bepxinh-b0be7 --platforms=android,ios,web
```

## Authentication

Đã nối đăng ký, đăng nhập Email/Password, đăng nhập Google, gửi email đặt lại mật khẩu
và đăng xuất với Firebase Auth. Cấu hình Google: [GOOGLE_AUTH.md](GOOGLE_AUTH.md).
SDK quản lý và khôi phục phiên; ứng dụng không tự lưu mật khẩu/token.
Form giữ nguyên khoảng trắng trong mật khẩu, chỉ trim tên và email.
Thông báo khôi phục không khẳng định một email có tồn tại hay không.

`AuthService` là contract được inject vào Cubit; `FirebaseAuthService` gọi SDK và công bố thay đổi UID
qua `sessionChanges`. Router theo dõi notifier này; các route `/profile`, `/profile/edit`, `/settings`,
`/fridge`, `/cart`, `/recipes/new` yêu cầu đăng nhập, gồm cả truy cập trực tiếp bằng URL.
Home, tìm kiếm, chi tiết công thức và hồ sơ tác giả mẫu vẫn cho phép xem khi chưa đăng nhập.
Đăng nhập từ deep link sẽ trở lại URL nội bộ ban đầu. Không chấp nhận URL ngoài ứng dụng.

Service và cây giao diện được tạo lại khi UID thay đổi, để dữ liệu phiên trước không còn trong UI.
Chưa triển khai Apple login, xác minh email bắt buộc hoặc xóa tài khoản.

## Firestore

Hồ sơ được khởi tạo bằng transaction ngay trong luồng đăng ký, sau khi lưu tên trên Firebase Auth.
Chỉ công bố đăng ký thành công khi Firestore đã xác nhận document `users/{uid}`.
Đăng nhập cũng kiểm tra/tạo bù hồ sơ còn thiếu, không ghi đè hồ sơ đã tồn tại.
Nếu Auth đã tạo nhưng Firestore lỗi, ứng dụng báo rõ và cho đăng nhập để thử lại; không xóa Auth tự động.
Đã kiểm chứng bằng SDK thật trên Chrome: đọc document trực tiếp ngay sau `register`,
trước khi mở Profile hoặc gọi `ensureAccount` từ màn hồ sơ. Bộ hồi quy sau sửa đạt 204 test.
Tên ban đầu lấy từ Firebase Auth displayName; không sao chép tài khoản Mai Anh từ dữ liệu mẫu.

```text
users/{uid}
  schemaVersion, id, name, handle, bio, showBio, avatarUrl, cookedCount
  role, status, createdAt, updatedAt, lastLoginAt, lockedAt, lockReason
users/{uid}/favorites/{recipeId}
  recipeId, createdAt
```

`FirestoreProfileService` đọc/lưu tên, giới thiệu và tùy chọn hiển thị, đồng thời nghe thay đổi hồ sơ.
`FirestoreRecipeFavoritesService` lưu/bỏ lưu và đồng bộ trạng thái giữa Home, tìm kiếm,
chi tiết công thức và Profile. Tài khoản mới không nhận các món yêu thích mặc định trong JSON.
Mỗi service gắn với một UID và kiểm tra phiên trước/sau các thao tác bất đồng bộ.

Rules chỉ cho chính chủ truy cập document/subcollection của họ. Client không được liệt kê user,
đổi UID/handle, tự tăng `cookedCount`, thêm quyền admin hoặc ghi collection tùy ý.
`updatedAt`/`createdAt` dùng server timestamp. Hồ sơ này là dữ liệu riêng; chưa xuất bản profile công khai.

Model có trạng thái khóa và vai trò, cùng giới hạn quyền sửa từng trường;
xem [USER_MODEL.md](USER_MODEL.md). Chưa có admin web/API quản trị tài khoản.

Danh mục nguyên liệu đã dùng Firestore: [schema, dữ liệu và xuất bản](INGREDIENT_CATALOG.md).

Đăng món đã dùng Firestore và Cloudinary, có nháp, bài chờ duyệt và phiên bản sửa
sau từ chối. Chỉ bài được duyệt trong `recipes` được đọc công khai. Home dùng bài và
banner Firestore qua listener realtime, không gộp bài/banner mẫu local. Tìm kiếm,
chi tiết và Profile vẫn hỗ trợ thêm công thức mẫu trong bundle.

Mọi bài dùng một document `recipes/{id}` schema 2: `pending`, `approved`, `rejected`.
Admin đổi `status` thành `approved` ngay trên document đó là Home lấy realtime;
không cần collection công khai riêng hoặc tự tạo `publishedAt`. `isBanner` nằm cấp gốc,
chỉ admin sửa. Nội dung công thức nằm trong `content`, snapshot tác giả trong `author`.
Hồ sơ tác giả công khai dùng snapshot tác giả của bài đã duyệt, không mở quyền đọc `users`.
Xem [RECIPE_PUBLISHING.md](RECIPE_PUBLISHING.md) cho contract và công cụ duyệt IAM.

Tủ lạnh lưu danh sách nguyên liệu riêng tại `users/{uid}/fridge/current` và lấy
gợi ý từ công thức đã duyệt trên Firestore; xem [FRIDGE.md](FRIDGE.md).

**Phần còn dùng mock:** công thức mẫu/tác giả mẫu trong bundle ở các màn khác và giỏ đi chợ.
Tài khoản mới chưa có bài được duyệt sẽ có 0 công thức của mình.

Triển khai riêng rules/indexes, không triển khai Hosting:

```powershell
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase deploy --only firestore --project bepxinh-b0be7 --non-interactive
```

Khi thêm tính năng ghi Firestore, cập nhật rules và kiểm thử trước khi deploy.

## Kiểm thử cô lập

Cần Node.js và Java 21+ cho Firebase Emulator CLI 15. Không dùng project thật để tạo tài khoản thử.

```powershell
flutter analyze --no-pub
flutter test --no-pub
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase emulators:exec --only auth,firestore --project demo-bepxinh "node tool/firebase_emulator_smoke.cjs"
```

Script smoke cố định loopback và project `demo-bepxinh`, kiểm tra đăng ký/đăng nhập,
email khôi phục, lưu hồ sơ/món đã lưu và từ chối truy cập chéo tài khoản/ghi trường sai.

Kiểm thử SDK Flutter thật trên Chrome, khi emulator đang chạy. Dùng web build độc lập
để tránh lỗi đường dẫn/CanvasKit của Flutter web test runner trên Windows:

```powershell
npm.cmd exec --yes --package=firebase-tools@15.34.2 -- firebase emulators:start --only auth,firestore --project demo-bepxinh
# Ở terminal khác, cần Python và Chrome:
flutter build web --release --no-wasm-dry-run --target tool/firebase_sdk_smoke.dart --output build/firebase-smoke-web
node tool/firebase_sdk_browser_smoke.cjs
```

Entry point smoke cố định project `demo-bepxinh`, dùng Auth/Firestore emulator trên loopback,
kiểm tra service thật của ứng dụng. Artifact nằm riêng trong `build/firebase-smoke-web`.
Script tự mở Chrome headless với profile riêng, rồi đóng browser/server khi hoàn tất.
Không dùng artifact smoke để deploy ứng dụng.
Để chạy ứng dụng ở chế độ emulator:

```powershell
flutter run -d chrome --dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1
```

Android emulator dùng host `10.0.2.2`. Cấu hình emulator trong `main.dart` bị từ chối ở release mode.
Khi chạy ứng dụng với emulator có project ID thật, phải khởi động **cả Auth và Firestore emulator**
với `--project bepxinh-b0be7`; không dùng chế độ này để chạy bộ smoke demo ở trên.

Tham khảo: [FlutterFire setup](https://firebase.google.com/docs/flutter/setup),
[Email/Password Auth](https://firebase.google.com/docs/auth/flutter/password-auth),
[Firestore Rules](https://firebase.google.com/docs/firestore/security/rules-conditions).

## Kết quả xác minh 09/11/2026

- Firebase apps Android/iOS/Web đã đăng ký đúng project number `955775168150`.
- Email/Password đang bật, localhost có trong authorized domains.
- Rules/indexes đã deploy thành công; đọc Firestore production không có phiên bị từ chối HTTP 403.
- Xem [RECIPE_PUBLISHING.md](RECIPE_PUBLISHING.md) cho kiểm thử và giới hạn luồng đăng món mới.
- Smoke REST emulator gốc bao gồm quyền đọc/ghi danh mục nguyên liệu và khóa tài khoản.
- Smoke Flutter SDK trên Chrome headless: đạt đăng ký, đăng nhập lại, lưu/đọc hồ sơ,
  đồng bộ món đã lưu, giữ dữ liệu và từ chối truy cập chéo tài khoản.
- Chưa build/chạy Android hoặc iOS trên thiết bị thật; không tạo tài khoản thử trên production.
