# Triển khai Firestore production — 16/11/2026

27/11/2026: bổ sung rules `catalogs/ingredients/additions/{id}` cho tên nguyên liệu
AI dùng chung toàn app; contract và giới hạn xác thực trong
[Danh mục nguyên liệu](INGREDIENT_CATALOG.md). Cần phát hành rules trước hoặc cùng
web mới; không seed/chỉnh dữ liệu production để kiểm thử.
Đã phát hành lúc 20:43 (UTC+7), Hosting `d1d8e3d3a4695071`, ruleset
`3e5e7398-4f52-46f5-9ee9-1dd24161729a`; đọc lại source rules và hash web live
đã khớp. Biên bản đầy đủ trong tài liệu danh mục trên.

Cập nhật 27/11/2026 lúc 16:50: quyền riêng tư nhật ký ăn và lượt AI dinh dưỡng
đã phát hành cùng web. Ruleset/hash/kiểm chứng mới nhất trong [Ước tính calo](NUTRITION.md).

Cập nhật mới nhất 27/11/2026: rules cho bữa nhiều món/phiên nấu/giỏ thật và
Hosting app đã phát hành, đọc lại khớp source. Ruleset, hash, kết quả xác minh nằm
trong [Nấu một bữa](MEAL_COOKING.md). Phần bên dưới là biên bản đợt 16/11.

Project: `bepxinh-b0be7`, database `(default)`.
Chỉ deploy Firestore rules/index, không deploy Hosting hoặc thay dữ liệu người dùng.
Tài khoản triển khai là tài khoản CLI được người dùng xác nhận riêng trong phiên làm việc.

## Rules đã phát hành

Đây là bản ghi đợt 18:05. Đợt bổ sung quyền quản lý bài lúc 18:38 xem
[ẩn/xóa bài](RECIPE_VISIBILITY.md). Bản mới nhất bổ sung báo cáo món lúc 21:52;
ruleset/hash hiện hành nằm trong [báo cáo món](RECIPE_REPORTS.md).

- Thời điểm server: `2026-11-16T11:05:35.983331Z` (18:05:35, UTC+7).
- Ruleset: `3642ba67-0cbb-4eea-92ce-446b9cf3f021`.
- SHA-256 sau chuẩn hóa CRLF/LF:
  `4b09fb5e66c090be0a223c5d6f7d0ecbf0714ffe1f5e186d766cfa9490c11d59`.
- Nội dung đọc lại từ Firebase Rules API khớp source `firestore.rules`.
- Bản trước cho phép `read, write: if true`; bản mới áp dụng phân quyền và validation
  cho hồ sơ, nguyên liệu, bài đăng, chat, nhật ký, bộ sưu tập và đánh giá.

Snapshot trước/sau lưu cục bộ tại `build/firestore-deploy-1794826966042`.
Đây là snapshot cấu hình rules/index, không phải backup dữ liệu Firestore.

## Index

- Giữ 9 composite index hiện có.
- Tạo thêm `user_reviews`: `status ASC`, `updatedAt DESC`, scope `COLLECTION`.
- Index mới: `CICAgNi4-ZIK`; đã xác minh `READY` lúc 18:11:43 UTC+7.
- Cả 10 composite index đều `READY`; không còn index đang xây dựng.
- Các field override hiện có được giữ nguyên; không ép xóa index ngoài cấu hình.

## Xác minh

Trước deploy, chạy lại 211 kiểm tra trên project demo cô lập:

- Auth/Firestore: 57.
- Đăng và duyệt công thức: 29.
- Chat/thông báo: 52.
- Góc bếp và đánh giá: 73.

Sau deploy, kiểm tra production chỉ đọc:

- Catalog nguyên liệu công khai: HTTP 200.
- Guest liệt kê `users`: HTTP 403.
- Ruleset đang active và hash khớp source; cả 10 index đều `READY`.

Log cục bộ: `build/rules_deploy_regression.log`, `build/rules_deploy_approved.log`,
`build/rules_deploy_verified.log`, `build/rules_deploy_public_check.log`.
Không tạo tài khoản hay ghi dữ liệu thử vào production. Kiểm tra trên emulator
không thay thế xác nhận các thao tác thực tế bằng tài khoản người dùng trong app.
