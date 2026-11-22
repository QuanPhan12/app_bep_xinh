# Thông báo và nhắn tin

## Kiến trúc và giao diện

Home có hai icon Phosphor với tooltip Thông báo/Nhắn tin, có cả khi tải hoặc lỗi.
Hai icon hiện chấm đỏ khi có thông báo/hội thoại chưa đọc. `HomeUnreadCubit`
nghe repository realtime qua `HomeUnreadScope` đặt trên router, trong phạm vi
repository theo UID. Đọc ở màn con sẽ cập nhật badge Home; chỉ mở danh sách
không đánh dấu tất cả đã đọc. Đăng xuất/đổi tài khoản hủy listener và xóa badge cũ.
Lỗi mạng giữ dấu hiệu gần nhất, không tự coi nội dung là đã đọc. Không sửa Rules
hoặc tạo số thông báo giả để hiển thị badge.
`HomeScreen` cấp callback qua `HomeActionScope`; `HomeAppBar` chỉ trình bày và
dùng kiểm soát tap chung. Màn mới là route ngoài bottom navigation, có AppBar
gradient cố định; tab Home giữ nền trùng màn hình và tiêu đề căn trái.
Callback mở route kết thúc ngay sau `push`, không trả Future chờ màn con đóng
cho `AppTapHandler`. Nhờ đó nút thử lại/soạn tin trên màn mới không bị khóa;
các thao tác ghi bất đồng bộ vẫn giữ cơ chế chống bấm lặp như trước.

Các feature tách `screens → widgets → Cubit → repository`.
Repository Firebase được inject trong `AppBepXinh`, tạo lại theo UID. Widget không
gọi Firestore. Tái sử dụng `AppPageScaffold`, `AppSliverAppBar`, `AppFeatureHeader`,
`AppCard`, `AppAvatar`, `AppSearchBar`, `AppTextField`, `AppMessenger`, `AppTap`.
`AppInboxBody`, `AppInboxFilters`, `AppInboxEmpty` dùng chung cho hai feature.

## Thông báo thật

`/notifications` nghe tối đa 100 bài mới nhất của tài khoản qua query
`recipes.where(authorId == uid).orderBy(submittedAt, descending: true)`.
Chỉ `approved`/`rejected` được chuyển thành thông báo. Duyệt bằng công cụ IAM
hoặc Console đều cập nhật realtime; không cần thêm collection thông báo hay
để client tự tạo quyết định duyệt. Bài approved mở chi tiết; rejected mở Bài đã gửi.

```text
users/{uid}/notification_reads/{recipeId}_{status}
  readAt: server timestamp
```

Dấu đã đọc thuộc riêng tài khoản, tồn tại qua đăng xuất/đăng nhập. Đánh dấu tất cả
chỉ áp dụng các thông báo đang tải, không đánh dấu nhầm thông báo mới đến trong lúc ghi.
Đây là thông báo trong app, chưa tích hợp push FCM hoặc thông báo hệ điều hành.

## Tin nhắn thật

`/messages`: query `memberIds array-contains uid`, sắp xếp `updatedAt` giảm dần,
tối đa 50 hội thoại. Lọc chưa đọc theo timestamp server và `readAt[uid]`;
dấu chấm là hội thoại có tin mới, không giả lập số lượng tin chưa đọc.

`/messages/new`: tìm người nhận trong tác giả của 100 công thức công khai mới nhất,
loại tài khoản hiện tại. Không mở quyền list collection `users` riêng tư.
Chọn tác giả tạo/mở hội thoại cặp đôi. Rules kiểm tra người nhận có tài khoản
active, là tác giả của bài approved và tên snapshot khớp bài đó.
Khi đang tạo, tác giả được chọn hiện vòng tải. Nếu tạo thất bại, màn giữ danh
sách người nhận và hiện lỗi qua `AppMessenger` để tránh cảm giác nút không hoạt động.

`/messages/:id`: nhận tối đa 100 tin gần nhất realtime, thứ tự cũ → mới khi hiển thị.
Tin dài tối đa 2.000 ký tự, hỗ trợ xuống dòng. Mỗi tin có thể kèm một ảnh hoặc
chỉ gửi ảnh không có chữ. Chưa có file khác, nhóm chat, trạng thái online/typing
hoặc phân trang lịch sử cũ hơn.

Nút Chọn ảnh dùng lại `ImagePickerRecipeCoverPicker` qua `ChatImageService`,
giới hạn 8 MB, giải mã kiểm tra trước khi xem trước. Ảnh được giảm tối đa
1920 × 1920 khi nền tảng hỗ trợ, upload bằng `CloudinaryRecipeImageUploader`
với tag `bep_xinh_chat`; định dạng nhận từ upload là JPG/JPEG/PNG/WebP.
Chọn/xem trước không upload; chỉ khi bấm Gửi mới tải ảnh lên. Có thể bỏ ảnh
trước khi gửi. Lỗi upload hoặc ghi Firestore giữ cả ảnh và lời nhắn để thử lại.
Upload thành công được giữ trong Cubit để retry ghi tin không upload lại.
Chạm ảnh đã gửi mở viewer toàn màn hình, hỗ trợ phóng to/thu nhỏ.

Cloudinary đang dùng URL công khai của hạ tầng upload hiện có: quyền thành viên
Firestore bảo vệ lịch sử và metadata, không bảo vệ tải ảnh khi URL đã được chia sẻ.
Người có URL có thể xem ảnh; giới hạn này được hiển thị ngay trong phần xem trước.
Chưa có bucket media riêng hoặc xóa tự động ảnh upload thành công nhưng gửi tin
thất bại rồi bị người dùng bỏ. Không coi đây là ảnh mã hóa đầu cuối.

```text
conversations/{sha256(jsonEncode(sorted([uidA, uidB])))}
  memberIds: [uidA, uidB]
  memberNames: {uidA: nameA, uidB: nameB}  # snapshot lúc tạo
  recipeId: bài approved dùng khi bắt đầu trò chuyện
  createdAt, updatedAt: server timestamp
  lastMessageId: null | messageId
  lastMessageText: string
  lastSenderId: null | uid
  readAt: {uid: server timestamp}

conversations/{id}/messages/{requestId}
  senderId: uid
  text: string
  image: {id, name, url, publicId}  # tùy chọn, chỉ URL HTTPS Cloudinary đúng cloud
  createdAt: server timestamp
```

Không lưu bytes/base64 hoặc đường dẫn thiết bị vào Firestore. Tin chỉ ảnh có
preview `📷 Ảnh`; tin kèm chữ dùng lời nhắn làm preview. Rules kiểm tra URL và
schema đính kèm, vẫn yêu cầu transaction cập nhật đúng preview và đúng thành viên.

Gửi bằng transaction: tạo message và cập nhật preview cùng commit.
`requestId` ngẫu nhiên 128 bit được giữ khi thử lại cùng bản nháp, tránh gửi trùng
nếu đã commit nhưng mất phản hồi. Snapshot là nguồn lịch sử duy nhất, Cubit không
tự chèn lại message từ kết quả gửi. Lỗi giữ bản nháp, khóa tap gửi lặp và báo qua
`AppMessenger`. Khi đóng màn/đổi UID, Cubit hủy subscription và bỏ kết quả muộn.

Rules chỉ cho thành viên active đọc; không cho giả sender, đổi thành viên,
sửa/xóa tin nhắn hay sửa dấu đã đọc của người còn lại. Preview phải khớp message
mới được ghi cùng transaction. Không có quyền admin từ field do client tự khai.

Listener đầu tiên chờ tối đa 20 giây rồi hiện lỗi/thử lại; listener vẫn có thể
phục hồi khi có snapshot mới. Snapshot cache có thể xuất hiện trước server.
Transaction gửi giới hạn 20 giây, UI chờ tối đa 25 giây; retry dùng cùng requestId.
Giới hạn trên là giới hạn tải hiện tại, chưa phải inbox/lịch sử không giới hạn.

## Kiểm thử và triển khai

Không tạo người dùng hoặc tin thử trên project production. Rules smoke chỉ
chấp nhận project `demo-bepxinh` và địa chỉ emulator loopback.

```powershell
flutter test --no-pub test/features/communication
firebase emulators:exec --project demo-bepxinh --only auth,firestore "node tool/communication_emulator_smoke.cjs"
flutter build web --debug --no-pub --target tool/communication_sdk_smoke.dart --output build/communication-smoke-web
firebase emulators:exec --project demo-bepxinh --only auth,firestore "node tool/firebase_sdk_browser_smoke.cjs --communications"
```

Firebase CLI cần Java 21 trở lên. Nếu ổ C thiếu chỗ, đặt TEMP/TMP vào thư mục
`build/communication_temp` trên ổ D trước khi chạy Flutter/emulator.

Chỉ triển khai Rules/index sau khi kiểm tra emulator qua:

```powershell
firebase deploy --only firestore:rules,firestore:indexes --project bepxinh-b0be7
```

Index mới: `conversations(memberIds CONTAINS, updatedAt DESC)`.
Chờ index ở trạng thái READY trước khi đánh giá truy vấn production. Không chạy
các entrypoint smoke với cấu hình Firebase production; chúng cố định project demo.

Xác minh ngày 10/11/2026: toàn bộ 238 test Flutter đạt, 43 kiểm tra Rules trên
emulator đạt, 12 kiểm tra Flutter Firebase SDK trong Chrome đạt. SDK dùng hai
tài khoản emulator để kiểm tra gửi/nhận realtime, retry không trùng, dấu đã đọc,
thông báo duyệt và dữ liệu sau đăng xuất/đăng nhập. Có ảnh rà giao diện trong
`build/ui-review/communication`.

Đã triển khai Rules/index lên production `bepxinh-b0be7` ngày 10/11/2026 sau
khi người dùng xác nhận. Đọc lại release xác nhận Rules khớp file local và đã
có quyền `conversations`, `notification_reads`. Index
`conversations(memberIds CONTAINS, updatedAt DESC)` đã ở trạng thái `READY`.
Log xác minh: `build/communication_deploy.log`, `build/communication_live_check.log`.
Không tạo tài khoản hoặc gửi tin thử trên production trong bước triển khai này.

## Cập nhật gửi ảnh

Code hỗ trợ chọn/xem trước/bỏ ảnh, gửi ảnh riêng hoặc kèm chữ, mở ảnh phóng to
và giữ ảnh khi thử lại. Bản mở rộng đã qua toàn bộ 245 test Flutter, 52 kiểm tra
Rules emulator và 15 kiểm tra Flutter Firebase SDK; kiểm tra cuối các file mới/sửa
không có lỗi analyzer. Log: `build/chat_image_full_tests.log`,
`build/chat_image_rules.log`, `build/chat_image_sdk_result.log`.

Kiểm thử SDK truyền metadata URL ảnh fixture giữa hai tài khoản emulator;
uploader Cloudinary được kiểm tra bằng HTTP mock, không tạo asset thật trong
bộ test này. Cloudinary tái sử dụng cấu hình upload hiện có của ứng dụng.

Rules gửi ảnh đã triển khai lên production `bepxinh-b0be7` ngày 10/11/2026 sau
khi người dùng xác nhận riêng. Đọc lại release xác nhận nội dung khớp hoàn toàn
file local; index chat vẫn `READY`, không đổi quyền thành viên.
Log: `build/chat_image_deploy.log`, `build/chat_image_live_check.log`.
CLI báo lỗi sau dòng Deploy complete, nhưng kiểm tra release độc lập xác nhận
Rules đã được phát hành đúng; không chạy deploy lại chỉ vì mã thoát cuối CLI.
Chưa gửi ảnh thử giữa tài khoản người dùng thật trên production.

Gửi món qua chat và thẻ công thức: xem [CHAT_RECIPES.md](CHAT_RECIPES.md) cho schema recipe, điều kiện công khai và kiểm thử. Nút đính kèm hiện gom chọn ảnh/công thức vào cùng menu.
