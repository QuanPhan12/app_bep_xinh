# Chi tiết món ăn

`/recipe/:id` tải công thức theo ID qua `RecipeDetailService`. Dữ liệu mock nằm
trong `assets/mock/recipe_details.json`, bao phủ món và banner của Home, cùng các
món trong Tủ lạnh. Alias trong fixture trỏ về cùng ID công thức chuẩn. ID không
tồn tại hiển thị thông báo riêng, không dùng một món mặc định thay thế.

`RecipeDetailCubit` quản lý tải/lỗi, khẩu phần, đánh dấu nguyên liệu, tab đang xem,
lưu món và bước nấu hiện tại. Cubit không giữ router/BuildContext. Request tải
trùng dùng chung Future; kết quả sau khi đóng màn hình không emit vào Cubit.

UI ghép các component sẵn có: `AppAppBar`, `AppCard`, `AppSectionHeader`,
`AppTextAction`, `AppButton`, `AppActionBar`, `AppLoadState`, `AppSkeleton` và các block skeleton.
`AppServingSelector` được chuyển từ Đăng món lên global để hai màn dùng cùng
cách chọn khẩu phần. Không tạo bộ card/header/nút riêng cho Chi tiết món.

Lượng nguyên liệu được tính từ lượng gốc và số khẩu phần, dùng chung formatter
với Đăng món. Không đổi lượng gốc hoặc quy đổi tự động giữa gram/ml/thìa. Các ô
nguyên liệu có sẵn được đánh dấu từ tồn kho khi tải; người dùng có thể chỉnh dấu
trong màn chi tiết. Những dấu này không tự ghi lại tồn kho hoặc giỏ đi chợ.

`RecipeFavoritesService` là nguồn lưu món dùng chung cho Home và Chi tiết. Mock
ghi theo thứ tự, phát thay đổi sau xác nhận; Home đang mở cập nhật mà không cần
tải lại. Trạng thái giữ trong phiên chạy. DI sở hữu service/stream; Cubit hủy
subscription khi đóng.

Nút Bắt đầu nấu chuyển sang từng bước, hỗ trợ quay lại bước trước, xem nguyên
liệu và hoàn tất. Đây là hướng dẫn từng bước, không có xử lý giọng nói/hẹn giờ.
Các nút chia sẻ/theo dõi chưa có dịch vụ tương ứng không được đưa vào giao diện.

Test bao phủ ID/alias, dữ liệu lỗi, tải/thử lại/đóng Cubit, số lượng và khẩu phần,
yêu thích giữa hai màn, hướng dẫn nấu, điều hướng từ card Home/Tủ lạnh, layout
320px/tablet và cỡ chữ lớn.
