# Gửi công thức trong chat

## Giao diện và luồng

Trong hội thoại: Đính kèm (+) → Chọn công thức → tìm theo tên (có/không dấu) → chọn
món → xem trước, thêm lời nhắn tùy chọn → Gửi tin nhắn. Chọn món không tự gửi.
Có thể bỏ thẻ trước khi gửi. Nút đính kèm dùng cùng menu để chọn ảnh hoặc công thức,
không thêm hàng nút vào composer. Thẻ chứa ảnh, tên món; bấm mở chi tiết công thức.
Thẻ có trong cả tin gửi và tin nhận, dùng theme light/dark và màu cam hiện có.

Mỗi tin có tối đa một loại đính kèm: ảnh hoặc công thức. Chọn loại khác chỉ thay
đính kèm sau khi đã chọn thành công; hủy không làm mất ảnh/công thức hoặc lời nhắn
trước đó. Chọn/xem trước công thức không upload ảnh.

Picker tải tối đa 100 món approved mới nhất từ PublishedRecipeSource khi mở, tìm
trong danh sách đó, không truy vấn users riêng tư hay dùng dữ liệu món giả. Có
loading/error/retry/empty; màn nhỏ dùng sheet, tablet dùng dialog. Tìm kiếm title
không phải truy vấn toàn bộ lịch sử hoặc tìm theo nguyên liệu.

## Contract

MessageRepository.loadRecipes cấp ChatRecipe; ChatRecipesCubit quản lý tải/tìm.
ConversationCubit giữ lựa chọn, thao tác async và requestId. Widget không gọi Firestore.
ConversationContent sở hữu điều hướng, MessageBubble/ChatRecipeCard nhận callback.

Schema cũ giữ nguyên; thêm field tùy chọn:

```text
conversations/{id}/messages/{requestId}
  senderId, text, createdAt         # như cũ
  recipe: {id, title, cover}         # tùy chọn
    cover: {id, name, url, publicId}
```

Không sao chép nguyên liệu/cách nấu vào tin nhắn. Nội dung có chữ vẫn tối đa 2.000
ký tự, recipe-only có text rỗng. Preview inbox: text nếu có, nếu không là 🍽 <tên món>.
Không cần index mới hoặc migration. Tin chữ/ảnh cũ vẫn hiển thị như trước; client
cần cập nhật để hiển thị loại thẻ mới.

Repository kiểm tra nguồn approved và snapshot title/cover khớp trong transaction.
Rules kiểm tra lại, chặn nguồn pending/rejected/hidden/deleted, metadata giả mạo,
ảnh và món trong cùng tin, sender giả danh, preview không khớp và người ngoài hội thoại.
Message và preview/readAt của người gửi phải commit cùng nhau. Không mở quyền sửa/xóa
lịch sử hoặc quyền đọc chat cho admin/người ngoài. Ảnh thẻ là URL công khai của công
thức đã duyệt, không có cơ chế media riêng mới.

Nếu món bị ẩn/xóa trước khi gửi, gửi bị từ chối và lựa chọn/lời nhắn được giữ.
Nếu nguồn mất công khai sau khi đã gửi, snapshot trong lịch sử vẫn còn; bấm thẻ
đi qua kiểm tra quyền/trạng thái hiện có ở màn chi tiết. Không dùng snapshot chat
để vượt quyền xem nội dung gốc.

Retry cùng payload giữ requestId; repository so cả text/image/recipe với tin đã
commit để không gửi trùng khi mất phản hồi. Đổi lời nhắn/đính kèm tạo requestId mới.
Chỉ snapshot realtime cập nhật lịch sử; không tự chèn tin giả vào danh sách.

## Kiểm tra

- Unit: recipe-only/caption, lỗi/retry cùng ID, đổi/hủy/xóa đính kèm, không upload,
  đóng Cubit khi picker chưa trả kết quả, tìm không dấu và payload không hợp lệ.
- UI: chọn → preview → gửi → mở chi tiết → quay lại; lỗi picker và retry không giữ
  khóa tap; keyboard/chữ lớn ở 320/800px; luồng gửi ảnh cũ.
- `tool/chat_recipe_emulator_smoke.cjs`: chỉ demo-bepxinh, 80 kiểm tra chat/text/ảnh/
  công thức và quyền thành viên. Không tạo tin nhắn/tài khoản trên production.
- Capture riêng: `flutter test --no-pub test/features/communication/chat_recipe_visual_test.dart --dart-define=UI_CAPTURE_CHAT_RECIPE=true`.
  12 ảnh tại `build/ui_ux/chat_recipe/` cho picker/preview/sent, mobile/tablet,
  light/dark. Ảnh asset là fixture của capture, không phải payload repository thật.

## Kết quả xác minh ngày 17/11/2026

- Flutter: toàn bộ suite 352 test đạt (2 capture bỏ qua); analyzer không có issue.
- Emulator: 80 kiểm tra đạt; capture riêng tạo đủ 12 ảnh và đã xem mobile/tablet,
  light/dark. Web release build thành công.
- Đã deploy riêng Firestore rules lên `bepxinh-b0be7` và đọc lại rules đang active,
  xác nhận trùng source local sau chuẩn hóa newline.
  Ruleset: `a881e064-92db-4898-b0aa-d7d90092ca53`.
  SHA-256: `617455f91ecd9b3a301e907eee22db986ced56afefc53598dbbe9dc0162df823`.
- Chưa deploy Firebase Hosting; chưa gửi tin thử trên production.
