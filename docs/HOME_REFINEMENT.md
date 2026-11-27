# Điều chỉnh Home từ phản hồi ảnh thực tế — 16/11/2026

## Số tương tác — 27/11/2026

Post hiện số cạnh tim, bình luận và chia sẻ; icon vẫn đơn sắc, không nền/viền riêng.
Giữ hành động lưu món, mở đánh giá cộng đồng và share hiện có. Số lấy từ metadata
server `engagement`, hỗ trợ k/M và tự xuống dòng khi cần. Contract và cách đồng bộ
dữ liệu cũ tại [RECIPE_ENGAGEMENT.md](RECIPE_ENGAGEMENT.md).

## Cập nhật giao diện khám phá — 26/11/2026

Đợt đầu nâng cấp Home/card/tìm kiếm dùng icon đơn sắc, bỏ viền trang trí và giảm
số lớp nền. Card nổi bật chuyển sang ảnh 64 px trên hàng cao tối thiểu 80 px,
tự tăng theo cỡ chữ; không dùng nền thẻ riêng. Chip chọn có nền trung tính, không viền.
Thanh điều hướng bỏ đường viền trên, nút Đăng món dùng nền trung tính.

Thêm ba điểm vào Trong 30 phút, Từ tủ lạnh và Đang theo dõi. Điểm vào đầu mở bộ
lọc tổng thời gian mới; hai điểm còn lại mở luồng hiện có. Tìm kiếm thêm thời gian,
độ khó, nguyên liệu muốn tránh và lịch sử cục bộ; contract tại `recipe_search.md`.
Không thay luồng đăng/duyệt bài, Firebase Rules hoặc schema.

Fixture Home 390×844 có safe area 44/34: ảnh đầu bảng tin ở 493 logical px trong
cả light/dark, đạt tiêu chí dưới 500 px. Ảnh mới tại `build/ui_ux/discovery-home-light`;
kết quả bên dưới là lịch sử của đợt 16/11, không phải thông số giao diện mới.

Xác minh đợt 26/11: toàn bộ Flutter test đạt 406, skip 4; web release build đạt;
formatter và `git diff --check` đạt. Analyzer còn 5 issue có sẵn ngoài phạm vi
(AI chat, login, kitchen overview, messages). Đã xem ảnh fixture Home light/dark
và sheet lọc mobile; có capture ba kích thước cho Home/tìm kiếm/sheet. Kiểm thử
sheet bổ sung màn ngang 844×390 và 1024×600 với chữ 150% và bàn phím.
Chưa deploy Hosting hoặc kiểm tra trên điện thoại thật trong đợt này.

## Những gì đã sửa

- Bỏ tiêu đề hỏi trùng với tìm kiếm; phần đầu còn thương hiệu và tìm kiếm.
- Món nổi bật dùng thẻ ngang: ảnh vuông 80 px, tên tối đa hai dòng và thời gian
  nấu. Dải thẻ cao 96 px ở chữ mặc định, tự tăng chiều cao khi tăng cỡ chữ.
- Giảm khoảng trống dưới mục nổi bật. Ảnh món trong bảng tin xuất hiện sớm hơn.
- Danh mục `Tất cả` có nền/viền và trạng thái selected rõ; các mục khác có mức nhấn
  thấp hơn. Chạm danh mục vẫn mở đúng route tìm kiếm và bộ lọc tương ứng.
- Chế độ `Mới nhất` / `Theo dõi` có gạch chân và semantics selected theo route;
  dùng chung component trên Home và bảng tin theo dõi. Quay lại không giữ nhầm tab.
- Giữ một thao tác mở chi tiết trên card, cùng các thao tác con lưu/đánh giá/chia sẻ.

## Kết quả kiểm tra bố cục

Ở fixture 390×844, có safe area trên 44 và dưới 34, text scale 100%, ảnh đầu tiên
của bảng tin bắt đầu tại **483 logical px**, cả light và dark.
Phương án thử đầu tiên trong đợt này ở 550.8 px chưa đạt mục tiêu dưới 500 px và
đã được thay bằng thẻ ngang. Đây là phép đo trên fixture, không phải số đo từ ảnh
DevicePreview của người dùng hoặc đảm bảo mọi nội dung/cỡ chữ đều có cùng vị trí.

Kiểm tra cỡ chữ 200% phát hiện metadata có thể xuống dòng gây tràn; đã giới hạn
metadata một dòng và làm tròn chiều cao theo font metrics. Tên vẫn tối đa hai dòng.

## Chọn banner trên admin

Trước khi bật banner mới, giao diện admin mở bản xem trước ảnh cắt vuông và yêu cầu
xác nhận ba tiêu chí: tên đúng nghĩa món ăn, ảnh món đã hoàn thành, nhận diện tốt
khi thu nhỏ. Chỉ bật nút chọn khi ảnh tải được và cả ba tiêu chí được xác nhận.
Gỡ banner giữ thao tác hiện có. Transaction vẫn kiểm tra bài approved và trạng
thái banner hiện tại để tránh ghi đè lựa chọn của người khác.

Đây là bước hỗ trợ người duyệt trong portal, không phải bộ phân loại ảnh hoặc
validation ngữ nghĩa ở server. Không thêm field/schema/audit checklist. Admin có
quyền IAM/SDK vẫn chịu trách nhiệm khi dùng đường ghi ngoài portal.

**Banner đang có không tự bị gỡ hoặc sửa.** Người quản trị cần rà lại tên/ảnh cũ
ở Banner trang chủ. Đợt UI này không sửa nội dung thật, không tự quyết định ảnh
nào là sai, không ghi dữ liệu thử vào production.

## Bằng chứng

- Analyzer sạch; 68 test Flutter liên quan Home/tìm kiếm/theo dõi/công cụ/tablet đạt.
- 12 ảnh mới: Home và bảng tin theo dõi × ba kích thước × hai theme.
- Admin production build và 4 domain test đạt; Chrome/demo emulator đạt 21 SDK
  check + 21 UI check, gồm mở preview, nút bị khóa trước xác nhận và bật banner
  sau khi đủ điều kiện cơ học. Ảnh trong test admin là fixture món ăn local.
- Không dùng kết quả test kỹ thuật để khẳng định thiết kế đã đạt cảm nhận cao cấp.
  Ảnh đối chiếu là dữ liệu fixture; nội dung production có thể khác.

Ảnh trước: `build/ui_ux/home-refinement-before`.
Ảnh sau: `build/ui_ux/home-refine-light` và `build/ui_ux/home-refine-dark`.
Log: `node_modules/.cache/report-release/home-refine-*.log`.
Preview admin: `../admin_bep_xinh/node_modules/.cache/admin-smoke/banner-review.png`.

## Phát hành

Ngày 16/11/2026, chỉ deploy Hosting lên project `bepxinh-b0be7`:

- App web version `59a47e69be540662`, lúc 23:32:14 UTC+7.
- Admin version `7a8520c8dd9cc645`, lúc 23:33:18 UTC+7.
- HTML/bootstrap/main.dart.js của app và HTML/JS/CSS admin live đã đối chiếu hash
  với artifact local. Không deploy Rules/index hay phát hành APK/IPA.
- Nếu đang chạy localhost bằng Flutter, cần hot reload/hot restart để nạp source;
  bản web Hosting tải lại bằng Ctrl+F5.
