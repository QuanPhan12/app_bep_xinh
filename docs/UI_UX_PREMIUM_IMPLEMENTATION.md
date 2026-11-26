# Bàn giao giao diện Bếp Xinh — 16/11/2026

Home đã được rà và sửa tiếp từ phản hồi ảnh thực tế:
[bố cục Home và bước chọn banner](HOME_REFINEMENT.md). Mô tả bên dưới là đợt
phát hành nền trước đó; bố cục Home hiện hành theo tài liệu bổ sung.

Triển khai theo `UI_UX_PREMIUM_REDESIGN_PLAN.md`, tham khảo khung trang, nhịp
khoảng cách và nhóm menu trong source Sollume. Không sửa repo Sollume.

## Điều hướng và các hành trình chính

- Mobile có bốn điểm đến có chữ: **Trang chủ · Tủ lạnh · Bếp của tôi · Cá nhân**.
  Bỏ vị trí dấu cộng không nhãn và Đi chợ mẫu khỏi thanh điều hướng.
- Tablet giữ cùng navigation shell khi resize; rail 100 px có nhãn dưới icon,
  từ 1180 px dùng sidebar 224 px. Tab chọn theo router, không có state chọn giả.
- `/kitchen` là branch số 2 trong shell; các route con giữ URL và auth guard.
  `/cart` vẫn là route riêng để giữ deep link và hành vi mẫu, không quảng bá trong nav.
- Đăng món từ nút có chữ trong Cá nhân hoặc nút dấu cộng “Đăng món” ở chính giữa navigation bottom. Nút giữa mở route đăng món hiện có, không tạo branch/tab mới; quay lại giữ tab và stack trước đó. Bốn tab giữ nguyên thứ tự và hành vi; auth guard, bản nháp và luồng gửi duyệt không đổi. Quản lý bài đăng có lối vào kế bên nút trong Cá nhân.
- Món đã lưu trong Bếp của tôi mở `/profile?tab=saved`; Profile Cubit chọn đúng
  tab từ route và giữ dữ liệu theo cùng service favorites.
- Card công thức vẫn chỉ có một hành động mở chi tiết; nút lưu/đánh giá/chia sẻ
  và tên tác giả giữ hành vi riêng.

## Các phần đã thay đổi

| Khu vực | Triển khai |
|---|---|
| Bộ component | Body text 15/13, section weight 600, card radius 12, dark nền than; vẫn dùng font Be Vietnam Pro, màu cam và màu trạng thái theo theme |
| Header | Bỏ dòng eyebrow in hoa trang trí; title và mô tả phân cấp bằng chữ và khoảng cách |
| Home | Header gọn, câu hỏi tác vụ và tìm kiếm rõ; món nổi bật dùng ảnh chữ nhật, danh mục và feed; bỏ shortcut Tủ lạnh lặp với nav |
| Tủ lạnh | Mô tả cách chọn nguyên liệu để tìm món; lối vào Nguyên liệu & hạn dùng có tên rõ |
| Bếp của tôi | `AppMenuGroup` chia Chuẩn bị bữa ăn, Công thức của bạn, Nấu và ghi nhớ, Cộng đồng |
| Chi tiết món | Công cụ phụ gom vào vùng mở rộng có nhãn; thanh Bắt đầu nấu và nội dung nguyên liệu/cách nấu giữ nguyên |
| Hồ sơ | Đã đăng/Đã lưu luôn có chữ; nút Đăng món và Quản lý bài đăng có mục đích riêng |
| Cài đặt | Nhóm Tài khoản, Quyền riêng tư, Giao diện ứng dụng; thao tác không giữ khóa tap trong suốt vòng đời route con |
| Thực đơn/kho/bộ sưu tập/nhật ký/timer/offline/theo dõi | Khung trang, mô tả ngữ cảnh, màu chữ/surface và control thống nhất; giải thích rõ kho số lượng/hạn dùng độc lập với bộ lọc Tủ lạnh |
| Auth/editor/quản lý bài | Form kế thừa typography và control chung; mở đầu auth gọn; tên trạng thái và quản lý bài thống nhất; giữ nháp và validation |
| Tin nhắn/thông báo/đánh giá/báo cáo | Theo cùng theme/control; hội thoại là hàng nhẹ với avatar tròn; giữ unread, gửi/nhận và quyền riêng tư hiện tại |
| Modal/empty/error | Kế thừa theme, cỡ chữ và surface mới; giữ callback retry, busy và phân biệt trạng thái theo contract hiện có |

Không tự đồng bộ dữ liệu kho với bộ lọc Tủ lạnh, không thêm checkout hoặc đổi
schema Firestore. Tính năng ẩn/xóa bài, duyệt đánh giá và báo cáo vẫn dùng Rules
đã phát hành; đợt này không cần deploy Rules/index hay ghi dữ liệu production.

## Admin

Portal có cùng font Be Vietnam Pro (bundle kèm OFL), màu cam cho hành động chính,
surface trung tính, nhịp chữ và khoảng cách rõ hơn. Có chọn Sáng/Tối/Theo hệ thống
ở thanh đầu trang; lựa chọn tồn tại trong phiên component, không lưu credential
hoặc đổi quyền truy cập. Login theo theme hệ thống. Toàn bộ màn quản trị dùng
stylesheet chung `src/features/admin/premium.css`.

Các tác vụ duyệt/ẩn, banner, catalog, tài khoản, báo cáo và lịch sử giữ repository
và transaction hiện có. Không thêm số liệu hoặc hành vi giả vào dashboard.

## Xác minh

- `flutter analyze --no-pub`: sạch.
- Full suite: **312 test đạt**, một test chụp ảnh tùy chọn skip trong lượt này.
- Hai lượt audit ảnh riêng: **84 ảnh sáng + 84 ảnh tối**, 28 route ở 390×844,
  800×1100 và 1024×768. Dùng font Be Vietnam Pro trong render fixture.
- Các test layout còn kiểm tra 320/360, sát breakpoint 599/600, tablet ngang,
  dark/resize, cỡ chữ lớn đến 200%, bàn phím, nháp và trạng thái cuộn.
- Đã kiểm tra route `/kitchen`, mở editor từ Cá nhân, back về đúng tab và
  `/profile?tab=saved`. Các kiểm tra auth/session và luồng nghiệp vụ cũ đều thuộc
  full suite; không thêm bypass đăng nhập.
- Admin: build và 4 domain test đạt; Chrome/demo emulator đạt **21 SDK check và
  17 UI check**, có đối chiếu computed style sáng/tối. Lint còn warning cũ ở prototype;
  bundle còn cảnh báo kích thước.
- Đã xem các ảnh đại diện Home, Bếp của tôi, Hồ sơ, Cài đặt, Chi tiết tablet và
  admin dark. Bộ ảnh là fixture kiểm soát, không phải ảnh dữ liệu người dùng thật.
- Chưa có nghiên cứu người dùng, kiểm thử trên điện thoại/tablet vật lý hoặc APK/IPA
  phát hành trong đợt này. Không khẳng định đã nghiệm thu mọi trạng thái bằng tài khoản thật.

Ảnh: `build/ui_ux/premium-light` và `build/ui_ux/premium-dark`.
Log cục bộ: `node_modules/.cache/report-release/premium-*.log`.
Ảnh/log admin: `../admin_bep_xinh/node_modules/.cache/admin-smoke`.

## Cập nhật bản chạy

Đã phát hành ngày 16/11/2026, dùng tài khoản vận hành đã được người dùng xác nhận:

- App: `https://bepxinh-b0be7.web.app`, version `6af9ae3accbef1ff`, lúc 23:00:35 UTC+7.
- Admin: `https://bepxinh-admin.web.app`, version `0b43bcd6a87c2fdf`, lúc 23:01:31 UTC+7.
- HTML/bootstrap/main.dart.js app và HTML/JS/CSS admin live khớp hash artifact local.
  Bốn font admin trên Hosting cũng đã được đối chiếu hash với asset local.
- Chỉ deploy Hosting của hai site; không thay Firestore Rules/index hay dữ liệu.

Web cần refresh để tải artifact mới. Local Flutter cần **hot restart** sau khi
đổi cấu trúc router/shell; hot reload có thể giữ instance router cũ. App đã cài
cần build/cập nhật riêng. Các thay đổi đang có trong Android/iOS và dữ liệu mock
của người dùng được giữ nguyên.
