# Báo cáo món — 16/11/2026

## Sử dụng

Chi tiết công thức công khai → biểu tượng cờ **Báo cáo món** → chọn loại vi phạm,
nhập lý do 1–500 ký tự và gửi. Cần đăng nhập tài khoản active; không báo cáo món
của chính mình, món đã ẩn/xóa hay fixture local. Mỗi tài khoản gửi tối đa một báo
cáo cho một ID món, không sửa/xóa hoặc gửi lại sau khi xử lý. Mở lại form xem
trạng thái chờ xử lý/đã xử lý/không vi phạm. Nội dung công thức không thay đổi
trong lúc gửi báo cáo, không tự ẩn theo số lượt báo cáo.

Admin → **Báo cáo món** (`?view=recipe-reports`) → xem báo cáo và mở công thức.
Admin nhập kết quả xem xét rồi chọn **Ẩn bài và xử lý** hoặc **Không vi phạm**.
Ẩn bài gỡ banner và ghi audit visibility cùng transaction đóng báo cáo. Nếu món
tác giả đang ẩn, admin tiếp nhận quyền ẩn; nếu đã bị admin ẩn hoặc chủ bài xóa,
chỉ ghi nhận món không còn công khai. Không vi phạm giữ nguyên trạng thái món.
Moderator được đọc báo cáo, không được xử lý/ẩn món. Kết quả đóng là bất biến.

## Dữ liệu và quyền

`recipe_reports/{uid}:{recipeId}`:

| Trường | Ý nghĩa |
|---|---|
| recipeId, recipeTitle | ID và tên món tại lúc gửi, Rules đối chiếu tên với recipe thật |
| reporterId | UID người gửi; không lưu email hoặc snapshot hồ sơ riêng |
| category | unsafe/copyright/spam/inappropriate/other |
| reason | Mô tả vi phạm, tối đa 500 ký tự |
| status | open/resolved/dismissed |
| createdAt | Server timestamp khi gửi |
| resolution | null/hidden/unavailable/dismissed |
| resolutionReason, resolvedBy, resolvedAt | Kết quả xem xét, UID admin, thời gian server; null trước khi xử lý |

ID recipe chỉ gồm chữ, số, dấu gạch dưới/ngang nên dấu `:` phân tách UID và recipe
không gây trùng khóa. Recipe vẫn chỉ có một document canonical `recipes/{id}`.
Người dùng chỉ tạo và đọc báo cáo của mình. Tác giả món không được đọc báo cáo của
người khác; staff được liệt kê/đọc; chỉ admin active được đóng báo cáo. Không cho
client xóa report hoặc sửa lại kết quả, giả mạo UID/thời gian, tự duyệt báo cáo.
Lý do ẩn do admin nhập được tác giả xem qua metadata visibility của bài.

Danh sách admin realtime theo status, tải 50 mục/lần, thứ tự mặc định theo ID;
tìm kiếm trong dữ liệu đã tải. Không hứa thứ tự theo thời gian. Query dùng index
đơn trường mặc định, không cần thêm composite index hoặc migration dữ liệu.

## Kiểm thử và phát hành

Các fixture chỉ dùng `demo-bepxinh`; không tạo báo cáo hay ẩn món production
để kiểm thử. Test nguồn: `tool/recipe_reports_emulator_smoke.cjs` và
`test/features/recipe_reports/recipe_report_test.dart`; admin SDK/UI mở rộng trong
`../admin_bep_xinh/tests/browser-driver.ts` và `browser-emulator.cjs`.

Luồng mới đã đạt 55 kiểm tra Rules và 21 SDK check + 15 UI check admin qua Chrome.
Form được kiểm tra mobile/tablet với dark theme, text scale 200%, gửi trùng,
retry khi lỗi và đóng Cubit trong lúc request đang chạy. Log phát hành/kiểm thử
cuối cùng lưu cục bộ ở `node_modules/.cache/report-release`.

Xác minh cuối: analyzer sạch, 42 test Flutter đạt (1 bài chụp ảnh audit tùy chọn
skip), tổng 326 kiểm tra Rules gồm 211 kiểm tra cũ, 60 quyền ẩn/xóa và 55 báo cáo.
Admin production build và 4 domain test đạt; lint còn warning cũ ở prototype và
bundle còn cảnh báo kích thước. Không thao tác tài khoản/báo cáo thật để kiểm thử.

Đã phát hành project `bepxinh-b0be7`, database `(default)`, ngày 16/11/2026:

- Rules lúc 21:52:19 UTC+7, ruleset `cb4bcbb5-0d1f-4d9e-975d-5b380a0fc663`.
  SHA-256 chuẩn hóa CRLF/LF: `afe710ae04c84c7eca3b7384a17e8813632c65b651edbf38efc58947e1ab4878`.
  Đọc lại Rules API khớp source; 10 index hiện có đều READY, không đổi index.
- App web lúc 21:53:19 UTC+7, version `497587b923d8a533`,
  `https://bepxinh-b0be7.web.app`.
- Admin lúc 21:54:04 UTC+7, version `92c3ed759b8d2dfc`,
  `https://bepxinh-admin.web.app/?view=recipe-reports`.
- HTML/bootstrap/main.dart.js app và HTML/JS/CSS admin live khớp artifact local.
  Không phát hành APK/IPA; bản app đã cài cần cập nhật build riêng.
