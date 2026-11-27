# Tìm kiếm món ăn

Thanh tìm kiếm Home, sáu nút danh mục và các nút “Xem tất cả” mở chung màn
`/recipes/search`. Query `q`, `filter`, `minutes`, `difficulty` và `exclude`
được mã hóa trong URL khi mở trang;
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
đã công bố từ `PublishedRecipeSource` ghép với fixture `recipe_details.json`,
cùng schema với Chi tiết/Nấu món. Nguồn Firestore giữ giới hạn hiện có 100 bản ghi;
đợt nâng cấp này không đổi nguồn dữ liệu hoặc thêm phân trang.
Tìm kiếm không phân biệt dấu hoặc chữ hoa, khớp tất cả từ khóa trong tên món,
mô tả, tên nguyên liệu và tên gọi khác của danh mục nguyên liệu.
Từ khóa và danh mục kết hợp theo điều kiện đồng thời.

Yêu thích dùng chung `RecipeFavoritesService` với Home, Chi tiết và Hồ sơ.
Mở chi tiết bằng push và quay lại giữ nguyên từ khóa, bộ lọc, kết quả và vị trí
cuộn. Nút quay lại từ đường dẫn trực tiếp đưa về Home.
Bài chờ duyệt chưa xuất hiện trong nguồn tìm kiếm công khai trước khi được công bố.

Giao diện dùng AppSearchBar, AppAppBar, AppLoadState và ProductGrid sẵn có.
Chiều rộng trang và số cột dùng AppLayout. Danh mục dùng chip chữ không viền.
Kiểm thử bao gồm màn 320–1280 px, chữ 150%, bàn phím,
điều hướng Home → Tìm kiếm → Chi tiết → quay lại và lưu/khôi phục danh mục form.


## UI/UX hiện tại

Ô nhập, bộ lọc và kết quả dùng một vùng cuộn để bàn phím tablet ngang không
ép nội dung. Nút Bỏ lọc xóa mọi bộ lọc, giữ nguyên từ khóa. Xóa từ khóa giữ các bộ
lọc. Home và tìm kiếm dùng `RecipeDiscoveryTheme`: icon đơn sắc theo light/dark,
chip không viền và nền trung tính khi chọn; màu thương hiệu dành cho thao tác chính.
Bỏ đoạn giới thiệu dư ở đầu trang. Card lưới không viền/shadow trang trí.

## Bộ lọc nâng cao — 26/11/2026

- `minutes`: tổng thời gian tối đa gồm chuẩn bị và nấu, nhận số nguyên 1–960.
  Sheet có lựa chọn 15/30/45/60/90/120 phút hoặc bất kỳ.
- `difficulty`: giá trị enum `RecipeDifficulty`; giá trị lạ được bỏ qua.
- `exclude`: tên nguyên liệu phân cách bằng dấu phẩy. So khớp từ/cụm từ không
  phân biệt dấu/chữ hoa trong tên nguyên liệu và alias catalog. Đây là lọc theo
  dữ liệu công thức, không xác nhận an toàn dị ứng.

Các điều kiện kết hợp đồng thời với từ khóa và danh mục. `RecipeSearchFilterCubit`
giữ bản nháp: đóng không áp dụng, Đặt lại chỉ sửa nháp, Áp dụng mới tải kết quả.
“Trong 30 phút” trên Home mở bộ lọc tổng thời gian, không đồng nhất với danh mục
Nấu nhanh. Hai lối tắt còn lại mở Tủ lạnh và bảng tin Đang theo dõi hiện có.

## Lịch sử trên thiết bị

`SearchHistoryRepository` lưu tối đa 8 từ khóa, gộp khoảng trắng và trùng dấu/chữ hoa.
Chỉ lưu khi gửi tìm kiếm, chọn lịch sử hoặc mở một kết quả, không lưu từng lần gõ.
`LocalSearchHistoryRepository` dùng SharedPreferences, namespace riêng theo UID băm
và riêng cho khách. Không đồng bộ Firebase. Nút Xóa lịch sử xóa lịch sử hiện tại.
Khi chưa nhập hiện tối đa 8 mục; khi nhập gợi ý tối đa 3 mục lịch sử khớp và khác
từ khóa hiện tại. Chọn mục đồng bộ ô nhập/kết quả. Ghi/xóa xếp hàng, kết quả đọc cũ
không khôi phục lịch sử đã xóa.

Không đổi schema hoặc Firestore Rules. Kiểm thử mới bao gồm điều kiện lọc kết hợp,
URL, hủy/áp dụng, lưu/xóa/cô lập lịch sử và sheet trên màn ngang có bàn phím.
Ảnh fixture ở `build/ui_ux/discovery-home-light`, `discovery-search-light`,
`discovery-filters-light`; chưa xác minh trực quan trên thiết bị thật.
