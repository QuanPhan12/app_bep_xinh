# Chi tiết món ăn

`/recipe/:id` tải công thức theo ID qua `RecipeDetailService`. Dữ liệu mock nằm
trong `assets/mock/recipe_details.json`, bao phủ món và banner của Home, cùng các
món trong Tủ lạnh. Alias trong fixture trỏ về cùng ID công thức chuẩn. ID không
tồn tại hiển thị thông báo riêng, không dùng một món mặc định thay thế.

Nội dung công thức dùng chung `RecipeContent` trong `features/recipes/models`.
`RecipeDetail` chỉ ghép nội dung đó với ID, tác giả, đánh giá và thông tin hệ thống.
Tác giả dùng `RecipeAuthor` gồm ID, tên, handle và ảnh đại diện tùy chọn.
`RecipeAuthorInfo` trong tổng quan món mở `/users/:userId` khi có ID. Điều hướng
dùng push để quay lại vẫn giữ state của chi tiết; callback không chờ route đóng
để tránh khóa các thao tác trên màn hồ sơ. Hồ sơ công khai thuộc feature Profile.
`RecipeDraft.toRecipeContent()` chuyển dữ liệu form đã hoàn tất sang cùng schema:
thời gian là số, thời gian bước tùy chọn là `null`, bữa ăn dùng enum ID, nguyên liệu
liên kết với nhóm qua `groupId`, thứ tự nhóm/bước và ID dòng giữ nguyên.

Schema bao gồm mô tả, ảnh bìa, thời gian chuẩn bị/nấu, khẩu phần, độ khó, dịp dùng
món, nhóm nguyên liệu, ghi chú bảo quản; mỗi bước có tên, nội dung, thời gian,
mẹo và ảnh tùy chọn. `RecipeImage` hỗ trợ asset mock và bytes bất biến của ảnh
được chọn từ form. Reader JSON dùng chung kiểm tra nhóm/ID trùng, đơn vị, giới hạn
field và nguồn ảnh. Công thức cũ thiếu nhóm được đưa vào nhóm `main`; `image` và
nhãn độ khó tiếng Việt cũ vẫn đọc được. Fixture đã chuyển sang schema mới.

`RecipeDetailCubit` quản lý tải/lỗi, khẩu phần, đánh dấu nguyên liệu, tab đang xem,
lưu món và bước nấu hiện tại. Cubit không giữ router/BuildContext. Request tải
trùng dùng chung Future; kết quả sau khi đóng màn hình không emit vào Cubit.

UI ghép các component sẵn có: `AppAppBar`, `AppCard`, `AppSectionHeader`,
`AppTextAction`, `AppButton`, `AppActionBar`, `AppLoadState`, `AppSkeleton` và các block skeleton.
`AppServingSelector` được chuyển từ Đăng món lên global để hai màn dùng cùng
cách chọn khẩu phần. Không tạo bộ card/header/nút riêng cho Chi tiết món.
`RecipeContentOverview`, `RecipeStepContent`, `RecipeImageView` dùng chung cho
xem trước bài đăng, chi tiết và chế độ nấu; cả ảnh asset lẫn ảnh đã chọn được hiển
thị qua cùng component. Style lấy từ Home; tablet giữ bố cục hai cột đã có.

Lượng nguyên liệu được tính từ lượng gốc và số khẩu phần, dùng chung formatter
với Đăng món. Không đổi lượng gốc hoặc quy đổi tự động giữa gram/ml/thìa. Các ô
nguyên liệu có sẵn được đánh dấu từ tồn kho khi tải; người dùng có thể chỉnh dấu
trong màn chi tiết. Những dấu này không tự ghi lại tồn kho hoặc giỏ đi chợ.
Các nhóm hiển thị theo thứ tự tác giả nhập. Chọn tất cả áp dụng toàn bộ nhóm;
đổi khẩu phần chỉ tính lượng hiển thị, giữ nguyên lượng gốc và mục "Vừa đủ".

`RecipeFavoritesService` là nguồn lưu món dùng chung cho Home và Chi tiết. Mock
ghi theo thứ tự, phát thay đổi sau xác nhận; Home đang mở cập nhật mà không cần
tải lại. Trạng thái giữ trong phiên chạy. DI sở hữu service/stream; Cubit hủy
subscription khi đóng.

Nút Bắt đầu nấu chuyển sang từng bước với đầy đủ tên, ảnh, thời gian, nội dung
và mẹo. Danh sách bước cho phép chuyển nhanh; có thể đổi sang tab nguyên liệu mà
không mất vị trí hoặc khẩu phần đã chọn. Back ở chế độ nấu tạm dừng và về chi tiết,
Back ở chi tiết mới rời route. Nút Tiếp tục nấu mở đúng bước đã tạm dừng. Hoàn tất
xóa vị trí tạm dừng và cho phép Nấu lại từ bước đầu. Trạng thái này giữ trong phiên
mở route, chưa lưu sau khi đóng app. Ghi chú bảo quản xuất hiện cả ở chi tiết và nấu.
Đây là hướng dẫn từng bước, không có xử lý giọng nói/hẹn giờ.
Các nút chia sẻ/theo dõi chưa có dịch vụ tương ứng không được đưa vào giao diện.

Mock gửi duyệt giữ `lastSubmittedContent` là snapshot chờ duyệt theo schema chung,
không tự đưa vào danh sách công thức công khai. Backend và quy trình duyệt thật
vẫn chưa được nối. Test round-trip xác nhận payload từ form đọc lại thành chi tiết
không mất nhóm, thứ tự, ảnh hoặc ghi chú.

Test bao phủ ID/alias, dữ liệu lỗi, tải/thử lại/đóng Cubit, số lượng và khẩu phần,
yêu thích giữa hai màn, hướng dẫn nấu, điều hướng từ card Home/Tủ lạnh, layout
320px/tablet và cỡ chữ lớn.
