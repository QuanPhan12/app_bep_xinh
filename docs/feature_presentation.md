# Giao diện các màn chức năng

`AppFeatureTheme` áp dụng tại entrypoint của Tủ lạnh, Hồ sơ cá nhân/công
khai, Cài đặt, Tìm kiếm, Đăng món và Chi tiết/Nấu món. Scope này không bọc
NavigationScreen, Home, Giỏ hàng hoặc Auth. Đăng nhập, Đăng ký và Quên mật khẩu
dùng giao diện mobile làm chuẩn cho cả điện thoại và tablet. Nội dung trên
tablet được căn giữa, tối đa 440px; không có card hoặc phần thương hiệu riêng.

Palette dùng nền kem và xanh thảo mộc cho thông tin hỗ trợ.
Card và khung nội dung không viền, bo góc 12px theo AppCard.radius.
Nút chính luôn dùng AppColors.primaryGradient có sẵn, nút phụ dùng primary50;
không có màu cam riêng hoặc biến thể nút viền cho từng feature.
AppCard, AppAppBar, AppSearchBar, AppSectionHeader,
AppActionBar và AppLoadState đọc scope; ngoài scope vẫn dùng cách trình bày cũ.
Marker là InheritedTheme để sheet/dialog mở từ các màn chức năng giữ cùng style.

AppChoiceChip và AppFilterChip dùng chung style không viền: mục được chọn có
nền primary, chữ trắng; mục còn lại có nền surfaceVariant. Tab phân đoạn dùng
AppSelectionStyles.segmented theo cùng quy tắc. AppButton và các bộ chọn không
thay đổi style theo AppFeatureTheme.

AppFeatureHeader cung cấp phần mở đầu với phân cấp chữ rõ và ảnh món ăn có sẵn.
Ảnh trang trí được bỏ khỏi semantics, có giới hạn decode và fallback khi lỗi.
Trên màn hẹp hoặc chữ lớn, phần ảnh nhường không gian cho nội dung. Header của
Tìm kiếm ẩn khi nhập hoặc mở bàn phím để giữ không gian kết quả.

ProfileCover dùng chung cho hồ sơ cá nhân
và công khai, đi cùng thống kê thực từ state. Không thêm số liệu giả hoặc nút
chưa có luồng xử lý. RecipeContentOverview và RecipeStepContent vẫn dùng chung
cho xem trước, chi tiết và nấu món; badge bước/thời gian tự xuống dòng.

Tất cả bố cục tiếp tục theo AppLayout. Kiểm tra hồi quy bao gồm toàn bộ route
trên điện thoại 320 px với chữ 150%, tablet dọc/ngang, bàn phím, xoay màn,
giữ dữ liệu form, điều hướng và scope Home/Giỏ hàng/Auth.
