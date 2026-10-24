# UI dùng chung

Home là nguồn style. Các thành phần đã được chuyển sang `lib/core/widgets` và
Home cũng dùng trực tiếp chúng; không giữ một bản trang trí gần giống ở feature.

| Component global | Nguồn trước khi chuyển | Đang dùng |
| --- | --- | --- |
| `AppSearchBar` | `HomeSearchBar` | Home, Tủ lạnh, tìm nguyên liệu khi đăng món |
| `AppSectionHeader` | Phần tiêu đề của `HomeLabelAction` | Home, Tủ lạnh, các nhóm form |
| `AppTextAction` | Hành động cạnh tiêu đề Home | Xem tất cả, thêm/xóa/đổi nguyên liệu, thêm bước |
| `AppCard` | Khung `ProductCard` của Home | ProductCard, tồn kho, món gợi ý và skeleton |
| `AppTextField` | Ô nhập của form Đăng món | Tên món, thời gian, lượng dùng, ghi chú, bước nấu |

`AppCard` giữ radius responsive, border và shadow từ ProductCard. `AppSearchBar`
giữ kích thước, icon và typography của thanh tìm kiếm Home, hỗ trợ cả mở trang và
nhập trực tiếp. `AppTextField` và dropdown dùng `inputDecorationTheme` sẵn có
trong `AppTheme`, không tự định nghĩa lại màu nền, viền, padding hoặc bo góc.

Feature sở hữu dữ liệu, callback và bố cục nghiệp vụ. Ví dụ `RecipeEditorSection`
chỉ ngăn nhóm form bằng divider và ghép `AppSectionHeader`; không có style tiêu
đề riêng. Cubit/service không phụ thuộc các component UI.

Đã bỏ `HomeSearchBar`, `HomeLabelAction`, `RecipeEditorField`,
`RecipeEditorTextAction` và khung `AppSurfaceCard` cũ để tránh hai nguồn style.
