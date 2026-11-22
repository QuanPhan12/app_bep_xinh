# Kế hoạch nâng cấp UI/UX toàn app Bếp Xinh

Trạng thái: đã triển khai phần UI/UX trong app; xem [báo cáo triển khai](UI_UX_IMPLEMENTATION.md).
Phạm vi: Flutter app `app_bep_xinh`, điện thoại và tablet. Admin nằm ngoài phạm vi.
Cơ sở: rà soát source, router, theme, widget và tài liệu hiện có. Chưa phải kết quả
đánh giá trực quan từng màn hình trên thiết bị thật hoặc nghiên cứu người dùng.

## 1. Mục tiêu và định hướng

Ưu tiên ba việc: tìm được món phù hợp, nấu theo công thức dễ dàng và chia sẻ
công thức thuận tiện. Giảm nội dung trang trí cạnh tranh với các tác vụ này.

Hướng thiết kế đề xuất: bếp Việt hiện đại, ấm áp, ảnh món ăn làm trọng tâm.
Giữ nhận diện cam và font Be Vietnam Pro; dùng nền sáng hơi ấm, chữ đậm rõ,
xanh thảo mộc cho thông tin hỗ trợ/thành công. Cam dành cho hành động và lựa chọn.
Giảm gradient, đổ bóng và card lồng nhau; phân cấp bằng khoảng cách và typography.

Giữ luồng nghiệp vụ, auth, dữ liệu và routing đang hoạt động. Mọi đề xuất cần
API hoặc lưu trữ mới được tách thành hạng mục chức năng, có contract riêng.
Không thêm điểm đánh giá, danh hiệu hay số liệu chưa có dữ liệu đáng tin cậy.

## 2. Những điểm đã thấy trong source

- `AppTheme` và `AppFeatureTheme` có palette/nền/biến thể component khác nhau;
  nhiều widget còn đọc màu tĩnh trực tiếp. Cần hợp nhất quy ước trước khi sửa màn.
- `AppBottomNavBar.showLabels` mặc định false; cần kiểm tra khả năng nhận biết
  các tab, đặc biệt Tủ lạnh và Giỏ đi chợ, rồi thử phương án có nhãn.
- `ProfileIdentity` có khoảng đệm trên cố định lớn và icon checkCircle luôn
  hiển thị. Cần bố cục gọn hơn; chỉ hiển thị trạng thái xác minh nếu có contract.
- `CartMobileView` sở hữu danh sách mẫu và có callback rỗng. Không thể mô tả
  chia sẻ/hoàn tất giỏ như tính năng thật chỉ bằng việc làm đẹp nút.
- Khung tablet đã có giới hạn chiều rộng, lưới và chia cột; cần tận dụng chúng,
  bổ sung phân cấp thông tin và mật độ phù hợp thay vì chỉ tăng kích thước.
- Tài liệu giao diện có thể chậm hơn source. Mỗi đợt phải cập nhật tài liệu cùng
  component và hành vi cuối cùng.

## 3. Kế hoạch theo giai đoạn

### Đợt 1 — Audit trực quan và chốt thiết kế nền (P0)

1. Chụp toàn bộ route ở điện thoại và tablet dọc/ngang với fixture kiểm soát.
2. Lập danh sách vấn đề: phân cấp, khoảng trống, thao tác khó thấy, nút chưa có
   chức năng, chữ nhỏ/nhạt và trạng thái tải/lỗi/không dữ liệu.
3. Chốt token chung: màu theo vai trò, khoảng cách 4/8/12/16/24/32, typography,
   bo góc, độ nổi, kích thước vùng chạm và chuyển động.
4. Chuẩn hóa button, input, search, chip, tab, recipe card, header, dialog/sheet,
   action bar, skeleton, empty/error state và thông báo phản hồi.
5. Làm bản mẫu của ba màn đại diện: Home, Chi tiết món và Đăng món; mỗi màn có
   điện thoại và tablet để duyệt trước khi nhân rộng toàn app.

Đầu ra: bảng audit có mức ưu tiên, bộ component mẫu và sáu bố cục đại diện.
Đạt khi ba màn có cùng ngôn ngữ thiết kế và các luồng chính dễ nhận biết.

### Đợt 2 — Điều hướng và khám phá món (P1)

- Giữ bốn tab hiện tại và hành động Đăng món riêng; thử nhãn ngắn cho các tab.
  Giữ nguyên stack, vị trí cuộn và hành vi Back đang có.
- Home: ưu tiên tìm kiếm, món gợi ý và danh mục; giảm banner/tiêu đề trùng lặp,
  chuẩn hóa recipe card và trạng thái lưu món. Tên section phải đúng dữ liệu;
  không gọi là cá nhân hóa hoặc thịnh hành nếu chưa có căn cứ.
- Tìm kiếm: làm rõ bộ lọc đang áp dụng, thao tác bỏ lọc và trạng thái không có
  kết quả; giữ ô nhập dễ tiếp cận khi mở bàn phím.
- Tủ lạnh: làm rõ nguyên liệu đã chọn, tự lưu/đang lưu/lỗi lưu; gợi ý món hiển
  thị thông tin đủ/thiếu theo dữ liệu hiện có, chọn nguyên liệu dễ tìm và bỏ chọn.

Đạt khi có thể đi từ Home hoặc Tủ lạnh tới món phù hợp, mở chi tiết và lưu món
mà không phải đoán ý nghĩa icon hay trạng thái bộ lọc.

### Đợt 3 — Chi tiết món và trải nghiệm nấu (P1)

- Tổng quan ngắn gọn: ảnh, tên món, tác giả, thời gian và khẩu phần nếu có dữ liệu.
- Phân biệt rõ Lưu món và Bắt đầu nấu; giữ hành động chính dễ tiếp cận.
- Nguyên liệu dễ quét mắt, định lượng nhất quán, nội dung dài không bị cắt.
- Chế độ nấu làm nổi bật bước hiện tại, tiến độ và Tiếp theo/Quay lại/Tạm dừng;
  hạn chế thông tin cạnh tranh với hướng dẫn đang đọc.
- Tablet rộng: nội dung bước chính và danh sách bước/nguyên liệu bố trí cạnh
  nhau; màn hẹp quay về một cột theo chiều rộng thực tế.
- Hết bước chỉ dùng thông điệp hoàn thành đúng hành vi đang được triển khai;
  không ngụ ý đã lưu lịch sử nếu chưa có lưu trữ.

Đạt khi hoàn thành luồng nấu và quay lại vẫn giữ trạng thái theo contract;
chữ lớn, hướng dẫn dài và ảnh lỗi đều đọc/điều khiển được.

### Đợt 4 — Đăng món, hồ sơ và giao tiếp (P2)

| Màn hình | Nâng cấp dự kiến |
| --- | --- |
| Đăng món | Giữ bốn bước; làm rõ bắt buộc/tùy chọn, lỗi tại trường, bước đang làm, trạng thái lưu nháp và gửi duyệt. Giảm phần mở đầu chiếm chiều cao. |
| Chọn nguyên liệu/ảnh | Đồng nhất tìm kiếm, chọn/sửa/hủy, tiến trình upload và xử lý lỗi; giữ dữ liệu khi đóng bàn phím hoặc xoay máy. |
| Xem trước công thức | Dùng cùng cách trình bày với chi tiết thật; có đường quay lại sửa từng phần. |
| Bài đã gửi | Phân cấp chờ duyệt/đã duyệt/cần sửa; lý do từ chối và hành động sửa rõ ràng. |
| Hồ sơ cá nhân | Thu gọn khoảng trống đầu trang, ưu tiên danh tính và công thức/đã lưu; thống kê phản ánh dữ liệu thật. |
| Hồ sơ công khai | Đồng nhất với hồ sơ cá nhân; chỉ có hành động và danh hiệu đã được hỗ trợ. |
| Sửa hồ sơ | Nhãn trường rõ, thông báo lưu/lỗi và tránh thoát làm mất thay đổi theo hành vi được thống nhất. |
| Cài đặt | Nhóm theo mục đích, tên mục dễ hiểu, thao tác đăng xuất rõ ràng. |
| Thông báo | Phân biệt đã/chưa đọc bằng nhiều dấu hiệu; chi tiết, đánh dấu đã đọc và điều hướng nhất quán. |
| Danh sách tin nhắn | Ưu tiên tên, nội dung cuối và chưa đọc; trạng thái rỗng/lỗi có bước tiếp theo. |
| Chọn người nhắn | Ô tìm kiếm dễ thấy; có phản hồi khi không tìm được hoặc đang mở hội thoại. |
| Hội thoại/xem ảnh | Tăng khả năng đọc, composer tránh bàn phím, gửi/upload/retry rõ ràng và không mất bản nháp. |

Đạt khi người dùng biết nội dung đang ở trạng thái nào và hành động tiếp theo
là gì; lỗi mạng không bị thể hiện thành thành công.

### Đợt 5 — Xác thực, giỏ đi chợ và hoàn thiện (P2/P3)

- Đăng nhập/đăng ký/quên mật khẩu: form gọn, nhãn rõ, lỗi gần trường, loading
  không nhảy layout; Google và email có phân cấp hợp lý. Giữ mật khẩu đã nhập
  khi đổi hiển thị và giữ nội dung khi resize.
- Kiểm tra tài khoản/bị khóa/lỗi xác minh: nội dung dễ hiểu, phân biệt đang chờ
  với lỗi; Thử lại và Đăng xuất rõ ràng theo trạng thái.
- Giỏ đi chợ: làm rõ tiến độ và các nhóm nguyên liệu; kiểm kê chức năng thật.
  Trong đợt UI, bỏ/ẩn các affordance chưa có xử lý hoặc thể hiện trung thực.
  Kết nối giỏ với công thức, lưu bền, chia sẻ và hoàn tất là backlog chức năng
  riêng cần chốt nguồn dữ liệu và hành vi trước khi triển khai.
- Đồng bộ microcopy, focus, semantics, trạng thái disabled/loading và chuyển động.
- Đánh giá trực quan lần cuối tất cả màn; cập nhật tài liệu cũ theo source mới.

## 4. Quy tắc thực hiện

- Sửa token/component trước, sau đó từng nhóm màn; tránh một lần thay tất cả.
- Mỗi đợt có ảnh trước/sau trên điện thoại và tablet, danh sách thay đổi và
  kiểm chứng tương tác thực tế. Golden test dùng fixture ổn định cho màn đại diện.
- Giữ phần trình bày tách khỏi Cubit/repository/router. UI không gọi Firebase.
- Không đổi palette riêng cho từng feature hoặc thêm kích thước cố định để
  che overflow. Không cắt text scale để ép bố cục vừa màn hình.
- Giữ AppBar tab cuộn, AppBar màn con cố định theo quy ước đã thống nhất.
- Dark mode, điều hướng tablet dạng rail, cá nhân hóa, timer và lịch sử nấu
  chưa thuộc phạm vi mặc định; đánh giá riêng khi có yêu cầu và contract.

## 5. Tiêu chí nghiệm thu

- Tất cả route và trạng thái tải/thành công/rỗng/lỗi/đang gửi có cách trình bày
  nhất quán; các nút hiển thị đều có hành vi thực tế rõ ràng.
- Không overflow ở 320/390/599/600/768/1024/1280 px; kiểm tra tablet dọc/ngang,
  bàn phím và chữ 150%–200% ở màn/luồng quan trọng.
- Vùng chạm mục tiêu ít nhất 48 logical px; đo tương phản, kiểm tra focus và
  semantics. Không dùng riêng màu sắc để biểu thị trạng thái quan trọng.
- Xoay máy/resize không mất draft, selection, tab, giỏ đi chợ hoặc stack điều hướng.
- Kiểm tra ảnh dài/ngắn/lỗi tải, tên món/tên người dài, lỗi mạng và retry.
- Chạy `flutter analyze --no-pub`, test liên quan và toàn bộ suite trước bàn giao.
  Ghi rõ cảnh báo có sẵn và kết quả trên thiết bị thật; không dùng test pass
  thay cho đánh giá giao diện hoặc đo hiệu năng trên thiết bị.
- Walkthrough ba tác vụ: tìm và lưu món; chọn nguyên liệu và bắt đầu nấu;
  tạo nháp và gửi công thức. Ghi lại lỗi thao tác và điểm phải quay lại.

Thứ tự triển khai đề xuất: đợt 1 → 2 → 3 → 4 → 5. Chốt hướng nhìn qua ba màn
đại diện trước khi áp dụng toàn app. Ước lượng thời gian sau audit trực quan,
vì khối lượng thay đổi nghiệp vụ của giỏ đi chợ chưa được chốt.
