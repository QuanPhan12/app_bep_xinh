# Port UI Sollume sang Bếp Xinh

Ngày đối chiếu source: 17/11/2026. Nguồn: `D:/Sollume-Project/sollume_app`.
Màu thương hiệu giữ cam Bếp Xinh `#E8590C`. Bộ component, typography, spacing và
bề mặt light/dark dùng Sollume. Bản port đầu đã hiểu sai và mang cả teal sang;
đã sửa lại theo yêu cầu giữ màu thương hiệu.

## Phần lấy từ source

### Chuẩn menu Bếp của tôi và Cài đặt — 26/11/2026

- Dùng trực tiếp `AppMenuTile` và `AppMenuSection` của bản port Sollume:
  nhóm phẳng, không nền bo góc hoặc divider; icon Phosphor Bold, chiều cao tối
  thiểu và typography lấy theo responsive của Sollume.
- `AppMenuGroup` chỉ ghép section và khoảng cách giữa nhóm. `AppFeatureTile`
  chuyển tiếp sang `AppMenuTile`, không giữ ô icon 44 px hoặc padding riêng.
- Bếp của tôi dùng một cột menu trên cả mobile/tablet; giữ tổng quan bữa ăn,
  timer, nhãn, mô tả và toàn bộ route tính năng.
- Cài đặt dùng hàng menu cho Giao diện, Về ứng dụng và Đăng xuất. Công tắc
  giới thiệu vẫn là switch; chọn theme vẫn mở sheet và giữ cơ chế lưu hiện có.
- Không đổi contract Firebase, quyền truy cập hoặc luồng nghiệp vụ. Màu nhấn
  tiếp tục là cam Bếp Xinh. Không thay đổi các shortcut theme dạng icon ở sidebar/hồ sơ.

Xác minh đợt này: 41 test hồ sơ/Cài đặt/bố cục đạt (1 capture tùy chọn skip);
test chọn/lưu theme đạt; các test Bếp và tổng quan bữa ăn đạt trong lượt kiểm tra
ban đầu. Hai finder “Đăng món” đã giới hạn trong hồ sơ để không trùng nút giữa
navigation. Analyzer còn 5 issue ở các file không sửa. Test Home trong
`appearance_test.dart` còn lỗi tìm tooltip `Lưu công thức` đã bị comment trong
source Home; không sửa Home trong đợt chuẩn hóa menu. Chưa kiểm tra trực quan
trên app đang chạy hoặc phát hành Hosting.

`lib/sollume/core/theme/` chứa nguyên bộ theme light/dark, màu, typography,
spacing, radius, sizes và responsive của Sollume. Palette là adaptation có chủ đích: màu nhấn cam, nền nhấn ấm; nền trắng/đen và neutral giữ nguyên.
Theme Bếp Xinh chỉ là facade thêm `AppPalette` cho những màn dùng API cũ.
`MaterialApp.builder` chạy builder responsive gốc, không tạo một ThemeData mô phỏng.
Font `BeVietnamPro` trỏ vào bộ Be Vietnam Pro đã đóng gói; giữ alias cũ cho màn cũ.

19 file UI được đưa từ source vào `lib/sollume/`. Trong đó 17 file chỉ đổi import
namespace (các import tương đối giữ nguyên). `app_colors.dart` thay palette thương hiệu sang cam Bếp Xinh. `AppButton` đổi import animation barrel
thành đúng animation đang dùng và bổ sung icon tùy chọn để giữ icon của Bếp Xinh.
Logic loading, giữ kích thước nhãn, typography và nút FilledButton vẫn từ source.

| Thành phần | Nơi sử dụng thực tế |
| --- | --- |
| `AppTabBar` | Hồ sơ Đã đăng/Đã lưu, chi tiết món Nguyên liệu/Cách nấu |
| `AppButton`, `AppLoadingIndicator`, `AppButtonLabel` | Nút chính/phụ qua facade `core/widgets/AppButton` |
| `AppTextField` | Đăng nhập/đăng ký/quên mật khẩu, công thức, chỉnh hồ sơ, các thanh tìm kiếm |
| `AppMenuSection`, `AppMenuTile` | Nhóm menu và các hàng tài khoản trong Cài đặt |
| `AppSliverAppBar` | App bar thường qua facade Bếp Xinh; nhánh cover/collapse vẫn dùng khả năng riêng |
| `AppTap` | Các menu lấy từ Sollume; guard của Bếp được truyền từ caller |

`AppTabs` nối TabController với lựa chọn được router/Cubit xác nhận. Khi hành động
bị guard từ chối, indicator trở về trạng thái đã xác nhận. Không chuyển state nghiệp vụ
sang component Sollume.

Hai phần điều hướng có adapter riêng:

- Bottom navigation dùng cấu trúc `NavigationBar`/`NavigationDestination`, divider,
  safe padding và theme gốc từ `NavigationBottomBar` Sollume. Thay binding 5 tab Sollume
  bằng 4 điểm đến Bếp Xinh và `AppTapHandler` đang có.
- Sidebar dùng ListTile, spacing, trạng thái chọn và tooltip từ
  `NavigationSidebarItem`. `AppNavigationItem` nhận props/callback thay Cubit Sollume.

`SOLLUME_PORT_MANIFEST.json` lưu đường dẫn nguồn/đích, SHA-256 của snapshot nguồn và
bản port đã review, kèm mô tả adaptation. Hash tính trên UTF-8 chuẩn hóa LF.
Test kiểm tra bản port không tự lệch khỏi manifest; theme facade cũng được đối chiếu
với bản theme port ở cả hai brightness.

## Phần tương thích, không phải sao chép nguyên màn hình

Các màn nấu ăn, bố cục feed/công thức và dữ liệu vẫn là Bếp Xinh. Không mang auth,
repository, router hay Cubit nghiệp vụ Sollume sang. Lớp nhãn UI của port chỉ trả
chuỗi tiếng Việt hiện có và thông báo xử lý; không sao chép hệ thống locale Sollume.
Nút ghost dùng TextButton của theme vì AppButton gốc chỉ có primary/secondary.
Card và chip Material kế thừa CardTheme/ChipTheme gốc, bỏ các màu ghi đè trước đây.
Các style tĩnh cũ lấy typography Sollume ở scale 1; màn dùng TextTheme nhận scale
responsive của source. Một số block nội dung đặc thù vẫn có kích thước riêng.

Vì vậy đây là dùng lại theme/component thật, không có nghĩa mọi màn Bếp Xinh giống
nguyên màn Sollume. Không thay đổi admin, Firestore rules hay dữ liệu production.

## Xác minh

- `flutter analyze --no-pub`.
- `flutter test --no-pub`: kiểm tra guard, trạng thái tab, form, routing, resize,
  bàn phím, chữ lớn và đối chiếu snapshot nguồn.
- Audit 28 route ở 390×844, 800×1100, 1024×768 cho từng theme. Fixture sử dụng
  theme/builder responsive runtime và font đóng gói, không dùng ThemeData cũ.
- Ảnh dark: `build/ui_ux/orange_brand_dark/`; light: `build/ui_ux/orange_brand_light/`.
  Đây là fixture test, không phải ảnh dữ liệu production hay kiểm chứng thiết bị thật.
- Release web: `flutter build web --release --no-pub`.

Bản port cần full restart/rebuild ứng dụng khi xem thay đổi font/dependency.

Kết quả bản port trước khi điều chỉnh màu thương hiệu: analyzer không có issue; 317 test đạt, 1 test chụp ảnh
được skip ở suite mặc định và đã chạy riêng cho cả hai theme. Hai lần capture đạt,
tạo đủ 168 ảnh. Đã xem trực tiếp ảnh Home mobile light/dark, Home tablet dark,
hồ sơ mobile dark, đăng nhập light và Cài đặt tablet dark. Release web build thành công
tại `build/web` (JS mặc định; cảnh báo dry-run Wasm không chặn build).
Chưa deploy bản port này lên Hosting.

Sau điều chỉnh màu thương hiệu: primary gốc `#E8590C`, CTA light `#BF4006`
để chữ trắng đủ tương phản; CTA dark `#FF922B` với chữ nâu đậm. Tên token teal/mint
trong bản port được giữ để tương thích API nguồn, giá trị hiện là sắc cam/kem Bếp Xinh.

Xác minh sau sửa màu: analyzer sạch; 43 test component/navigation/tablet đạt
(1 audit skip trong suite mặc định), kiểm tra riêng 11 test palette/component cũng đạt.
Hai capture light/dark đạt, 168 ảnh đã cập nhật theo palette cam; đã xem đăng nhập
light và hồ sơ dark để xác nhận CTA/điểm nhấn thương hiệu. Chưa build release hoặc
deploy lại sau thay đổi màu này.

Home hiện hiển thị thẳng toàn bộ công thức, đã bỏ cặp tab Mới nhất/Theo dõi và
component HomeFeedSwitch. Trang bảng tin tác giả đang theo dõi giữ route riêng,
không còn cặp tab này; tính năng theo dõi tác giả vẫn truy cập từ Bếp của tôi.
