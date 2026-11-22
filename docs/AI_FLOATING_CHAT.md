# Chat AI nổi và vòng đời phiên

- Avatar AI nằm trong body của navigation shell, phía trên bottom navigation trên điện thoại và bên phải sidebar trên tablet. Kéo avatar để đổi vị trí; chạm để mở `/messages/ai`.
- Vị trí dùng tọa độ tương đối, giới hạn theo body và safe area; giữ khi chuyển tab hoặc thay đổi kích thước. Các route chi tiết nằm ngoài shell không hiển thị avatar.
- `AiChatSessionScope` nằm dưới provider có key theo UID trong `app.dart`. Route chat chỉ sở hữu controller nhập và cuộn; Cubit thuộc phiên tài khoản.
- Rời route vẫn giữ hội thoại, bản nháp, trạng thái gửi và request ID để tránh gửi trùng khi thử lại. Yêu cầu đang chạy được nhận kết quả khi người dùng mở màn hình khác.
- Mở lại không tải đè lịch sử đã tải thành công; lần tải lỗi vẫn có thể thử lại. Khi đổi tài khoản/đăng xuất, scope cũ đóng Cubit, không chuyển dữ liệu phiên sang tài khoản mới.
- Lần đầu mở tải 6 tin mới nhất. Cuộn lên tải từng trang 6 tin cũ hơn. Khi gửi câu hỏi, truy vấn ngữ cảnh chỉ lấy 8 tin mới nhất.
- Bản nháp và vị trí avatar chỉ giữ trong bộ nhớ trong phiên chạy app. Khởi động lại dùng lịch sử đã lưu từ repository; không giữ bản nháp qua lần khởi động mới.
- Kiểm thử: `test/features/ai_chat_session_test.dart`, `test/features/ai_chat_test.dart`, `test/features/tablet_layout_test.dart`.
