# Home và Tủ lạnh

## Luồng dữ liệu

Widget chỉ nhận dữ liệu/callback; Cubit sở hữu trạng thái và gọi `HomeService` hoặc
`FridgeService`. Các interface được inject ở `AppBepXinh`. JSON được kiểm tra khi
parse: id không trùng, trường bắt buộc đúng kiểu, thời gian/đánh giá hợp lệ và
nguyên liệu tham chiếu phải tồn tại. Collection từ response không thể sửa trực tiếp.

Danh mục nguyên liệu nằm trong `features/ingredients`, dùng chung với Đăng món
qua `IngredientCatalogService`. `FridgeService` ghép response tồn kho/gợi ý với
danh mục này; không sở hữu một bản danh mục riêng. Tìm nguyên liệu hỗ trợ tên gọi
khác và không dấu. ID tồn kho và ID nguyên liệu công thức cùng một namespace.

`MockApiClient` mô phỏng độ trễ, đọc fixture trong `assets/mock/`. Mock service giữ
các thay đổi trong bộ nhớ của phiên chạy. Hiện chưa có HTTP, xác thực hay lưu bền
vững. Khi nối backend, thay implementation ở DI, giữ nguyên interface và các test
hợp đồng; không đưa request hoặc fixture trở lại widget/state.

## Request và tính nhất quán

- Request tải trùng dùng chung Future: mọi caller đều chờ cùng một kết quả.
- Tủ lạnh ghi theo thứ tự. Refresh chờ write đã nhận; thao tác trong lúc refresh
  được thực hiện sau khi có response. Write lỗi khôi phục snapshot đã lưu gần nhất.
- Home chỉ bảo vệ favorite vừa ghi trong request refresh đang chạy. Một request
  mới vẫn lấy server làm nguồn chính, không giữ override cũ vô thời hạn.
- Service phát `FridgeSummary` sau xác nhận lưu. Home cập nhật card ngay cả khi tab
  còn nằm trong indexed stack. Response Home cũ không ghi đè summary mới hơn.
- Cubit gửi lỗi gốc và stack qua `addError` cho `BlocObserver`; UI hiển thị thông
  báo phù hợp. Tích hợp hệ thống giám sát lỗi tại observer của app khi triển khai.

## Ownership và UI

DI hủy service stream khi app dispose; HomeCubit hủy subscription của mình. Future
đang chạy không giữ màn hình sống và không emit vào Cubit đã đóng. Widget dùng
selector theo phần dữ liệu để thay favorite không dựng lại toàn bộ feed.

`HomeBannerSlide` chỉ hiển thị. `HomeBanner` là StatefulWidget vì sở hữu controller,
notifier và lifecycle observer; `HomeBannerSliver` cung cấp trạng thái viewport.
Autoplay dừng khi tab/route bị ẩn, app rời foreground, banner ngoài viewport,
pointer đang nhấn hoặc hệ thống yêu cầu giảm chuyển động. App bị pause được dừng
Timer trực tiếp vì lúc đó có thể không còn frame để rebuild.

Ảnh được giới hạn kích thước giải mã và có fallback. `ProductGrid` dùng chung cho
mobile/tablet; card và carousel dành thêm chiều cao khi cỡ chữ hệ thống tăng.
Typography không nhân thêm hệ số màn hình lên cỡ chữ nội dung card.

Các phần UI dùng chung của Home đã được chuyển lên core: `AppSearchBar`,
`AppSectionHeader`, `AppTextAction` và khung `AppCard` của ProductCard. Home và
Tủ lạnh cùng dùng các component này; Đăng món dùng chung header/action/search
và `AppTextField` theo theme. Chi tiết ownership nằm trong `shared_ui.md`.

Home và Tủ lạnh có skeleton riêng theo bố cục (`HomeSkeleton`, `FridgeSkeleton`).
`AppLoadState` nhận skeleton cho lần tải đầu; refresh vẫn giữ nội dung hiện có.
`AppSkeleton` tôn trọng giảm chuyển động, TickerMode và vòng đời ứng dụng. Tủ lạnh
dùng tiêu đề thường, card tồn kho viền mảnh và danh sách nguyên liệu không có
khung bao ngoài. Chip giữ kích thước gọn, món chưa có ảnh không tạo ảnh giả hay
icon lớn thay thế.

## Kiểm tra

Chạy `flutter analyze --no-pub` và `flutter test --no-pub`. Test bao phủ tải/lỗi/
thử lại, request trùng, thứ tự ghi, rollback, response cũ, đồng bộ hai màn, hủy
subscription, JSON lỗi, autoplay, cập nhật danh sách carousel và màn hẹp/chữ lớn.
