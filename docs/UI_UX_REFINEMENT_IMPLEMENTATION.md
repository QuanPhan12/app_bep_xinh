# Cải thiện giao diện Bếp Xinh — 18/11/2026

Triển khai theo [UI_UX_NEXT_PLAN.md](UI_UX_NEXT_PLAN.md). Phạm vi là app Flutter;
giữ màu cam, light/dark, font và component Sollume đã port. Không sửa source port,
quyền Firestore, API AI hoặc quy trình nghiệp vụ trong đợt giao diện này.

## Component dùng chung

- `AppCard`: khung viền nhẹ, không đổ bóng; ảnh và nội dung cùng bề mặt.
- `AppSectionHeader`: thứ bậc chữ từ Theme, có subtitle/semantics header; không scale
  font hai lần qua cả style cũ lẫn responsive.
- `AppMenuGroup` và `AppFeatureTile`: nhóm menu có khoảng cách, icon, mô tả và
  đường phân cách cùng chuẩn. Điều hướng/hành động vẫn được caller truyền vào.
- `AppLoadState`/`AppInboxEmpty`: icon trung tính nhỏ hơn, thông báo có chiều dài
  dòng dễ đọc; nút thử lại vẫn giữ hành vi cũ.
- `AppActionBar`: giới hạn chiều rộng thao tác trên tablet; safe area giữ nguyên.
- `AppContentScrollView`: kéo danh sách để đóng bàn phím; không làm mất dữ liệu form.

## Màn và luồng chính

| Khu vực | Kết quả |
| --- | --- |
| Home / feed theo dõi | Tên món trước ảnh, ảnh 4:3 có khoảng cách và bo góc; card tách rõ. Lưu/đánh giá/chia sẻ và nguồn biến tấu được giữ. Điểm đánh giá thật có icon sao; không thêm số giả hay nút mở chi tiết trùng. |
| Chi tiết / preview món | Typography bớt nặng, metadata thành nhóm; sao đánh giá và tag trung tính. Panel nguyên liệu/cách nấu rõ hơn; nút Bắt đầu nấu và More giữ nguyên. |
| Bếp của tôi | Tóm tắt từ stream thực đơn của phiên và timer thực. Không có dữ liệu thì hiện trạng thái rỗng, không dựng lịch mẫu. Nhóm công cụ hai cột khi đủ rộng, một cột trên mobile. |
| Tủ lạnh | Kho nguyên liệu và gợi ý cạnh nhau ở tablet rộng; chữ lớn chuyển về một cột. Grid đo chiều rộng cột thực thay vì toàn màn hình. |
| Cá nhân | Lưới ảnh có lề/bo góc và số cột theo vùng chứa. Các nút, bộ lọc và đồng bộ tab/lưu món giữ nguyên. |
| Chat | Bộ đếm tách khỏi hàng nhập, nút gửi và đính kèm căn giữa ô nhập; nội dung/bản nháp khi lỗi được giữ. Preview trong danh sách có màu thứ cấp, AI vẫn ghim đầu danh sách. |
| Thông báo | Phân biệt icon thông báo đã đọc/chưa đọc, giữ trạng thái và luồng mở chi tiết. |
| Auth | Form tablet có khung; cùng một cây widget khi resize để giữ focus/selection. Kéo để đóng bàn phím, không đổi cơ chế đăng nhập/khôi phục mật khẩu. |
| Editor và màn công cụ | Dùng chung card/header/action bar; giảm padding lặp. Các danh sách Bếp giới hạn chiều rộng đọc; mô tả đầu trang nhường chỗ khi bàn phím mở. |

## Kiểm tra và ảnh

- Baseline light: 28 route × 3 kích thước, 84 ảnh trong
  `build/ui_ux/refinement_before_light/`.
- Bản sau: 28 route ở 390×844, 800×1100, 1024×768, cả light/dark. Ảnh dùng
  fixture widget, không phải ảnh dữ liệu production. Có kiểm tra thêm breakpoint,
  320 px, chữ lớn 200%, bàn phím và xoay máy bằng các test hiện có.
- Gallery đối chiếu: `build/ui_ux/refinement_review.html`; dark có ảnh sau,
  không dựng ảnh trước dark khi đợt này chưa chụp baseline dark.
- Test mới chỉ kiểm tra hành vi mới có ý nghĩa: bữa ăn đọc từ stream cập nhật,
  bỏ ngày cũ, và timer chỉ hiện khi thật sự tồn tại.
- Bài kiểm tra layout Tủ lạnh được cập nhật theo bố cục hai cột đã duyệt;
  vẫn kiểm tra không chồng lấn và giữ panel nấu ăn ở màn chi tiết.

Không xem ảnh DevicePreview bị thu nhỏ là bằng chứng kích thước thật. Đã đối
chiếu ảnh đại diện Home, chi tiết, bếp, tủ lạnh, hồ sơ, chat, auth và tablet;
các route khác có kiểm tra layout và ảnh để rà lại trong gallery.

## Kết quả chốt

Cập nhật theo chỉnh sửa tiếp theo của người dùng: post Home/feed theo dõi đã bỏ
khung card, viền và padding ngang ngoài; ảnh tràn ngang, không bo góc. Chỉ phần
chữ và hàng thao tác giữ khoảng đệm để dễ đọc, các post giữ khoảng cách dọc.

Chỉnh tiếp theo: bỏ viền ngoài của các nhóm mục Bếp của tôi/Cài đặt, gồm khối
tóm tắt bếp và Về Bếp Xinh. Icon công cụ trong Bếp của tôi hiển thị trực tiếp,
không còn ô nền. Các màn khác vẫn giữ kiểu card hiện có.

- `flutter analyze --no-pub`: không có issue.
- Full suite: 379 test đạt, 4 test capture bỏ qua theo cờ mặc định. Sau lần chốt
  nhãn ngắn Tủ lạnh, chạy lại 16 test Fridge/service screens đều đạt.
- Bộ responsive kiểm tra breakpoint, bàn phím, giữ focus/selection khi xoay,
  chữ lớn 200% và tóm tắt bếp: 29 test đạt (1 test capture bỏ qua mặc định).
- Capture cuối: 84 ảnh light + 84 ảnh dark; chat AI chụp thêm 8 ảnh. Tủ lạnh đã
  được chụp lại ở 3 kích thước sau chốt nhãn, gallery dùng các ảnh mới nhất.
- `flutter build web --release --no-pub --no-wasm-dry-run --target lib/main.dart
  --dart-define=PUBLIC_APP_URL=https://bepxinh-b0be7.web.app`: thành công.
- Các kiểm tra dùng fixture và local build; chưa deploy đợt UI này lên Hosting.
  Để xem trong phiên app đang mở, hot restart; bản Hosting hiện vẫn là bản phát
  hành trước đợt cải thiện giao diện này.
