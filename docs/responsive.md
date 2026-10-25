# Responsive trên điện thoại và tablet

`AppLayout` là nguồn quy tắc layout dùng chung. Phân loại theo chiều rộng cửa sổ
logical pixel, không theo cạnh ngắn nhất hay tên thiết bị. Bàn phím thay đổi vùng
hiển thị nhưng không thay ngưỡng tablet. `AppSize` và `ResponsiveUtils` dùng cùng
ngưỡng 600px; các cột bên trong dùng `LayoutBuilder` theo constraint của cha.

| Nội dung | Mobile | Tablet |
| --- | --- | --- |
| Trang danh sách, chi tiết, đăng món | Tối đa 440px | Tối đa 1120px |
| Cài đặt/form đơn | Tối đa 440px | Tối đa 720px |
| Sheet chọn nguyên liệu/chỉnh hồ sơ | Tối đa 440px | Tối đa 640px |
| Form xác thực | Một cột | Form tối đa 440px; thêm cột thương hiệu khi cửa sổ từ 1000px |

`AppAdaptiveColumns` xếp dọc khi vùng nội dung dưới 840px và thành hai cột khi đủ
rộng. Mỗi bố cục có một vùng cuộn ngoài, hai pane có chiều cao tự nhiên; không dùng
hai ListView lồng nhau hoặc buộc chiều cao card cố định. Giỏ đi chợ dùng ngưỡng
760px để hiển thị hai nhóm nguyên liệu cạnh nhau.

- Home: header, banner, danh mục, shortcut và danh sách cùng chiều rộng. Banner
  tablet cao hơn; slider tính số thẻ theo chiều rộng thực tế. ProductGrid tự chọn
  2–4 cột (tile mục tiêu từ 210px); chiều cao vẫn xét cỡ chữ hệ thống.
- Tủ lạnh: tồn kho bên trái, gợi ý món bên phải khi đủ chỗ; màn hẹp xếp tồn kho
  trước gợi ý. Tìm/thêm nguyên liệu nằm trong bottom sheet, cuộn được khi mở bàn phím.
- Hồ sơ: thông tin cá nhân cạnh thống kê/hành động; lưới món tự tăng số cột.
- Giỏ đi chợ: hai nhóm món xếp cạnh nhau. State danh sách nằm ngoài layout nên
  xoay màn hình không làm mất đánh dấu đã mua.
- Chi tiết món: ảnh/tổng quan cạnh nguyên liệu hoặc cách nấu. Chế độ đang nấu
  giữ chiều rộng đọc 720px; action bar dùng khung trang chung.
- Đăng món: thông tin chia hai cột; phần nguyên liệu có cột khẩu phần riêng;
  nhiều bước nấu chia hai cột; xem trước đặt tổng quan cạnh chi tiết công thức.
- Đăng nhập/đăng ký/quên mật khẩu: dùng cùng bố cục mobile trên mọi kích thước.
  Tablet chỉ căn giữa và giới hạn nội dung ở 440px, không thêm card hay pane
  thương hiệu. AppBar, logo và form giữ cùng cách trình bày. Nội dung cuộn khi
  bàn phím mở; cùng widget/Cubit giữ dữ liệu khi đổi chiều hoặc qua mốc mobile/tablet.
- Cài đặt: giới hạn chiều rộng đọc; sheet chỉnh hồ sơ rộng hơn trên tablet.

Điều hướng tablet giữ bottom bar hiện có, giới hạn 720px và căn giữa. Các route
chi tiết/form vẫn mở ngoài shell theo cấu hình hiện tại.

`test/features/tablet_layout_test.dart` chạy mọi route tại 600×960, 800×1100,
1024×768, 1280×800 với chữ 150%, kiểm tra cuộn, hai pane, xoay màn hình, bàn phím,
giữ dữ liệu đăng món/xác thực và đánh dấu giỏ đi chợ. Các test feature còn kiểm tra
mobile 320px và luồng tương tác của từng màn.
