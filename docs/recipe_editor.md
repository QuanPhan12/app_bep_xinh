# Đăng món

Màn `/recipes/new` được mở từ nút `+` của thanh điều hướng mobile/tablet.
`AppAppBar` nằm trong `core/widgets`, dùng lại cho các màn form/chi tiết. Màn Đăng
món chỉ có luồng tác giả, không chứa giao diện quản trị hay tab duyệt bài.

`RecipeEditorCubit` sở hữu dữ liệu form, validation, thao tác lưu/gửi và kiểm tra
thay đổi chưa lưu. Widget được tách thành ảnh bìa, thông tin món, nguyên liệu,
các bước và thanh hành động. Các dòng nguyên liệu/bước dùng id ổn định để xóa
một dòng không làm chuyển nội dung controller sang dòng khác.

Nguyên liệu được thêm/sửa qua bottom sheet riêng. `IngredientPickerCubit` quản lý
tìm kiếm qua service (debounce, bỏ response cũ, lỗi/thử lại), chọn danh mục,
số lượng thập phân, đơn vị, ghi chú và lựa chọn "Vừa đủ". Hủy sheet không thay
đổi form; xác nhận mới cập nhật một dòng và kiểm tra trùng. Có thể xóa hết dòng,
nhưng gửi duyệt yêu cầu ít nhất một nguyên liệu.

`features/ingredients` sở hữu danh mục dùng chung cho Tủ lạnh và Đăng món, inject
qua `IngredientCatalogService`. Fixture `assets/mock/ingredients.json` chứa ID,
tên gọi khác và đơn vị hợp lệ; `fridge.json` chỉ còn tồn kho và gợi ý món.
Mock service gộp request tải danh mục và cache trong phiên. Tìm kiếm hỗ trợ
không dấu và alias (đậu phụ/đậu hũ, thịt lợn/thịt heo). Thêm tên trùng chính xác
với alias sẽ chọn nguyên liệu chuẩn thay vì tạo một nguyên liệu tự nhập.

`RecipeIngredientDraft.id` là ID dòng; `ingredientId` là ID danh mục, nullable
khi người dùng tự nhập nguyên liệu chưa có. `amount` là số, `unitId` là ID đơn
vị; tên và nhãn đơn vị chỉ là snapshot hiển thị. `toTaste` bỏ amount/unit khỏi
payload. Ghi chú không nằm chung trong lượng dùng. Service gửi duyệt đối chiếu
ID và đơn vị với danh mục. Chưa tự quy đổi giữa thìa, gram, ml hoặc tính dinh
dưỡng; các phép tính đó cần dữ liệu quy đổi riêng theo nguyên liệu.

`RecipeEditorService` được inject ở app. Implementation hiện tại mô phỏng độ
trễ và lưu bản nháp trong phiên chạy; chưa gửi bài lên backend thật và chưa lưu
qua lần khởi động app. Lưu nháp chấp nhận form chưa hoàn tất; gửi duyệt kiểm tra
tên, ảnh, thời gian, khẩu phần, nguyên liệu và bước nấu. Gửi thành công đóng form.
Snapshot lưu nháp không đánh dấu những thay đổi phát sinh trong request là đã lưu.

`RecipeCoverPicker` tách khỏi Cubit để kiểm thử và thay implementation. Adapter
`image_picker` chọn ảnh thư viện, giới hạn dung lượng, kiểm tra ảnh bằng codec có
kích thước giải mã nhỏ và phục hồi kết quả picker bị gián đoạn trên Android.
Ảnh lưu bằng bytes thay vì dùng đường dẫn tạm xuyên phiên. iOS đã khai báo mục
đích truy cập thư viện ảnh; không yêu cầu camera/microphone vì màn này chỉ chọn ảnh.

Các test bao phủ validation, gõ/xóa/nhập lại, thêm/xóa dòng, chọn/hủy/lỗi ảnh,
lưu/gửi bất đồng bộ, quay lại khi chưa lưu, khôi phục nháp, định tuyến nút `+`
và layout màn hẹp/chữ lớn.

Form dùng nền trắng, tiêu đề nhóm và đường phân cách mảnh. Ảnh bìa đặt ở đầu,
nguyên liệu hiển thị dạng dòng có thể chạm để sửa. Không bọc mỗi phần trong card
hay thêm icon/nền màu trang trí. Màu cam ưu tiên cho hành động và lựa chọn hiện tại.

Tiêu đề/action dùng `AppSectionHeader` và `AppTextAction` tách từ Home; tìm nguyên
liệu dùng cùng `AppSearchBar` với Home/Tủ lạnh. `AppTextField` và dropdown nhận
style từ `AppTheme`. Xem `shared_ui.md` cho danh sách component và nơi sử dụng.

Tải form dùng `RecipeEditorSkeleton`; tải/tìm nguyên liệu dùng `SkeletonListRows`.
`AppSkeleton` có một ticker cho cả bố cục, dừng khi route bị ẩn, app rời foreground
hoặc người dùng bật giảm chuyển động. Skeleton chặn thao tác và có nhãn đọc màn
hình "Đang tải". Loading khi lưu/gửi vẫn thuộc nút hành động.
