# Giao diện toàn app Bếp Xinh

## Nguồn thiết kế chung

`AppColors`, `AppUi` và `AppTheme` là nguồn màu, khoảng cách, bo góc và theme.
Điện thoại và tablet dùng nền sáng ấm, card trắng, chữ nâu đậm, cam cho hành động
và xanh thảo mộc cho nội dung hỗ trợ. Không có palette riêng theo feature.
`AppFeatureTheme` còn tồn tại như marker tương thích; không tạo Theme override.
Các hằng của marker trỏ về AppColors.

- Cam thương hiệu giữ nguyên; `AppColors.action` dùng sắc cam đậm cho nút/chip
  có chữ trắng và liên kết nhỏ. Cặp màu chính được kiểm tra tương phản trong test.
- Card mặc định bo 16 px, không viền và không shadow; control bo 12 px.
- Button có primary/secondary/ghost. Primary dùng nền đặc, có icon và giữ nhãn
  khi loading. Chiều cao là tối thiểu; nhãn dài/chữ lớn được xuống dòng, không co font.
- Input/search/tab/chip dùng component chung; vị trí focus và giá trị nhập giữ
  nguyên khi đổi kích thước. Form auth dùng Validation chung để báo lỗi tại trường.
- AppBar nền sáng, chữ/icon tối. AppBar tab vẫn floating/snap; màn con cố định.
- Thanh điều hướng có tên tab mặc định và đo chiều cao theo nội dung/cỡ chữ.
  Nút giữa là hành động Đăng món, không trở thành một tab được chọn.

## Phân cấp nội dung

`AppFeatureHeader` dùng khoảng cách và typography cho phần mở đầu; ảnh trang trí
có fallback, không có semantics. Đăng món chỉ giữ bốn mốc dưới AppBar, ẩn khi mở
bàn phím để ưu tiên ô nhập; không còn dòng số bước/trạng thái nháp phía trên mốc.
`AppCard`, `AppSearchBar`, `AppSectionHeader`, `AppActionBar`, `AppLoadState` và
`AppStatusBadge` không đổi style theo marker feature.

Home dùng tên Món ngon khám phá, không ngụ ý có thuật toán xếp hạng thịnh hành.
Thẻ Tủ lạnh nền xanh nhạt, thông tin và hành động rõ ràng. Recipe card dùng tiêu đề
14 px, metadata 12 px; grid/slider đo lại chiều cao tương ứng. Nút lưu món có tooltip,
semantics và vùng tương tác 48 px.

Hồ sơ cá nhân dùng cùng block danh tính với hồ sơ công khai, không có khoảng trống
cover lớn hay dấu xác minh vô điều kiện. Sửa hồ sơ xác nhận trước khi bỏ thay đổi,
cả nút Back lẫn Back hệ thống, và chặn rời màn khi đang lưu.

Bài đã gửi dùng badge chữ + icon cho chờ duyệt/đã duyệt/cần sửa. Thông báo hiển thị
đã/chưa đọc bằng chữ cùng các dấu hiệu trực quan. Tin nhắn chỉ có ảnh có preview
bằng chữ trong inbox. Chế độ nấu có hành động tạm dừng bên cạnh điều khiển bước.

Giỏ đi chợ hiện là danh sách mẫu lưu trong phiên; màn hình ghi rõ điều này và không
hiển thị nút chia sẻ/hoàn tất chưa có xử lý. Không ghi thêm dữ liệu thật từ đợt UI.

## Kiểm chứng

Bố cục theo AppLayout, AppAdaptiveColumns và showAppAdaptiveSheet. Kiểm tra
điện thoại nhỏ, tablet dọc/ngang, breakpoint 599/600, bàn phím và chữ 150%/200%.
Ảnh audit, giới hạn kiểm chứng và lệnh chạy nằm trong
[UI_UX_IMPLEMENTATION.md](UI_UX_IMPLEMENTATION.md).

## Empty dùng chung — 27/11/2026

`core/widgets/app_empty_state.dart` là phần nội dung dùng chung, nhận `title`
tùy chọn, `message`, `action`, `illustrationAsset`, `fallbackIcon` và `padding`.
Màn cha giữ quyền cuộn và callback nghiệp vụ. Không card/viền/nền trang trí;
chữ theo theme light/dark, ảnh trang trí không thêm nội dung cho screen reader.

Ảnh mặc định `assets/images/empty_state.webp` (1536×1024, alpha, 34.7 KB) là
minh họa bát rỗng và giấy công thức không chữ, chỉ có sắc xám. Sinh bằng built-in
`image_gen`, xuất WebP quality 85, giữ alpha; không thay bằng ảnh SVG hoặc icon giả.
Nguồn PNG giữ tại thư mục generated_images của Codex, ứng dụng chỉ tham chiếu WebP
trong repo. Không thêm dependency; thư mục ảnh đã đăng ký trong pubspec.

`AppLoadState` dùng minh họa cho trạng thái rỗng không có retry; loading/skeleton
và lỗi có retry giữ hành vi cũ. `AppInboxEmpty` (thông báo/tin nhắn) và
`ProfileRecipeEmptyState` dùng cùng component, giữ nội dung và callback; nút khám
phá của hồ sơ đổi sang nút chữ không viền. Các empty đang dùng `AppLoadState`
(gồm tìm kiếm) nhận ảnh tự động.

Kiểm chứng: lượt test toàn bộ đạt 406, skip 4; sau khi đồng bộ nút phụ/ảnh của
Đăng món, chạy lại 66 test editor đạt (1 skip). Analyzer còn 5 issue có sẵn ngoài
source sửa; formatter và `git diff --check` đạt. Capture ba kích thước cho empty
light/dark và editor đều đạt; đã xem ảnh mobile, ảnh empty có alpha đúng trên
cả hai nền. Thư mục ảnh: `build/ui_ux/empty-search`, `empty-search-dark`,
`editor-milestones`. Chưa kiểm tra thiết bị thật hoặc deploy Hosting.

Prompt tạo ảnh:

> Use case: stylized-concept. Asset type: reusable empty-state illustration for Bep Xinh cooking mobile app, delivered as a transparent raster asset to be exported WebP. Create a beautifully restrained editorial illustration of one empty shallow ceramic bowl seen in gentle three-quarter view, beside a single small recipe sheet with no writing. Compact centered composition, generous transparent margin. Soft matte sculptural shapes, subtle light-gray and medium neutral-gray shading, elegant simple silhouette readable at 120px. Strict grayscale only, no colored accents, no outlines or decorative borders, no frame, no sparkles, no text, no lettering, no symbols, no logo, no watermark. Actual transparent background with preserved alpha, no white rectangle. No cast shadow beyond the objects. Designed for a clean modern food app empty state on both white and dark backgrounds.
