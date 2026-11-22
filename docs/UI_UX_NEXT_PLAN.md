# Kế hoạch cải thiện UI/UX Bếp Xinh

Trạng thái: đã được yêu cầu triển khai ngày 18/11/2026. Xem kết quả và bằng chứng
tại [UI_UX_REFINEMENT_IMPLEMENTATION.md](UI_UX_REFINEMENT_IMPLEMENTATION.md).
Phạm vi: toàn bộ app Flutter, không bao gồm admin.

## Định hướng

Giữ theme/component Sollume đã port, cam thương hiệu `#E8590C`, font Be Vietnam Pro
và light/dark. Nâng chất lượng bằng phân cấp nội dung, bố cục và tính nhất quán.
Không thêm tính năng trong đợt làm giao diện; giữ hành vi tìm kiếm, đăng món,
duyệt bài, biến tấu, báo cáo, chat và AI đang có.

Đề xuất dựa trên source hiện tại và ảnh Home/chat đã kiểm tra. Cần chụp đầy đủ
các màn/trạng thái trước khi chốt thay đổi cụ thể, không coi source audit là
bằng chứng mọi màn hiện đang lỗi thị giác.

## 1. Chốt chuẩn và ba màn mẫu

- Lập danh sách route, ảnh trước thay đổi và điểm gây khó hiểu của từng màn.
- Chuẩn hóa khoảng cách theo bộ spacing đang có; màu cam ưu tiên hành động chính
  và trạng thái chọn, màu trung tính cho nội dung/hành động phụ.
- Giữ AppSliverAppBar, AppTabBar, AppTextField, nút và menu đã port từ Sollume.
  Loại các ghi đè cục bộ gây khác nhau về chiều cao, padding, radius hoặc màu.
- Chuẩn typography cho tiêu đề, nội dung, metadata; không thu nhỏ chữ để nhét thông tin.
- Dựng Home, Chi tiết món và Bếp của tôi làm ba màn mẫu; đối chiếu ảnh light/dark
  trước khi áp dụng các quy tắc đó cho toàn bộ app.

## 2. Điều hướng và màn chính

| Khu vực | Thay đổi đề xuất |
| --- | --- |
| Điều hướng | Giữ 4 tab hiện tại. Đồng nhất trạng thái chọn, nhãn, app bar, back và safe area. |
| Home | Trật tự tìm kiếm → món nổi bật → bộ lọc → feed. Đồng nhất ảnh/card và metadata; giảm khoảng trống không có chủ đích. Chỉ bấm card để mở chi tiết, không thêm nút mở trùng. |
| Card món | Tên món rõ, ảnh ổn định, thông tin thời gian/độ khó/đánh giá gọn. Giữ sao đánh giá và liên kết nguồn món biến tấu; tránh lặp thông tin tác giả. |
| Tìm kiếm | Đặt tìm kiếm và bộ lọc cùng nhóm; hiển thị bộ lọc đang chọn và cách xóa. Kết quả, không có kết quả và trạng thái đang tìm có bố cục nhất quán. |
| Chi tiết món | Ảnh → tên/nguồn → thông tin chính → nguyên liệu/cách nấu. Một hành động chính Bắt đầu nấu; công cụ phụ ở More như hiện tại. Kiểm tra thanh hành động khi cuộn và mở bàn phím. |

## 3. Các luồng công việc

| Khu vực | Thay đổi đề xuất |
| --- | --- |
| Tủ lạnh | Làm rõ trình tự thêm nguyên liệu → nguyên liệu đang có → món phù hợp. Thể hiện đủ/thiếu nguyên liệu bằng nhãn dễ hiểu; làm gọn các nhóm mở rộng. |
| Bếp của tôi | Tăng tính hữu ích của màn hub bằng bản tóm tắt dữ liệu thật như bữa sắp tới/hẹn giờ đang chạy khi có. Bên dưới giữ các nhóm Chuẩn bị bữa ăn, Công thức của bạn, Nấu và ghi nhớ; tránh biến toàn màn thành danh sách shortcut giống nhau. |
| Thực đơn | Phân cấp rõ ngày, bữa và món. Thao tác thêm/đổi món theo đúng ô bữa; bảng tablet có độ rộng hợp lý. |
| Kho nguyên liệu / giỏ mua | Dễ phân biệt còn dùng, sắp hết hạn, cần mua. Nút thay số lượng và đánh dấu hoàn thành có vùng chạm đủ lớn. |
| Bộ sưu tập / offline / nhật ký / theo dõi | Dùng cùng mẫu trang danh sách, item và menu phụ. Empty state nói rõ bước tiếp theo thay vì chỉ ghi chưa có dữ liệu. |
| Hẹn giờ | Giữ vòng tiến độ đã làm; thống nhất căn hàng, số thời gian và vị trí tạm dừng/tiếp tục/hoàn tất. Nhiều đồng hồ không tranh nhau màu nhấn. |
| Đăng / sửa / biến tấu | Nhóm theo Thông tin món, Nguyên liệu, Cách nấu; giữ bản nháp và validation. Ảnh preview, thêm bước, lỗi từng mục và nút lưu rõ ràng. Không đổi thành wizard trước khi kiểm tra nhu cầu thực tế. |

## 4. Cá nhân, giao tiếp và trạng thái

- Cá nhân: avatar/tên/bio/thống kê rõ thứ bậc; hành động đăng món và sửa hồ sơ
  không cạnh tranh. Tab nội dung và empty state cùng chuẩn với hồ sơ công khai.
- Chat: AI là hội thoại ghim đầu danh sách, cùng style với chat người dùng.
  Đồng nhất avatar, preview, unread và thời gian. Ô nhập/nút gửi thẳng hàng ở
  trạng thái rỗng, nhiều dòng, đang gửi và khi bàn phím mở.
- AI: avatar/giọng điệu nhất quán, thẻ món dễ bấm. Phân biệt lỗi tải lịch sử,
  lỗi provider và giới hạn lượt dùng bằng thông báo có hành động phù hợp.
- Thông báo/đánh giá: ưu tiên nội dung, trạng thái chưa đọc, số sao và thời gian;
  giảm icon/trang trí không mang ý nghĩa.
- Đăng nhập/đăng ký/quên mật khẩu/cài đặt: giữ component Sollume; thống nhất
  chiều rộng form, nhãn, validation và back. Form cuộn được khi bàn phím mở.
- Loading, empty, error, offline và thành công cần được thiết kế cùng màn chính.
  Không đổi chiều cao lớn đột ngột hoặc làm mất nội dung/draft khi có lỗi.

## 5. Responsive và nghiệm thu

- Mobile: kiểm tra 320, 390, 430 px; tablet: 600, 800, 1024 px và xoay ngang.
  Kiểm tra thêm hai phía của breakpoint thực tế trong AppResponsive/AppLayout.
- Tablet dùng cột/grid theo nội dung; màn hội thoại/form có chiều rộng tối đa
  vừa đọc. Không chỉ kéo giãn giao diện mobile, không thay cách điều hướng tùy hứng.
- Vùng chạm tối thiểu 48 logical px cho nút thao tác; kiểm tra chữ hệ thống 1.5–2x,
  tương phản, keyboard inset, safe area và tiêu đề dài tiếng Việt.
- Chụp ở kích thước logic thật; ảnh nằm trong DevicePreview thu nhỏ chỉ là bổ sung.
- Mỗi đợt có ảnh trước/sau light/dark trên mobile/tablet, analyzer và các test liên quan.
- Sau khi duyệt màn mẫu mới triển khai cuốn chiếu phần còn lại. Chỉ deploy khi
  hoàn thành kiểm tra chức năng và kiểm tra artifact live.

## Thứ tự bàn giao

1. Audit và chuẩn component; ba màn mẫu Home / Chi tiết món / Bếp của tôi.
2. Home, tìm kiếm, chi tiết, điều hướng và Tủ lạnh.
3. Các công cụ Bếp của tôi, editor, cá nhân và giao tiếp.
4. Auth/cài đặt/trạng thái phụ; responsive và hồi quy toàn app.

Tiêu chí hoàn thành: người dùng nhận ra mục đích và hành động chính của mỗi màn;
không có nút điều hướng trùng; không overflow/bàn phím che thao tác; light/dark
và component nhất quán; chức năng hiện có được giữ và có bằng chứng kiểm tra.
