# Cá nhân và Cài đặt

`ProfileScreen` nằm trong tab Cá nhân; `/settings` mở phía trên shell như Đăng
món và Chi tiết món. Quay lại giữ nguyên tab Công thức/Đã lưu và vị trí cuộn.
Route factory thuộc từng feature; Cubit không phụ thuộc router hoặc BuildContext.

Tab Cá nhân không có AppBar, cùng bố cục các tab Home/Tủ lạnh. Nút Cài đặt nằm
trong hàng thông tin hồ sơ. Trang Cài đặt dùng `AppAppBar` để quay lại.
Hồ sơ dùng `AppButton`, `AppTextField`, `AppSectionHeader`,
`ProductGrid`/`ProductCard` của Home, skeleton và `AppMessenger` có sẵn. Không
tạo bản sao của thẻ món hoặc giao diện thông báo. Avatar dùng chữ đầu tên khi
chưa có ảnh đại diện. Không thêm nút chia sẻ, huy hiệu hay chuỗi ngày chưa có
chức năng tương ứng.

`ProfileService` được inject từ `app.dart`. Mock đọc `assets/mock/profile.json`
và danh mục `recipe_details.json`, mô phỏng request/write bằng `MockApiClient`.
Các thay đổi tên, giới thiệu và tùy chọn hiển thị được lưu trong phiên; chưa có
backend hoặc lưu bền sau khi khởi động lại. Thay implementation service khi nối API.

`ProfileCubit` nhận thay đổi tài khoản qua stream và món đã lưu từ
`RecipeFavoritesService` dùng chung với Home/Chi tiết món. Giữ thay đổi phát sinh
trong lúc tải để response cũ không ghi đè chúng. Tải lại không xóa nội dung đang
hiển thị; lỗi refresh hiển thị bằng messenger. Mỗi món chỉ có một lượt lưu đang
chạy; lỗi ghi giữ dữ liệu đã xác nhận.

`ProfileEditCubit` giữ dữ liệu form, validation và trạng thái lưu. `SettingsCubit`
quản lý tải/lưu tùy chọn hiển thị giới thiệu. Service tuần tự hóa các lượt ghi để
chỉnh sửa hồ sơ và tùy chọn không ghi đè nhau. Nút Cài đặt, chỉnh sửa hồ sơ, mở
món, bỏ lưu, thông tin ứng dụng và xác nhận đăng xuất đều có luồng hoạt động.
Đăng xuất hiện dùng điều hướng về Login theo cơ chế auth hiện có của app.

Kiểm thử bao gồm lỗi/thử lại, tải trùng, response muộn, đồng bộ qua stream, lưu
trùng, validation xóa/nhập lại, navigation thực và giao diện 320/800px với chữ
lớn, bàn phím. Thanh điều hướng tablet dùng `Center(heightFactor: 1)` để không
chiếm hết chiều cao body.

## Hồ sơ công khai

`/users/:userId` mở ngoài shell từ thông tin tác giả trong Chi tiết món. Route
factory nằm trong `profile_routes.dart`. ID được encode khi tạo đường dẫn;
không suy ra ID từ tên hiển thị và không chuyển hồ sơ không tồn tại về tài khoản
đang đăng nhập. Tên tác giả dạng chuỗi cũ vẫn hiển thị nhưng không có liên kết.

`RecipeAuthor` là định danh công khai dùng trong công thức: ID, tên, handle và
avatar tùy chọn. Fixture `public_profiles.json` chứa thông tin giới thiệu công
khai. `MockProfileService` triển khai hai contract `ProfileService` và
`PublicProfileService`, được DI quản lý như một instance để đồng bộ thay đổi
tên/giới thiệu. Dữ liệu công thức công khai lọc theo `author.id` của danh mục;
không lấy danh sách món đã lưu hay thông tin chỉnh sửa của người khác.

`PublicProfileCubit` sở hữu tải/lỗi/không tìm thấy, refresh và lưu món của người
đang xem. Nó kiểm tra đúng ID response, bỏ response sau khi đóng, gộp request tải
trùng, giữ thay đổi qua stream trong lúc tải. Giới thiệu bị ẩn không xuất hiện
trong public projection. Event thay đổi tài khoản chỉ áp dụng cho ID đang mở.

Giao diện dùng `ProfileIdentityInfo`, `AppAvatar`, `ProductGrid`/`ProductCard`,
`AppCard`, `AppAppBar` và skeleton chung. Màn công khai chỉ có thông tin công khai
và công thức đã chia sẻ; không có Sửa hồ sơ, Cài đặt hoặc tab Đã lưu. Danh sách
trống và hồ sơ không tồn tại có trạng thái riêng. Chạm món mở chi tiết; quay lại
qua hồ sơ giữ nguyên khẩu phần và nguyên liệu đã đánh dấu của chi tiết ban đầu.
Không thêm chức năng theo dõi/nhắn tin khi chưa có service.

Summary món từ `recipe_details` dùng `RecipeItem.fromRecipeJson` để đọc ảnh bìa
theo schema mới và đổi ID độ khó thành nhãn hiển thị, dùng chung cho hồ sơ riêng
và hồ sơ công khai. Món chưa có ảnh dùng placeholder của `ProductCard`.

Các test bổ sung bao phủ định danh tác giả, lọc đúng người, tùy chọn giới thiệu,
favorite dùng chung, route có ID encode, response muộn, lỗi/thử lại, trạng thái
trống và layout 320/800/1024/1280px với chữ 150%.
