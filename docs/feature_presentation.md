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
có fallback, không có semantics. Header Đăng món ẩn khi mở bàn phím để ưu tiên ô nhập.
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