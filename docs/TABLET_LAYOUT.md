# Bố cục tablet của app Bếp Xinh

> Cập nhật: shell hiện dùng thanh bên trên tablet và thanh đáy phẳng trên điện thoại.
> Home chuyển sang feed, Tủ lạnh dùng dải nguyên liệu và lưới món. Xem contract mới
> trong [INSTAGRAM_UI.md](INSTAGRAM_UI.md); phần mô tả bố cục cũ dưới đây là lịch sử.

Điều hướng khi xoay máy (26/11/2026): shell chọn sidebar khi **cạnh ngắn của
viewport từ 600 px**, thay vì chỉ xét chiều rộng. Điện thoại 844×390, 926×428
hoặc 568×320 giữ bottom navigation với bốn tab và nút Đăng món ở giữa. Sidebar
không dựng nội dung khi ẩn, tránh layout các nút trong chiều cao thấp. Shell/tab
vẫn giữ cùng vị trí trong cây widget để không mất state khi xoay hoặc đổi breakpoint.
Quy tắc chiều rộng cho bố cục nội dung/dialog khác không đổi.

Xác minh: 33 test navigation/bố cục đạt sau khi test ngang dùng nút Đăng món
trên navigation; gồm xoay dọc/ngang/qua tablet, giữ cùng ProfileCubit và tab
Đã lưu, mở/đóng Đăng món, chuyển đủ bốn tab ở cả ba kích thước ngang nêu trên.
Analyzer chỉ còn các issue ngoài phần sửa (có chẩn đoán bị in lặp trong lượt chạy).
Chưa kiểm tra trên điện thoại thật hoặc deploy Hosting cho bản sửa này.

Áp dụng cho Flutter app trong `app_bep_xinh`. Kích thước dưới đây là logical pixel.

## Quy ước

- Từ 600 px: dùng không gian tablet; dưới 600 px giữ bố cục điện thoại.
- Nội dung danh sách/lưới tối đa 1120 px; form và hộp thư tối đa 720 px;
  form xác thực tối đa 440 px. Không kéo ô nhập ra toàn màn hình lớn.
- `AppAdaptiveColumns` chia cột theo **chiều rộng được cha cấp**, mặc định từ
  840 px, giỏ đi chợ từ 760 px. Giữ cây `Flex` khi đổi hướng để bảo toàn
  controller, vùng chọn và focus. Các cột dùng chung vùng cuộn của màn hình.
- `ProductGrid` tự tính số cột (2–4) và chiều cao theo nội dung/cỡ chữ.
- Shell giữ cùng cây widget khi vượt mốc 600 px; thanh điều hướng đáy tối đa
  720 px. Không khởi tạo lại tab hay xóa các món đã đánh dấu khi resize.
- `showAppAdaptiveSheet` mở sheet trên điện thoại và dialog rộng tối đa
  640 px trên tablet. Dialog tự tránh bàn phím; builder nhận phần còn lại,
  không trừ bàn phím lần thứ hai.
- AppBar màn con cố định; AppBar của các tab cuộn theo quy ước hiện tại.

## Phạm vi màn hình

| Nhóm | Màn hình và cách thích ứng |
| --- | --- |
| Xác thực | Đăng nhập, đăng ký, quên mật khẩu: form giữa màn hình, giới hạn chiều rộng, cuộn khi thiếu chiều cao; giữ nội dung nhập khi resize. |
| Trạng thái tài khoản | Kiểm tra/bị khóa/lỗi xác minh: nội dung giới hạn chiều rộng, có thể cuộn. |
| Trang chủ | Banner tablet, danh mục, slider và lưới món ăn theo chiều rộng. |
| Tủ lạnh | Kho nguyên liệu và gợi ý món chia cột khi đủ chỗ; chọn nguyên liệu bằng dialog trên tablet. |
| Giỏ đi chợ | Hai nhóm món chia cột khi đủ rộng, giữ đánh dấu qua xoay máy và thay đổi breakpoint. |
| Hồ sơ | Hồ sơ cá nhân/công khai: nội dung căn giữa, lưới món ăn thích ứng. |
| Cài đặt và sửa hồ sơ | Form/danh sách tối đa 720 px, cuộn và tránh bàn phím. |
| Tìm món | Bộ giới thiệu, ô tìm kiếm, bộ lọc và kết quả dùng một vùng cuộn; tablet ngang có bàn phím vẫn cuộn tới được kết quả. |
| Chi tiết món và nấu ăn | Tổng quan/nguyên liệu/các bước chia cột khi đủ rộng, thanh hành động riêng. |
| Đăng món | Bốn bước dùng chiều rộng trang và chia cột theo nội dung; chọn/sửa nguyên liệu bằng dialog, giữ bản nháp khi xoay. |
| Bài đã gửi | Trên thẻ đủ rộng, ảnh và thông tin duyệt nằm cạnh nhau; màn hẹp xếp dọc. |
| Thông báo | Hộp thư giới hạn chiều rộng; chi tiết mở dialog tablet có nút đóng. |
| Tin nhắn | Danh sách, chọn tác giả và hội thoại giới hạn chiều rộng; composer giữ bản nháp khi xoay, danh sách tin nhắn cuộn riêng. |

## Kiểm chứng

`test/features/tablet_layout_test.dart` kiểm tra toàn bộ route màn hình, cuộn,
chữ 150%, kích thước 599/600, tablet dọc/ngang và màn rộng 1280 px; thêm
các tình huống bàn phím, dialog nguyên liệu/thông báo, giữ focus/vùng chọn,
bản nháp và trạng thái giỏ đi chợ.

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

Widget test dùng repository giả, không đọc/ghi Firebase thật. Kiểm thử layout
tự động không thay thế kiểm tra trực tiếp trên thiết bị tablet thật.
