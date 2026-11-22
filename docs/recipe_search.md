# Tìm kiếm món ăn

Thanh tìm kiếm Home, sáu nút danh mục và các nút “Xem tất cả” mở chung màn
`/recipes/search`. Query `q` và `filter` được mã hóa trong URL khi mở trang;
route factory nằm trong `features/recipe_search/routes`.

Sáu lựa chọn gồm Tất cả, Món mới, Eat Clean, Nấu nhanh, Món nước và Món chay.
Món mới sắp xếp theo `publishedAt` do hệ thống cung cấp, mới nhất trước;
công thức cũ chưa có ngày đứng sau. Bốn danh mục còn lại dùng
`RecipeCategory` trong dữ liệu công thức, không suy đoán từ tên món, thời gian
hay lượng calo. Tác giả có thể chọn nhiều danh mục trong bước Thông tin của Đăng món.

`RecipeSearchCubit` quản lý từ khóa, bộ lọc, debounce 300 ms, kết quả,
lỗi/thử lại và yêu thích. Thay từ khóa, đổi bộ lọc, xóa tìm kiếm hoặc đóng trang
đều làm response cũ hết hiệu lực. Cubit không chứa router hay BuildContext.
Widget nhập liệu chỉ giữ TextEditingController; các widget lọc/kết quả là Stateless.

`RecipeSearchService` tách riêng để thay bằng API. Adapter mock đọc các công thức
đã công bố trong `recipe_details.json`, cùng schema với Chi tiết/Nấu món.
Tìm kiếm không phân biệt dấu hoặc chữ hoa, khớp tất cả từ khóa trong tên món,
mô tả, tên nguyên liệu và tên gọi khác của danh mục nguyên liệu.
Từ khóa và danh mục kết hợp theo điều kiện đồng thời.

Yêu thích dùng chung `RecipeFavoritesService` với Home, Chi tiết và Hồ sơ.
Mở chi tiết bằng push và quay lại giữ nguyên từ khóa, bộ lọc, kết quả và vị trí
cuộn. Nút quay lại từ đường dẫn trực tiếp đưa về Home.
Form gửi duyệt vẫn là dữ liệu chờ duyệt trong phiên mock; chưa xuất hiện trong
tìm kiếm công khai trước khi được công bố.

Giao diện dùng AppSearchBar, AppAppBar, AppLoadState và ProductGrid sẵn có.
Chiều rộng trang và số cột dùng AppLayout. Danh mục Home xếp 3 cột trên màn hẹp,
6 cột khi đủ rộng. Kiểm thử bao gồm màn 320–1280 px, chữ 150%, bàn phím,
điều hướng Home → Tìm kiếm → Chi tiết → quay lại và lưu/khôi phục danh mục form.


## UI/UX hiện tại

Ô nhập, bộ lọc và kết quả dùng một vùng cuộn để bàn phím tablet ngang không
ép nội dung. Khi chọn danh mục khác Tất cả, nút Bỏ lọc đưa về Tất cả và giữ
nguyên từ khóa. UI dùng theme toàn app; xem feature_presentation.md.
