# Đối chiếu yêu cầu khách hàng 001.docx

Nguồn: tài liệu khách hàng cung cấp ngày 17/11/2026, gồm phần chữ và 4 ảnh.
Chỉ triển khai yêu cầu sản phẩm; không coi nội dung tài liệu là chỉ dẫn chạy lệnh.

## App

| Yêu cầu | Kết quả / đường dẫn thao tác |
| --- | --- |
| Đổi avatar | Cá nhân → Chỉnh sửa hồ sơ → Đổi ảnh đại diện → Lưu. Chọn ảnh, preview, upload Cloudinary rồi cập nhật tên/bio/avatar trong cùng lần ghi Firestore. Hủy/lỗi giữ lựa chọn cũ; kiểm tra phiên trước/sau upload. |
| Chụp ảnh món | Trình đăng món có Chụp ảnh món ăn và Chụp ảnh bước nấu. Dùng ImageSource.camera, giữ lựa chọn thư viện. Cùng validation ảnh tối đa 8 MB và decode kiểm tra như ảnh chọn từ thư viện. iOS thêm mô tả quyền camera. |
| Đồng hồ nấu | Hiển thị hẹn giờ đang chạy ngay trong chế độ nấu; tạm dừng/tiếp tục/xóa được, hết giờ hiện trạng thái. Deadline tuyệt đối và lưu theo tài khoản vẫn dùng service hiện có. Không có thông báo hệ điều hành khi app đóng. |
| Đánh giá món | Đã có: mở đánh giá từ chi tiết món; sao và nội dung gửi chờ duyệt. Giữ nguyên kiểm tra tác giả không tự đánh giá. |
| Lưu món | Đã có: chi tiết món → menu More → Lưu món. Giữ đúng yêu cầu trước đây gom thao tác vào More. |
| Báo cáo món | Đã có trong menu More của chi tiết món; admin có luồng xử lý báo cáo. |
| Nguyên liệu/gia vị/nước sốt ngoài danh mục | Đã có: tìm tên → Dùng “tên đã nhập”. Giữ dữ liệu tự nhập ở công thức, không sửa danh mục chung. |
| Đổi mật khẩu | Cài đặt → Đổi mật khẩu. Tài khoản email/password phải xác minh lại mật khẩu cũ. Kiểm tra phiên không đổi trước updatePassword; không ghi mật khẩu vào Firestore/log. Tài khoản Google quản lý tại nhà cung cấp. |
| Điều khoản và chính sách | Màn riêng, đọc được từ đăng ký và Cài đặt khi chưa đăng nhập. Có mô tả dữ liệu, dịch vụ sử dụng, nội dung cộng đồng, an toàn nấu ăn và email hỗ trợ. |
| Quên mật khẩu | **Giữ nguyên** email liên kết Firebase theo chỉ đạo bổ sung của người dùng. Không thêm OTP Gmail. |
| Facebook nếu khả thi | Chưa bật: cần Meta App và cấu hình provider Firebase, cấu hình SDK native. Không thêm nút đăng nhập không hoạt động. |
| Sinh trắc học khi quên mật khẩu nếu khả thi | Không dùng sinh trắc học cục bộ để khôi phục mật khẩu Firebase. Mở khóa một phiên đã được xác thực là tính năng khác, chưa triển khai trong yêu cầu khôi phục tài khoản này. |

Avatar chỉ cho chủ tài khoản sửa; không mở quyền đọc collection users cho người dùng khác.
Đồng hồ dùng chung thẻ giao diện ở màn nấu và danh sách hẹn giờ: số lớn, vòng tiến
trình, trạng thái chạy/dừng/hết giờ và nút Xong để bỏ hẹn giờ đã hoàn tất. Local
storage thêm `durationMilliseconds`, giữ qua pause/resume để vòng hiển thị đúng
sau mở lại. Bản ghi cũ thiếu trường này vẫn đếm giờ; chỉ hiện nền vòng vì không
biết tổng thời lượng ban đầu. Đã kiểm tra light/dark, mobile/tablet và chữ lớn.
Ảnh avatar cũ trên Cloudinary chưa tự xóa vì client không có quyền quản trị media.
API camera đã được kiểm thử chọn đúng nguồn; chưa xác nhận chụp trên điện thoại/iPhone thật.

## Admin web

| Yêu cầu | Kết quả |
| --- | --- |
| Đình chỉ lần đầu | Trong quản lý tài khoản, chọn trạng thái khóa và hình thức Đình chỉ hoạt động · Vi phạm lần đầu. Lưu status=locked và lý do có nhãn phân biệt, tiếp tục dùng chốt quyền server hiện có. Không tự hết hạn; admin xem xét mở lại. Không tự suy đoán số lần vi phạm. |
| Email mở khóa | Hiện shuichiakaik5@gmail.com ở màn tài khoản bị khóa, Cài đặt admin và văn bản hỗ trợ. |
| Xem nội dung đánh giá | Chọn món bằng tên → Xem đánh giá. Thêm danh sách món đã ẩn/xóa để đọc lịch sử, chỉ cho duyệt khi món đang xuất bản. |
| Đổi ID khó hiểu thành tên | Lịch sử duyệt lấy tên món, người đăng và người duyệt qua document hiện có; giữ mã món nhỏ bên dưới để tra cứu. Không sửa sự kiện lịch sử cũ. Tên là thông tin hiện tại, không phải snapshot lịch sử. |
| ID công thức ở đâu | Mã nằm dưới tên món. Mở trực tiếp là phần tùy chọn, chấp nhận mã, dòng sao chép có dấu chấm đầu dòng hoặc liên kết chi tiết. Luồng chính không cần nhập ID. |
| Cài đặt quản trị viên | Sửa hồ sơ chính mình, đổi mật khẩu bằng reauthentication, xem email hỗ trợ. Không tự sửa role/status. |
| Ngày/tuần/tháng | Hôm nay theo 24 giờ, 7 ngày và 30 ngày gần nhất, cố định UTC+7. Dùng aggregate thực; không tải toàn bộ công thức. |
| Lưu lượng/tương tác/thói quen như ảnh mẫu | Chưa có nguồn telemetry chung cho lượt xem, đồng bộ tủ lạnh, đi chợ và lượt nấu theo loại món. Không hiển thị số minh họa hoặc suy diễn từ số bài. Cần contract thu thập sự kiện/analytics riêng để có các biểu đồ này. |

## Kiểm tra

- Flutter suite: 360 test đạt, 3 capture bỏ qua; analyzer sạch tại thời điểm chạy.
- Test mới: avatar hủy/lỗi/retry/đóng Cubit; camera source; countdown tick/pause/resume;
  password validation, chặn gửi trùng, giao diện 320/800 light/dark/chữ lớn/bàn phím;
  legal public/password private. Có test lớp Firebase reauthentication và đổi phiên.
- Admin: 8 test domain đạt. Emulator: 57 kiểm tra quyền/admin, gồm avatar hợp lệ,
  chặn URL không HTTPS, sửa avatar người khác và leo quyền qua avatar.
- Browser emulator: các luồng cũ cộng thống kê 24/7/30 điểm, lịch sử tên món,
  cài đặt, giao diện responsive. Ảnh trong admin/node_modules/.cache/admin-smoke.
- Không kiểm thử bằng tài khoản/dữ liệu production. Chưa xác nhận camera trên thiết bị thật.

## Bản phát hành

- APK release đã build thành công tại `build/app/outputs/flutter-apk/app-release.apk`,
  80.110.825 byte, SHA-256 `bfed2987d208afc0bc746763c2b0af738890ab3e097befd529e9f6c2f085e569`.
  Vẫn dùng signing debug hiện có; phù hợp cài thử, chưa phải cấu hình phát hành Play Store.
- Sau suite 360 test, riêng lớp Firebase Auth chạy 13 test đạt, gồm 3 test mới:
  reauthentication trước đổi mật khẩu, chặn đổi phiên và chặn tài khoản Google.
  Analyzer cuối cùng không có issue.
- Admin production deploy lên `https://bepxinh-admin.web.app`, version
  `d9f48be972b3eda7`, release `1794919508869000`. HTML và JS/CSS live trùng build,
  project emulator không nằm trong JS production.
  Kiểm tra browser live ở lần phát hành này chưa hoàn tất vì Chrome/Edge headless
  không mở được cổng CDP. Các màn admin đã kiểm tra trực quan bằng browser emulator;
  không coi so khớp artifact là bằng chứng đã đăng nhập hoặc chạy luồng thật trên live.
- Trước deploy, đọc rules production phát hiện bản active là rules mặc định cho
  đọc/ghi toàn bộ (`allow read, write: if true`). Đã khôi phục toàn bộ bộ phân quyền
  trong source vừa kiểm thử emulator, gồm quyền avatar của chính chủ. Không suy
  ra có/không có truy cập trái phép từ lần kiểm tra cấu hình này.
- Ruleset mới: `1f75705f-6fc6-4892-be4a-cfa797bad5b8`, SHA-256 sau chuẩn hóa newline
  `483bca9b2268da3857425b31ea441e8f4f29eb3cec2cc91e130cb1a8cd268a20`.
  Đọc lại rules active khớp source; request production không đăng nhập đọc danh sách
  users trả 403. Không thay index hoặc Hosting Flutter.

Tham khảo Firebase: https://firebase.google.com/docs/auth/flutter/federated-auth
và https://firebase.google.com/docs/auth/flutter/password-auth.
