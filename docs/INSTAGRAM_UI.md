# Giao diện Bếp Xinh: feed, ảnh và dark/light

Bản thiết kế tiếp theo đã triển khai: [bố cục rõ tác vụ](UI_UX_PREMIUM_IMPLEMENTATION.md).
Các đoạn mô tả đợt Instagram bên dưới là lịch sử; điều hướng và ảnh nổi bật hiện
hành xem bản bàn giao mới.

Đợt thiết kế lại theo yêu cầu mới thay thế bố cục Home dạng dashboard và thanh điều
hướng có nút nổi trước đây. Giữ nhận diện cam `#E8590C`, font Be Vietnam Pro và các
luồng nấu ăn hiện có. Thiết kế tham khảo cách tổ chức nội dung của Instagram;
không thêm tính năng mạng xã hội hoặc số liệu chưa có dữ liệu thật.

## Hệ thống giao diện

- Light: nền trắng, chữ gần đen, đường phân cách xám mảnh. Dark: nền đen,
  lớp nổi xám `#181818`, chữ trắng/xám sáng. Giảm độ bo chung xuống 8 px.
- Cam dùng cho điểm nhấn, nút chính và trạng thái. Nút nền cam đậm dùng chữ trắng;
  liên kết trong dark dùng cam sáng hơn để giữ tương phản.
- `AppPalette` là ThemeExtension theo BuildContext. Không dùng biến màu toàn cục
  phụ thuộc màn đang mở; preview light/dark trong cùng cây vẫn độc lập.
- `AppTextStyles` không gán cứng màu chữ nội dung. `AppTheme` áp dụng màu từ
  ColorScheme cho typography, form, app bar, menu, dialog, sheet và control.
- Các tham chiếu màu trong màn cũ đã chuyển sang `context.colors`; marker
  AppFeatureTheme chỉ giữ tương thích, không tạo một palette cạnh tranh.

## Bố cục mới

| Khu vực | Thiết kế |
|---|---|
| Home | Header thương hiệu gọn với tìm kiếm, thông báo, tin nhắn. Công thức nổi bật thành hàng ảnh tròn, danh mục cuộn ngang. Feed ảnh vuông lớn, tác giả thực nếu có. Chạm card mở chi tiết; nút riêng chỉ dành cho lưu, đánh giá và chia sẻ, chạm tác giả mở hồ sơ. Không có nút ba chấm/dao nĩa hoặc dòng CTA mở chi tiết trùng lặp. |
| Bảng tin theo dõi | Cùng kiểu bài trong feed, một cột đọc tối đa 630 px; giữ phân trang và quản lý theo dõi. |
| Hồ sơ | Avatar và thống kê trên một hàng, tên/bio phía dưới, nút chỉnh sửa; tab ảnh/đã lưu dạng icon có tooltip. Lưới ảnh 3 cột tỷ lệ 3:4, khe 2 px, mở đúng món. Tiêu đề vẫn có semantics/tooltip. |
| Tủ lạnh | Dải nguyên liệu và thao tác sửa phía trên, lưới món phía dưới; tablet không chia một cột lớn trống cho vài nguyên liệu. Bộ lọc và kết quả đối sánh giữ nguyên. |
| Chi tiết món | Ảnh làm điểm mở đầu, thông tin nấu dùng đường phân cách trung tính; giữ chế độ nấu, timer, nhật ký và các công cụ mới. |
| Màn khác | Cùng nền/chữ/control dark/light: auth, Cài đặt, Đi chợ mẫu, tìm kiếm, editor, thông báo, chat và các màn Góc bếp. |

Cạnh ngắn viewport dưới 600 px: thanh đáy phẳng với 5 vị trí (4 nhánh + tạo bài),
kể cả điện thoại xoay ngang; không dùng ConvexAppBar.
Dependency `convex_bottom_bar` được gỡ khỏi app sau khi chuyển thanh điều hướng.
Cạnh ngắn từ 600 px: thanh bên 100 px; chiều rộng từ 1180 px: mở nhãn và thương hiệu, rộng 224 px.
Home giữ cột đọc tối đa 630 px; khi vùng nội dung đủ 1000 px mới thêm cột tiện ích.
Shell giữ cùng vị trí widget chứa navigationShell khi đổi kích thước để bảo toàn
branch stack và state; tạo bài là thao tác push, không làm đổi tab đang chọn.

Hàng ảnh tròn là công thức nổi bật từ dữ liệu banner hiện có, không giả định story
24 giờ. Không tạo lượt thích, số bình luận, follower hoặc thời gian đăng giả.
Lưu món trên feed vẫn qua auth guard và Cubit; trạng thái yêu thích dùng nguồn cũ.

## Chọn giao diện

Vào **Cài đặt → Giao diện**, hoặc nút giao diện trên header Hồ sơ/thanh bên.
Có Theo hệ thống, Sáng và Tối. Mặc định theo hệ thống; lựa chọn lưu cục bộ qua
SharedPreferences, không gắn với hồ sơ Firebase và không ghi dữ liệu tài khoản.

`AppThemeCubit` nằm ngoài state theo UID. Chuyển màn hoặc đổi tài khoản không
làm mất lựa chọn giao diện trên thiết bị. Việc đọc tùy chọn muộn không được ghi đè
lựa chọn người dùng vừa bấm; ghi storage lỗi vẫn giữ mode trong phiên và báo rõ.

## Kiểm thử và ảnh xem trước

Các bài kiểm thử cũ liên quan hình dạng card, icon Convex và vị trí tìm kiếm được
cập nhật sang tương tác mới, vẫn kiểm tra routing, lưu món, lọc và giữ bản nháp.
Thêm test tương phản, đổi mode, khôi phục lựa chọn, storage lỗi và auth guard feed.
Các route chính được kiểm tra light/dark, chữ lớn, bàn phím và đổi mốc 599/600 px.
Các màn Góc bếp có dữ liệu được chạy cả hai mode với chữ 200%.

Ảnh fixture tại `build/ui_ux/instagram_light` và `build/ui_ux/instagram_dark`, mỗi
mode gồm 19 màn ở 390×844, 800×1100 và 1024×768. Gallery cục bộ:
`build/ui_ux/instagram_preview.html`. Ảnh không phải dữ liệu tài khoản production.

```powershell
# Dùng thư mục tạm trên ổ project nếu ổ hệ thống thiếu chỗ.
New-Item build/instagram_temp -ItemType Directory -Force | Out-Null
$env:TEMP = (Resolve-Path build/instagram_temp).Path
$env:TMP = $env:TEMP
flutter analyze --no-pub
flutter test --concurrency=1
flutter build web --release
flutter test --dart-define=UI_CAPTURE=true --dart-define=UI_CAPTURE_STAGE=instagram_light test/features/tablet_layout_test.dart --plain-name "capture app UI audit"
flutter test --dart-define=UI_CAPTURE=true --dart-define=UI_CAPTURE_STAGE=instagram_dark --dart-define=UI_CAPTURE_THEME=dark test/features/tablet_layout_test.dart --plain-name "capture app UI audit"
```

Không đổi Firestore rules/index, không triển khai Hosting hay phát hành bản store
trong đợt thiết kế này. Kiểm thử widget và build không thay thế trải nghiệm thực
tế trên tablet/điện thoại; chưa đánh giá hiệu năng bằng profiler trên thiết bị.

## Kết quả bàn giao

- Analyzer sạch: `build/instagram_analyze_serial.log`.
- 306 test Flutter đạt, 1 bài capture ảnh tùy chọn skip trong suite thường:
  `build/instagram_regression_serial.log`.
- Hai lượt capture chạy riêng đều đạt: 57 ảnh mỗi mode, tổng 114 ảnh fixture.
- Web release thành công: `build/instagram_web_final.log`, artifact `build/web`.
- Android debug thành công: `build/instagram_android_final.log`, APK tại
  `build/app/outputs/flutter-apk/app-debug.apk`. Chưa chạy trên thiết bị thật.
- `git diff --check` đạt. Các file log/ảnh/build là artifact cục bộ, không đưa lên Git.

Build Android dùng workaround cache Kotlin khác ổ đĩa đã ghi trong
`KITCHEN_FEATURES.md`: Gradle `--no-daemon`, `-Pkotlin.incremental=false` và
`-Pkotlin.compiler.execution.strategy=in-process`. Không thay Gradle properties
của project chỉ để xử lý môi trường máy này.

Chạy capture và suite widget tuần tự: Flutter dùng chung `build/unit_test_assets`;
chạy đồng thời có thể thay thế shader/font asset khi test khác đang dùng.
