# Tài liệu Kỹ thuật Dự án Bếp Xinh (App Bếp Xinh)

Tài liệu này mô tả chi tiết kiến trúc, công nghệ và các quy chuẩn lập trình được triển khai trong dự án **Bếp Xinh**. Tất cả lập trình viên tham gia dự án cần tuân thủ các quy tắc dưới đây.

---

## 1. Công nghệ & Thư viện cốt lõi (Tech Stack)

| Hạng mục | Thư viện / Công cụ | Phiên bản | Mục đích sử dụng |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter / Dart SDK | `^3.13.2` | Nền tảng phát triển ứng dụng di động đa nền tảng |
| **State Management** | `flutter_bloc` | `^9.1.1` | Quản lý trạng thái theo mô hình BLoC / Cubit |
| **Routing** | `go_router` | `^18.1.0` | Điều hướng khai báo (Declarative Routing), hỗ trợ deep-link |
| **Responsive** | `responsive_framework` + `AppSize` | `^1.5.1` | Tự động thích ứng kích thước & layout đa thiết bị (Mobile/Tablet) |
| **Network Check** | `connectivity_plus` | `^7.0.0` | Giám sát trạng thái kết nối Internet |
| **Typography** | `google_fonts` | `^6.2.1` | Phông chữ thương hiệu **Be Vietnam Pro** |
| **Animation** | `flutter_animate` | `^4.5.2` | Hiệu ứng chuyển động vi mô (Micro-interactions) |
| **Data Immutability** | `equatable` | `^3.0.0` | So sánh giá trị State trong Cubit/BLoC |
| **Functional / Result** | `fpdart` | `^1.1.0` | Xử lý lỗi functional (`Either<Failure, T>`) |
| **Debug UI** | `device_preview` | `^1.3.1` | Giả lập và kiểm thử giao diện nhiều thiết bị trong môi trường Debug |

---

## 2. Cấu trúc thư mục (Project Architecture)

Dự án áp dụng mô hình kiến trúc lai **Feature-Driven & Layered Architecture**:

```text
lib/
├── app.dart                          # Root Widget (MaterialApp, Theme, ResponsiveBreakpoints)
├── main.dart                         # Entry point (Khởi tạo App & cấu hình AppTapInterceptors)
├── core/                             # Tầng dùng chung toàn dự án (Design System & Platform Core)
│   ├── colors/
│   │   └── app_colors.dart           # Bảng màu thương hiệu (#E8590C) & màu ngữ nghĩa
│   ├── constants/
│   │   ├── app_assets.dart           # Định nghĩa đường dẫn hình ảnh/icon tài nguyên
│   │   └── app_constants.dart        # Tên app, slogan, version, maxContentWidth
│   ├── dimensions/
│   │   ├── app_size.dart             # Bộ tính toán co giãn thông minh (Damped Scaling)
│   │   └── dimensions.dart           # Barrel export
│   ├── router/
│   │   └── app_router.dart           # Định nghĩa cấu hình GoRouter & Path/Name Constants
│   ├── tap/                          # Hệ thống xử lý tap tập trung (Centralized Tap System)
│   │   ├── app_tap_handler.dart      # Bộ điều phối xử lý Tap trung tâm
│   │   ├── tap_config.dart           # Model cấu hình hành vi Tap
│   │   ├── tap_extension.dart        # Extension context.onAppTap(...) tiện dụng
│   │   ├── tap_interceptor.dart      # Interceptors: Throttle, Haptic, Network, Auth, Analytics
│   │   └── tap.dart                  # Barrel export
│   ├── text_styles/
│   │   └── app_text_styles.dart      # Typography Be Vietnam Pro phân cấp chuẩn Material 3
│   ├── themes/
│   │   └── app_theme.dart            # Cấu hình ThemeData Material 3 Light Theme
│   ├── utils/
│   │   └── responsive_utils.dart     # Extension context.isTablet, context.isMobile
│   └── widgets/                      # Các UI Components dùng chung
│       ├── app_button.dart           # Nút bấm chuẩn tích hợp AppTap & auto-sizing
│       ├── app_messenger.dart        # Thông báo Toast/Snack tùy biến theo thiết bị
│       ├── app_sliver_app_bar.dart   # Sliver AppBar tùy biến
│       ├── app_tap.dart              # Vùng chạm cảm ứng tích hợp scale animation & guard
│       ├── responsive_layout.dart    # Điều phối giao diện Mobile / Tablet / Desktop
│       └── widgets.dart              # Barrel export
├── data/                             # Tầng dữ liệu (Data Layer)
│   ├── repositories/                 # Khai báo Repository & Implementation
│   └── services/                     # API Client, Local Storage, Firebase/Supabase
└── features/                         # Các module tính năng theo nghiệp vụ
    └── auth/                         # Module xác thực người dùng
        ├── cubits/                   # State Management
        │   ├── login/                # LoginCubit & LoginState
        │   ├── register/             # RegisterCubit & RegisterState
        │   └── forgot_password/      # ForgotPasswordCubit & ForgotPasswordState
        ├── screens/                  # Màn hình giao diện
        │   ├── login/                # LoginScreen, LoginMobileView, LoginTabletView
        │   ├── register/             # RegisterScreen, RegisterMobileView, RegisterTabletView
        │   └── forgot_password/      # ForgotPasswordScreen, MobileView, TabletView
        ├── validation/
        │   └── validation.dart       # Bộ quy tắc kiểm tra tính hợp lệ dữ liệu
        └── widgets/                  # Sub-widgets (LoginForm, RegisterForm, ForgotPasswordForm, v.v.)
```

---

## 3. Hệ thống Design System & Giao diện

### 3.1. Bảng màu (AppColors)
- **Primary Color:** `#E8590C` (Màu cam ấm thực đặc trưng, kích thích vị giác). Có sẵn thang sắc độ từ `primary50` đến `primary900`.
- **Secondary Color:** `#2B8A3E` (Xanh thảo mộc tươi mát).
- **Accent Color:** `#FAB005` (Vàng gia vị / đánh giá sao).
- **Background & Surface:** `#F8F9FA` (Nền dịu mắt) và `Colors.white` (Surface Card/Modal).

### 3.2. Typography (AppTextStyles)
Sử dụng phông chữ **Be Vietnam Pro** với độ phân cấp rõ ràng:
- `displayLarge` (48sp), `displayMedium` (36sp), `displaySmall` (30sp).
- `headlineLarge` (26sp), `headlineMedium` (22sp), `headlineSmall` (20sp).
- `titleLarge` (18sp), `titleMedium` (16sp), `titleSmall` (14sp).
- `bodyLarge` (16sp), `bodyMedium` (14sp), `bodySmall` (12sp).
- `labelLarge` (14sp), `labelMedium` (12sp), `labelSmall` (11sp).

---

## 4. Hệ thống Responsive & Đa thiết bị (Responsive Architecture)

Dự án hỗ trợ mượt mà từ điện thoại nhỏ (màn hình hẹp/bị zoom to), điện thoại siêu dài (như Vivo) cho đến máy tính bảng (Tablet) thông qua 3 cơ chế:

### 4.1. Điều phối layout theo Breakpoint (`ResponsiveLayout`)
Tách riêng giao diện Mobile và Tablet để code rõ ràng, không bị lồng ghép `if/else` phức tạp:
```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: const ResponsiveLayout(
        mobile: LoginMobileView(),
        tablet: LoginTabletView(),
      ),
    );
  }
}
```

### 4.2. Giới hạn bề ngang tối đa trên Tablet (`AppConstants.maxContentWidth`)
Trên Tablet, form nhập liệu được giới hạn độ rộng `440.0` để tránh bị kéo dãn toàn màn hình gây mất thẩm mỹ:
```dart
ConstrainedBox(
  constraints: const BoxConstraints(
    maxWidth: AppConstants.maxContentWidth, // 440.0
  ),
  child: const LoginForm(),
)
```

### 4.3. Hệ thống co giãn thông minh (`AppSize`)
Không dùng tỉ lệ cứng; `AppSize` tính toán theo thuật toán giảm chấn (damped scaling):
```dart
final size = context.appSize;

// Kích thước chuẩn hóa thích ứng theo thiết bị:
double btnHeight = size.buttonHeight; // 46 trên máy nhỏ, 50 máy chuẩn, 58 tablet
double iconSize = size.iconMedium;

// Tiện ích extension co giãn:
SizedBox(height: 28.h(context));
EdgeInsets.symmetric(horizontal: 16.w(context));
```

---

## 5. Quản lý tương tác Tap tập trung (`AppTapHandler`)

Tất cả các hành vi bấm/chạm nút bấm, thẻ Card, Icon,... đều phải đi qua hệ thống tập trung để đảm bảo:
1. **Chống nhấn 2 nút cùng lúc / Đa chạm (Multi-touch Collision Guard):** Tự động phát hiện và chặn khi người dùng cố tình dùng 2 ngón tay nhấn 2 nút khác nhau cùng lúc (khoảng cách chạm < 350ms).
2. **Khóa chống chạy đè tác vụ (Concurrency Lock):** Khi đang có một hành động bất đồng bộ đang chạy (gọi API, submit form, navigation), hệ thống tự động khóa và chặn tất cả các tap khác cho đến khi tác vụ hoàn thành (trừ khi bật `allowConcurrent: true`).
3. **Chống spam click (Per-action Throttle):** Ngăn chặn người dùng bấm liên tục vào cùng 1 nút gây gửi request trùng lặp.
4. **Rung phản hồi nhẹ (Haptic Feedback):** Tăng trải nghiệm chạm thực tế.
5. **Tự động kiểm tra mạng (`requiresNetwork`):** Chặn hành động và báo lỗi ngay nếu thiết bị ngắt kết nối Internet.
6. **Kiểm tra quyền đăng nhập (`requiresAuth`):** Tự động chặn và nhắc nhở nếu chưa đăng nhập.
7. **Ghi nhận Analytics tự động (`actionName` + `params`):** Thu thập dữ liệu hành vi người dùng mà không cần chèn code Firebase rải rác.
8. **Bắt lỗi an toàn & Tự động giải phóng Lock (Safe Execution & Auto Release):** Sử dụng khối try-catch-finally đảm bảo dù Exception xảy ra thì hệ thống vẫn giải phóng lock an toàn, không làm đơ giao diện.

### Cách sử dụng 1: Nút bấm chuẩn hóa (`AppButton`)
```dart
AppButton(
  text: 'Đăng nhập',
  actionName: 'btn_login',
  requiresNetwork: true, // Tự động chặn và hiện thông báo nếu mất mạng
  isLoading: state.status == LoginStatus.loading,
  throttleDuration: const Duration(milliseconds: 600),
  onPressed: () {
    context.read<LoginCubit>().submitLogin();
  },
)
```

### Cách sử dụng 2: Vùng bấm cho Card, Item, Banner, Icon (`AppTap`)
```dart
AppTap(
  actionName: 'recipe_item_click',
  requiresNetwork: true,
  requiresAuth: false,
  scaleOnTap: true, // Hiệu ứng co nhẹ 0.97 mượt mà khi chạm
  params: {'recipe_id': item.id},
  onTap: () {
    context.push('/recipe/${item.id}');
  },
  child: RecipeCard(recipe: item),
)
```

### Cách sử dụng 3: Extension `context.onAppTap` cho widget Flutter tiêu chuẩn
```dart
IconButton(
  icon: const Icon(Icons.share),
  onPressed: context.onAppTap(
    () => shareRecipe(),
    actionName: 'share_recipe',
    requiresNetwork: true,
  ),
)
```

### Cấu hình Handler tại `main.dart`
Hành vi của `requiresAuth` và tracking Analytics được đăng ký tập trung một lần duy nhất tại `main.dart`:
```dart
void _setupTapInterceptors() {
  AppTapHandler.instance.configureAuth(
    isAuthenticated: () => false, // Kết nối với AuthBloc/TokenStorage
    onUnauthenticated: (context, config) {
      AppMessenger.showWarning(context, 'Hành động yêu cầu đăng nhập!');
    },
  );

  AppTapHandler.instance.configureAnalytics(
    onTrack: (actionName, params) {
      // FirebaseAnalytics.instance.logEvent(name: actionName, parameters: params);
      debugPrint('🚀 [Analytics] Action: $actionName | Params: $params');
    },
  );
}
```

---

## 6. Hệ thống Thông báo thích ứng (`AppMessenger`)

Thay thế `ScaffoldMessenger` mặc định bằng hệ thống Toast hiển thị qua `OverlayEntry`, tự động nhận diện thiết bị:
- **Mobile (< 600px):** Nổi ở phía dưới (Bottom Floating Toast).
- **Tablet (>= 600px):** Nổi ở góc trên bên trái (Top-Left Floating Toast).

```dart
// Gọi nhanh qua BuildContext extension:
context.showSuccess('Đăng ký tài khoản thành công!', title: 'Thành công');
context.showWarning('Vui lòng kiểm tra lại thông tin.', title: 'Lưu ý');
context.showError('Đã có lỗi xảy ra!', title: 'Thất bại');
context.showInfo('Đã lưu công thức vào mục yêu thích.');
```

---

## 7. Quản lý trạng thái (State Management)

Dự án sử dụng **BLoC / Cubit** kết hợp với **State bất biến (Immutable State)**:

1. **Cubit:**
   - Mỗi màn hình/nghiệp vụ có 1 Cubit riêng (ví dụ: `LoginCubit`, `RegisterCubit`).
   - Cubit chỉ xử lý logic, emit State mới thông qua phương thức `state.copyWith(...)`.
2. **View:**
   - **`BlocListener`**: Dành cho tác vụ điều hướng (Navigation), hiển thị thông báo (`context.showSuccess`), mở Dialog.
   - **`BlocSelector`**: Chỉ rebuild phần UI thực sự phụ thuộc vào thuộc tính cần theo dõi (ví dụ: `isPasswordObscured`, `isLoading`).
   - Tránh dùng `BlocBuilder` bao phủ toàn bộ cây Widget lớn.

---

## 8. Quy chuẩn lập trình (Coding Conventions)

1. **Đặt tên file & thư mục:**
   - Sử dụng `snake_case` cho tên file (ví dụ: `login_text_field.dart`, `register_checkbox_policy.dart`).
   - Sử dụng `PascalCase` cho tên Class (ví dụ: `LoginTextField`, `RegisterCheckboxPolicy`).
2. **Validation:**
   - Mọi biểu thức chính quy (Regex) và quy tắc kiểm tra form đặt trong `lib/features/auth/validation/validation.dart`. Không hardcode kiểm tra regex trong Widget hay Cubit.
3. **Import:**
   - Ưu tiên import tương đối cho các file trong cùng feature.
   - Sử dụng import package cho các component từ `core/`.
   - Luôn chạy `flutter analyze` trước khi commit code để đảm bảo không có cảnh báo hoặc import thừa.
