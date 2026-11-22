> Cập nhật 17/11/2026: theme/component hiện lấy từ Sollume.
> Xem [phạm vi port và adapter](SOLLUME_UI_PORT.md). Mô tả style Home bên dưới là lịch sử
> cấu trúc Bếp Xinh; màu sắc, input, button, card và tab hiện lấy từ theme mới.

# UI dùng chung

Home là nguồn style. Các thành phần đã được chuyển sang `lib/core/widgets` và
Home cũng dùng trực tiếp chúng; không giữ một bản trang trí gần giống ở feature.

| Component global | Nguồn trước khi chuyển | Đang dùng |
| --- | --- | --- |
| `AppSearchBar` | `HomeSearchBar` | Home, Tủ lạnh, tìm nguyên liệu khi đăng món |
| `AppSectionHeader` | Phần tiêu đề của `HomeLabelAction` | Home, Tủ lạnh, các nhóm form |
| `AppTextAction` | Hành động cạnh tiêu đề Home | Xem tất cả, thêm/xóa/đổi nguyên liệu, thêm bước |
| `AppCard` | Khung `ProductCard` của Home | ProductCard, tồn kho, món gợi ý, Cài đặt và skeleton |
| `AppAvatar` | Avatar chữ đầu tên của Hồ sơ | Hồ sơ riêng, hồ sơ công khai, thông tin tác giả món |
| `AppTextField` | Ô nhập của form Đăng món | Tên món, thời gian, lượng dùng, ghi chú, bước nấu, chỉnh hồ sơ |
| `AppServingSelector` | Ô khẩu phần của Đăng món | Đăng món, Chi tiết món |
| `AppActionBar` | Khung thanh nút cuối trang Đăng món | Đăng món, Chi tiết món |
| `AppMessenger` | Thông báo custom có sẵn | Home, Tủ lạnh, Đăng món, Chi tiết món, Cá nhân, Cài đặt |
| `ProductGrid` / `ProductCard` | Danh sách món của Home | Home, Công thức của tôi, Đã lưu |
| `AppAdaptiveColumns` | Quy tắc bố cục theo chiều rộng thực tế | Tủ lạnh, Hồ sơ, Giỏ đi chợ, Chi tiết món, Đăng món |

`features/recipes/widgets` sở hữu các block đọc nội dung công thức:
`RecipeContentOverview`, `RecipeStepContent`, `RecipeImageView`, `RecipeNotes`.
Đăng món và Chi tiết món dùng trực tiếp các block này; không sao chép cách hiển
thị tên bước, ảnh, thời gian, mẹo hoặc thông số món sang từng feature.

`AppCard` không viền, dùng bo góc 16px và không shadow; `CardTheme` dùng cùng
`AppUi.cardRadius`. Các khung nội dung và ghi chú dùng cùng quy tắc. `AppSearchBar`
giữ kích thước, icon và typography của thanh tìm kiếm Home, hỗ trợ cả mở trang và
nhập trực tiếp. `AppTextField` và dropdown dùng `inputDecorationTheme` sẵn có
trong `AppTheme`, không tự định nghĩa lại màu nền, viền, padding hoặc bo góc.

Màn Tìm kiếm món dùng lại AppSearchBar với controller, nút xóa và callback
submit; chiều cao tối thiểu cho phép chữ lớn. Kết quả dùng ProductGrid/ProductCard
và cùng nguồn yêu thích với Home/Chi tiết/Hồ sơ.

Feature sở hữu dữ liệu, callback và bố cục nghiệp vụ. Ví dụ `RecipeEditorSection`
ghép `AppCard` và `AppSectionHeader`; không có style tiêu
đề riêng. Cubit/service không phụ thuộc các component UI.

Thông báo tạm thời dùng `AppMessenger`, không dùng `SnackBar` riêng ở feature.
Cubit chỉ phát nội dung và `AppNotificationType` (enum Dart thuần trong
`core/models`); screen listener gọi messenger. Lỗi tải trang ban đầu vẫn hiển thị
qua `AppLoadState` để người dùng có thể thử lại.

Đã bỏ `HomeSearchBar`, `HomeLabelAction`, `RecipeEditorField`,
`RecipeEditorTextAction` và khung `AppSurfaceCard` cũ để tránh hai nguồn style.

Quy tắc responsive dùng `AppLayout` trong `core/utils/app_layout.dart`. Xem
[responsive.md](responsive.md) cho chiều rộng trang/form/sheet, bố cục tablet và kiểm thử.

Toàn app dùng AppTheme và token AppColors/AppUi. AppFeatureTheme chỉ còn là marker
tương thích, không thay palette hoặc style component. AppButton dùng nền đặc, giữ
nhãn khi loading và cho chữ lớn xuống dòng. Xem [feature_presentation.md](feature_presentation.md)
và [UI_UX_IMPLEMENTATION.md](UI_UX_IMPLEMENTATION.md).

Nút quay lại trên AppAppBar/SliverAppBar dùng đúng control Sollume:
`IconButton` + `PhosphorIconsBold.caretLeft`, không đặt size 18px hay bọc hiệu ứng
AppTap riêng. Kích thước, vùng bấm, feedback, màu disabled theo IconButtonTheme;
callback vẫn qua guard Bếp Xinh và giữ trạng thái khóa khi đang lưu.
