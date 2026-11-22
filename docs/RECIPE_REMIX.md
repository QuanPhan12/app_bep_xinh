# Biến tấu và đăng lại công thức

## Luồng người dùng

Chi tiết công thức công khai → Tùy chọn công thức → Biến tấu công thức → Bắt đầu
chỉnh sửa. App dùng lại editor 4 bước, component/theme Sollume và màu cam Bếp Xinh.
Không thêm tab điều hướng hay trình soạn riêng.

Người dùng sửa tên, mô tả, ảnh, định lượng, nguyên liệu, thời gian hoặc các bước nấu;
điền “Bạn đã điều chỉnh gì?” (10–500 ký tự). Gửi duyệt yêu cầu có thay đổi nội dung,
không chỉ thêm lời ghi chú vào bản sao nguyên trạng. Xem trước hiển thị nguồn và
điều chỉnh. Bản mới thuộc người đăng lại, trạng thái pending, isBanner=false;
không ghi đè bài gốc, không mang số sao/lượt lưu hay quyền của tác giả gốc sang.

Nguồn hiển thị ở editor, preview, chi tiết bản mới và modal duyệt bài admin.
Nguồn có thể bấm để mở công thức gốc trong app. Biến tấu từ một bản biến tấu ghi
nguồn trực tiếp, người đọc tiếp tục mở nguồn để xem các phiên bản trước.
Chỉ mở tính năng cho bài canonical `r_*` có contentHash, không nhận fixture cục bộ.

## Bảo vệ bản nháp

- Gate nạp nguồn và nháp hiện tại, không ghi đè nháp.
- Nháp cùng nguồn được tiếp tục với các sửa đổi đã lưu.
- Nháp khác yêu cầu xác nhận trước khi vào editor; chỉ thay nháp server khi lưu/gửi.
- Editor tải lại nháp và đối chiếu snapshot đã xác nhận. Nếu nháp vừa bị thay,
  dừng với thông báo mở lại. Revision server tiếp tục chặn phiên cũ ghi đè.
- Bản biến tấu mới được đánh dấu chưa lưu; Back vẫn xác nhận bỏ thay đổi.
- Khi sửa bài biến tấu bị từ chối, giữ nguồn và yêu cầu chỉnh nội dung trước gửi lại.
  Không gắn nhầm revisionOf của nháp khác vào bản biến tấu mới.

## Dữ liệu

Vẫn một document lifecycle `recipes/{id}`. Thêm root `remix` tùy chọn:

```json
{
  "recipeId": "r_original",
  "title": "Tên công thức gốc",
  "authorId": "uid_goc",
  "authorName": "Tên tác giả gốc",
  "sourceHash": "sha256_cua_nguon_64_ky_tu",
  "changes": "Các điều chỉnh do người đăng lại mô tả"
}
```

`content` không đổi schema. Nháp lưu `remix` và `remixBaseline` (fingerprint nội dung
chuẩn hóa để kiểm tra thay đổi). Hash idempotency của bài mới bao gồm cả content và
remix; thay ghi nguồn/ghi chú không bị nhầm với retry của payload cũ.

Repository đọc nguồn trong transaction trước khi tạo bài. Firestore rules kiểm tra
nguồn approved, tên/tác giả/hash khớp snapshot gốc, ghi chú đủ giới hạn; cấm tự duyệt
và thay metadata sau gửi như mọi bài khác. Nguồn vừa ẩn/xóa thì lưu nháp vẫn được,
nhưng gửi bài mới bị từ chối và giữ nội dung đang sửa. Attribution là snapshot,
nên bản đã đăng vẫn giữ tên nguồn nếu nguồn mất công khai về sau; mở link sẽ theo
luồng không tìm thấy có sẵn. Kiểm duyệt nội dung vẫn do admin, không tự xác minh
mô tả điều chỉnh hay tự kết luận chất lượng bản biến tấu.

Đây là additive field, bài cũ không có remix vẫn đọc/gửi bình thường. Không cần
migration hoặc index mới. Cần deploy firestore.rules trước khi app gửi payload mới.

## Kiểm tra

- `flutter analyze --no-pub`, full Flutter suite và các test mới trong recipe_remix_test.
- `tool/recipe_remix_emulator_smoke.cjs`: dữ liệu demo-bepxinh, 33 kiểm tra nguồn,
  trạng thái public/pending, giả mạo metadata, locked user và tự duyệt.
- Rules regression: publishing 29, visibility 60, reports 55 kiểm tra trên emulator.
- Admin: build TypeScript/Vite và domain tests.
- Capture riêng: `flutter test --no-pub test/features/recipe_editor/recipe_remix_visual_test.dart --dart-define=UI_CAPTURE_REMIX=true`.
  12 ảnh gate/editor/preview ở 390×844 và 800×1100, light/dark:
  `build/ui_ux/recipe_remix/`. Dùng fixture và font thật, không ghi dữ liệu production.

Các kiểm tra emulator không tạo công thức hoặc tài khoản trên Firebase thật.

## Kết quả triển khai 17/11/2026

Analyzer sạch; full suite 333 test đạt, 2 capture test skip ở suite mặc định
(capture biến tấu đã chạy riêng và đạt). App release web build thành công.
Admin build thành công, 4 domain test đạt; chưa kiểm chứng modal admin bằng browser.
12 ảnh biến tấu được tạo; đã xem gate mobile light, editor mobile dark và preview tablet light.

Firestore rules đã deploy lên `bepxinh-b0be7`, release active được đọc lại và so khớp
source sau deploy: `projects/bepxinh-b0be7/rulesets/f112bef0-94a2-4476-9519-9e33744c5fe2`.
SHA-256 chuẩn hóa LF: `d0a6a6e569a3f8280cba07b176a71fb1f387bf7dd883bfac6a2bd95c1fb1818f`.
Không có index mới. App/admin mới nằm trong source và bản build local, chưa deploy Hosting.

Thanh chi tiết chỉ có một More (⋯), chứa Lưu/Bỏ lưu, Biến tấu và Báo cáo. Mục không hợp lệ được ẩn, thao tác Lưu bị khóa khi request đang chạy.

Post Home và bảng tin Theo dõi hiển thị icon liên kết cùng “Biến tấu từ <tên tài khoản
chủ công thức gốc>” dưới header tác giả. Chạm dòng này mở công thức gốc, không mở lại
bản biến tấu. Tên dùng snapshot authorName của nguồn, không giả handle từ UID.
RecipeItem giữ remix qua parser, copyWith yêu thích và Equatable để realtime không
làm mất thông tin nguồn. Bài thường không có hàng trống bổ sung.
