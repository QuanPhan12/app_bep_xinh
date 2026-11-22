# Báo cáo triển khai UI/UX Bếp Xinh

> Bố cục và màu trong tài liệu này là đợt trước. Thiết kế hiện tại theo yêu cầu
> mới xem [Giao diện feed và dark/light](INSTAGRAM_UI.md).

Phạm vi: Flutter app, điện thoại và tablet. Các thay đổi là phần trình bày và
hành vi tương tác trong app; không thay contract Firebase, dependency hay admin.

## Đã triển khai

| Nhóm | Kết quả |
| --- | --- |
| Thiết kế nền | Hợp nhất palette AppColors và theme toàn app; AppFeatureTheme chỉ còn marker tương thích. Token AppUi cho khoảng cách, bo góc và vùng chạm. |
| Component | Card phẳng bo 16 px, AppBar sáng; button nền đặc, có icon, giữ nhãn khi loading và xuống dòng theo chữ lớn; search/form cùng style. |
| Điều hướng | Hiện nhãn tab, đo chiều cao theo font/chiều rộng; nút Đăng món có tooltip và semantics, giữ contract router. |
| Home | Đổi tên section thành Món ngon khám phá/Tất cả công thức; thẻ Tủ lạnh nền xanh nhẹ với nội dung đọc được; giảm mảng cam trang trí. Sửa tham chiếu ảnh canh kimchi trong danh mục mẫu từ ảnh burger sang ảnh canh đúng có sẵn. |
| Recipe card | Tên món 14 px, metadata 12 px và đo chiều cao đồng bộ; vùng lưu món 48 px, có tooltip/trạng thái toggled. |
| Tìm kiếm | Bỏ lọc nhanh giữ từ khóa, tiếp tục dùng vùng cuộn chung và controller ổn định. |
| Tủ lạnh | Hiển thị đang lưu ngay tại kho nguyên liệu, giữ rollback/retry của Cubit. |
| Chi tiết/Nấu | Dùng cùng theme và action bar, icon lưu món phù hợp AppBar sáng; bước nấu hiện tiến độ và có nút Tạm dừng. |
| Đăng món | Giữ bốn bước, header nhẹ và ẩn khi mở bàn phím, thao tác tiếp/lưu nháp giữ nhãn khi loading. |
| Bài đã gửi | Badge có chữ + icon phân biệt trạng thái duyệt, giữ thông báo lý do và hành động hiện có. |
| Hồ sơ | Thu gọn khoảng trống cover, dùng chung ProfileIdentityInfo; bỏ dấu xác minh không có nguồn dữ liệu. |
| Sửa hồ sơ | Bảo vệ thay đổi chưa lưu khi Back nút/hệ thống; ở lại giữ form, bỏ thay đổi không ghi, đang lưu chặn Back. |
| Thông báo | Có chữ Đã đọc/Chưa đọc ngoài màu và chấm trạng thái; dialog tablet giữ nút đóng. |
| Tin nhắn | Inbox dùng card nhất quán; tin chỉ có ảnh hiển thị Đã gửi một ảnh; semantics cho trạng thái chưa đọc. |
| Auth | Login có tiêu đề/mô tả rõ; input báo lỗi email/tên/mật khẩu qua Validation chung; toggle mật khẩu có tooltip. Checkbox điều khoản có vùng chạm và semantics rõ, không giả liên kết chưa có luồng mở. |
| Giỏ đi chợ | Ghi rõ danh sách mẫu theo phiên, giữ đánh dấu và bố cục tablet; bỏ nút chia sẻ/hoàn tất callback rỗng. |
| Trạng thái chung | Loading/rỗng/lỗi và retry dùng component chung; action bar không tạo style/shadow theo feature. |

Các màn Cài đặt, tài khoản bị khóa/kiểm tra/lỗi xác minh, hồ sơ công khai,
chọn tác giả, hội thoại, chọn nguyên liệu và xem trước tiếp tục dùng nguồn dữ
liệu và hành vi hiện có, nhận thiết kế chung từ component/theme.

## Audit trực quan và ảnh

- Bộ ảnh nằm tại `build/ui_ux/before` và `build/ui_ux/after`: 19 route, mỗi route
  ở 390×844, 800×1100 và 1024×768 (57 ảnh mỗi bộ).
- Ảnh dùng repository giả và tài nguyên trong repo, không truy cập Firebase.
  Một số ảnh/bản nháp là fixture kiểm thử, không phải dữ liệu production.
- Bộ after nạp icon Phosphor và ảnh trước khi chụp. Font chữ audit là Segoe UI
  cục bộ trên Windows để không phụ thuộc mạng; app vẫn giữ Be Vietnam Pro.
  Bộ before là ảnh khảo sát ban đầu, có icon/ảnh chưa nạp đủ; không dùng hai bộ
  làm phép so sánh pixel/golden hoặc bằng chứng đo font production.
- Mở `build/ui_ux/index.html` để xem bộ ảnh theo màn và kích thước.

Lệnh tạo lại ảnh after trên Windows:

```powershell
flutter test --no-pub test/features/tablet_layout_test.dart --plain-name "capture app UI audit" --dart-define=UI_CAPTURE=true --dart-define=UI_CAPTURE_STAGE=after
```

Test capture mặc định được bỏ qua trong suite thường, do cần font Windows và
ghi PNG. Kích hoạt capture chỉ dành cho audit, không thêm route/shortcut vào app.

## Kiểm chứng

- `flutter analyze --no-pub`: đạt, không còn cảnh báo/lỗi.
- `flutter test --no-pub`: 278 test đạt, 1 test capture bỏ qua mặc định;
  layout 320–1280 px, chữ 150%, tablet dọc/ngang,
  keyboard; thêm các luồng chính ở 200%, bảo vệ bản nháp hồ sơ, tương phản của
  cặp màu chữ chính, button có chữ lớn/loading và giữ dữ liệu khi xoay.
- `flutter build web --release --no-pub`: build cục bộ, không deploy Hosting.
- Test capture được chạy riêng để xuất 57 ảnh after. Nhật ký cuối tại
  `build/ui_ux_final_*`; nhật ký build tại `build/ui_upgrade_web_build.log`.

## Giới hạn và backlog chức năng

Chưa kiểm tra trên tablet/điện thoại vật lý hoặc thực hiện nghiên cứu người dùng;
chưa đo hiệu năng trên thiết bị. Build và widget test không thay thế các bước đó.

Giỏ đi chợ thật, chia sẻ, lưu bền, lịch sử nấu, xác minh tài khoản, cá nhân hóa,
dark mode và rail tablet là các hạng mục riêng cần contract. Đợt này không tạo
dữ liệu/đánh giá/danh hiệu giả để lấp chỗ trống của giao diện.
