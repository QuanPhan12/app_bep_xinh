# Quyền ẩn/xóa bài — 16/11/2026

Nguồn duy nhất vẫn là `recipes/{id}`. Không sao chép nội dung sang collection khác.
Contract đầy đủ: [đăng và duyệt công thức](RECIPE_PUBLISHING.md).

## Sử dụng

App: Hồ sơ → **Quản lý bài đăng**, hoặc Cài đặt → **Bài đã gửi**.
Ẩn bài đã duyệt, hiện lại bài tự ẩn hoặc xóa bài chưa xóa. Mỗi thao tác có xác nhận;
bài admin ẩn hiển thị lý do và không có nút hiện lại cho tác giả.
Nếu đang có nháp sửa từ bài bị từ chối, app yêu cầu gửi bản nháp trước khi xóa
bài gốc để tham chiếu revisionOf không bị mất điều kiện gửi.

Admin: **Duyệt công thức** → **Đã duyệt** → **Ẩn bài**, nhập lý do và xác nhận.
Tab **Đã ẩn** cho phép hiện lại bài admin ẩn hoặc tiếp nhận bài tác giả đã ẩn bằng
**Giữ ẩn bởi admin**. Tab **Đã xóa** chỉ đọc. **Lịch sử ẩn/xóa** hiển thị audit thật.
Moderator được đọc nhưng không có quyền ẩn/hiện bài.

| Người thực hiện | Từ trạng thái | Sang trạng thái |
|---|---|---|
| Chủ bài active | approved | hidden, vai trò author |
| Chủ bài active | hidden do author | approved |
| Chủ bài active | pending/approved/rejected/hidden | deleted |
| Admin active | approved hoặc hidden do author | hidden, vai trò admin; bắt buộc lý do |
| Admin active | hidden do admin | approved |

Không chuyển deleted về trạng thái khác. Không cho admin hiện lại bài tác giả đang
ẩn; muốn tiếp nhận kiểm duyệt phải ghi quyết định ẩn của admin trước. Mỗi thao tác
đều đặt `isBanner: false`; hiện lại không tự khôi phục banner.

## Bảo toàn dữ liệu

Xóa là xóa khỏi app bằng tombstone `deleted`, không xóa vật lý document, ảnh
Cloudinary, đánh giá hay lịch sử. App không cung cấp khôi phục. Đây không phải
quy trình xóa tài khoản/dữ liệu cá nhân. Feed/banner/tìm kiếm/public profile vẫn
chỉ query `approved`, nên bài bị ẩn/xóa rời các danh sách; Home cập nhật realtime.
Quyền đọc công khai bài/review/tổng điểm bị thu hồi ở Rules. Không thu hồi được
bản đã tải hoặc ảnh HTTPS công khai. Màn chi tiết đang mở không tự xóa dữ liệu
đã render; lần tải tiếp theo bị từ chối.

Các trường visibility chỉ được thay cùng status/isBanner, giữ nguyên content,
hash, tác giả và quyết định duyệt cũ. Transaction so sánh status/visibilityEventId
trên server trước khi ghi. Sự kiện `recipes/{id}/visibility_events/{eventId}` là
append-only, bắt buộc cùng commit; chỉ tác giả/staff được đọc, không ai sửa/xóa.
Không ghi log nội dung công thức hoặc lý do của người dùng.

Query bài của tôi dùng status IN pending/approved/rejected/hidden và authorId,
sắp xếp submittedAt giảm dần, tối đa 50; dùng composite index sẵn có. Không cần
migration dữ liệu cũ: metadata visibility được thêm khi thao tác lần đầu.

## Xác minh

- Flutter analyzer sạch; 60 test đạt, 1 bài chụp ảnh audit tùy chọn được skip.
- 60 kiểm tra quyền mới trên demo emulator; 211 kiểm tra Rules cũ đạt.
- Admin: 4 domain test; 17 Firebase SDK check và 11 UI check qua Chrome/emulator.
- Cả app web release và admin production build thành công. Lint admin còn warning
  cũ ở prototype; bundle hiện còn cảnh báo kích thước. Không kiểm thử bằng thao tác
  ẩn/xóa bài thật hay tài khoản người dùng thật trên production.

Log cục bộ: `build/recipe_visibility_*.log`. Chỉ dùng fixture trên `demo-bepxinh`.

## Phát hành

Đợt bổ sung báo cáo món lúc 21:52 cùng ngày đã thay ruleset bên dưới;
Rules hiện hành xem [báo cáo món](RECIPE_REPORTS.md). Nội dung dưới đây là lịch sử
đợt phát hành quyền ẩn/xóa.

Rules đã phát hành lúc 18:38:28 UTC+7, ruleset
`d99c3e9c-f8bd-4e76-8a64-890332306454`; đọc lại Rules API khớp source.
SHA-256 sau chuẩn hóa CRLF/LF:
`ac51419c4f4d90668fb911524dc9266722c54c0610977c24bcc8c19c3dd7ec52`.
Cả 10 index hiện có đều READY, không tạo/xóa index. Snapshot trước/sau:
`build/firestore-deploy-1794829075942`.

App web bản cuối phát hành lúc 18:44:35 UTC+7, Hosting version `ef5b1f2313750c05` trên
`https://bepxinh-b0be7.web.app`. Admin phát hành lúc 18:40:20 UTC+7, version
`602b65cabcb66e4c` trên `https://bepxinh-admin.web.app`. Đã đối chiếu hash HTML,
bootstrap và main.dart.js của app, cùng HTML/JS/CSS của admin với artifact local.
Không phát hành APK/IPA trong đợt này; bản app đã cài cần build/cập nhật riêng.
