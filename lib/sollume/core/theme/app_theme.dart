import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_responsive.dart';

export 'app_colors.dart';
export 'app_text_styles.dart';
export 'app_spacing.dart';
export 'app_radius.dart';
export 'app_sizes.dart';
export 'app_responsive.dart';

/*
 * AppTheme là điểm truy cập trung tâm cấu hình toàn bộ ThemeData cho ứng dụng Sollume:
 * - Hỗ trợ cả hai chế độ sáng (AppTheme.light) và tối (AppTheme.dark).
 * - Tự động đồng bộ tỷ lệ co giãn (scale) theo độ rộng màn hình qua AppTheme.builder.
 */
abstract final class AppTheme {
  /* Lấy ThemeData cho chế độ sáng (Light Theme) */
  static ThemeData get light => _build(Brightness.light);

  /* Lấy ThemeData cho chế độ tối (Dark Theme) */
  static ThemeData get dark => _build(Brightness.dark);

  /*
   * Cung cấp builder cho MaterialApp hoặc MaterialApp.router:
   * MaterialApp(builder: AppTheme.builder, ...)
   * Giúp tự động tính toán scale UI theo độ rộng màn hình và truyền vào toàn bộ Theme.
   */
  static Widget builder(BuildContext context, Widget? child) =>
      AppResponsiveInit(
        child: child ?? const SizedBox.shrink(),
        builder: (context, metrics, navigator) => Theme(
          data: _build(
            Theme.of(context).brightness,
            scale: metrics.scale,
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: navigator,
        ),
      );

  /*
   * Hàm nội bộ khởi tạo ThemeData hoàn chỉnh theo độ sáng (Brightness)
   * và hệ số co giãn giao diện (scale).
   */
  static ThemeData _build(
    Brightness brightness, {
    double scale = 1,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final colors = brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
    return _components(
      brightness: brightness,
      colors: colors,
      text: AppTextStyles.build(colors, scale: scale),
      scale: scale,
      scheme: _colorScheme(brightness, colors),
      textScaler: textScaler,
    );
  }

  /*
   * Khởi tạo ColorScheme chuẩn Material 3 tương ứng với từng chế độ sáng/tối.
   */
  static ColorScheme _colorScheme(
    Brightness brightness,
    AppThemeColors colors,
  ) {
    final isDark = brightness == Brightness.dark;
    final c = colors;

    /*
     * Màu thông báo lỗi được tinh chỉnh để tăng tính tương phản và dễ đọc chữ:
     * - Dark mode: #FFB4AB
     * - Light mode: #B4232D
     * (Màu đỏ gốc AppColors.sourceRed vẫn được giữ cho các chấm chỉ báo trạng thái trang trí).
     */
    final error = isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB4232D);
    final onError = isDark ? const Color(0xFF690005) : Colors.white;
    return ColorScheme(
      brightness: brightness,
      primary: c.cta,
      onPrimary: c.onCta,
      primaryContainer: c.soft,
      onPrimaryContainer: c.onSoft,
      secondary: c.mint,
      onSecondary: c.onMint,
      secondaryContainer: c.soft,
      onSecondaryContainer: c.onSoft,
      tertiary: c.warm,
      onTertiary: const Color(0xFF3F2C17),
      tertiaryContainer: isDark
          ? const Color(0xFF51391F)
          : const Color(0xFFFFE8CE),
      onTertiaryContainer: isDark
          ? const Color(0xFFFFDDB5)
          : const Color(0xFF51391F),
      error: error,
      onError: onError,
      errorContainer: isDark
          ? const Color(0xFF93000A)
          : const Color(0xFFFFDAD6),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410002),
      surface: c.background,
      onSurface: c.text,
      surfaceDim: c.previewBackground,
      surfaceBright: c.card,
      surfaceContainerLowest: c.background,
      surfaceContainerLow: c.card,
      surfaceContainer: c.field,
      surfaceContainerHigh: c.header,
      surfaceContainerHighest: c.field,
      onSurfaceVariant: c.muted,
      outline: c.muted,
      outlineVariant: c.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.text,
      onInverseSurface: c.background,
      inversePrimary: isDark ? AppColors.teal : AppColors.mint,
      surfaceTint: Colors.transparent,
    );
  }

  /*
   * Cấu hình toàn diện các thành phần giao diện (UI components) Material 3:
   * Nút bấm, Ô nhập liệu, AppBar, NavigationBar, Thẻ Card, Hộp thoại Dialog...
   */
  static ThemeData _components({
    required Brightness brightness,
    required AppThemeColors colors,
    required TextTheme text,
    required ColorScheme scheme,
    required double scale,
    required TextScaler textScaler,
  }) {
    final isDark = brightness == Brightness.dark;
    final c = colors;
    final error = scheme.error;

    /* Hàm tính kích thước co giãn UI với giới hạn min/max an toàn */
    double ui(double base, {double? min, double? max}) => (base * scale)
        .clamp(
          min ?? base * AppSizes.minUiScale,
          max ?? base * AppSizes.maxUiScale,
        )
        .toDouble();

    /* Chiều cao chuẩn của các nút bấm và ô tương tác (tối thiểu 48px, tối đa 56px) */
    final controlHeight = ui(AppSizes.buttonHeight, min: 48, max: 56);

    /* Viền bo góc chuẩn cho nút bấm và ô nhập liệu */
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );

    /* Viền mặc định phẳng (không viền) cho ô nhập liệu */
    final plainInput = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide.none,
    );

    /* Phong cách nút bấm chính (Primary CTA Button) */
    final primaryButton = FilledButton.styleFrom(
      backgroundColor: c.cta,
      foregroundColor: c.onCta,
      disabledBackgroundColor: c.field,
      disabledForegroundColor: c.muted.withValues(alpha: .6),
      minimumSize: Size(48, controlHeight),
      padding: EdgeInsets.symmetric(
        horizontal: ui(20, min: 16, max: 24),
        vertical: ui(14, min: 12, max: 16),
      ),
      shape: rounded,
      textStyle: text.labelLarge,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      tapTargetSize: MaterialTapTargetSize.padded,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,

      /* Màu nền và bề mặt */
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      cardColor: c.card,
      dividerColor: c.divider,
      disabledColor: c.muted,
      hintColor: c.muted,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      applyElevationOverlayColor: false,

      /* Hệ thống kiểu chữ (Typography) */
      fontFamily: AppTextStyles.fontFamily,
      textTheme: text,

      /* Phần mở rộng theme ngữ cảnh (ThemeExtension) */
      extensions: <ThemeExtension<dynamic>>[c],

      /* Cấu hình biểu tượng (Icons) */
      iconTheme: IconThemeData(color: c.text, size: ui(22, min: 20, max: 24)),
      primaryIconTheme: IconThemeData(
        color: c.text,
        size: ui(22, min: 20, max: 24),
      ),

      /* Thanh tiêu đề ứng dụng (AppBar) */
      appBarTheme: AppBarThemeData(
        backgroundColor: c.background,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: math.max(
          ui(56, min: 56, max: 64),
          textScaler.scale(text.titleLarge!.fontSize!) *
                  text.titleLarge!.height! +
              2 * ui(8, min: 8, max: 12),
        ),
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: c.text, size: ui(22, min: 20, max: 24)),
        systemOverlayStyle:
            (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarContrastEnforced: false,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
      ),

      /* Thẻ thông tin (Card) */
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      /* Nút bấm chính dạng filled / elevated */
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),

      /* Nút bấm viền / phụ (Outlined Button) */
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          backgroundColor: c.field,
          side: BorderSide.none,
          minimumSize: Size(48, controlHeight),
          padding: EdgeInsets.symmetric(
            horizontal: ui(20, min: 16, max: 24),
            vertical: ui(14, min: 12, max: 16),
          ),
          shape: rounded,
          textStyle: text.labelLarge,
        ),
      ),

      /* Nút bấm chữ (Text Button) */
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
          padding: EdgeInsets.symmetric(vertical: ui(4, min: 8, max: 12)),
          textStyle: text.labelLarge,
          iconSize: (text.labelLarge?.fontSize ?? 14) * 1.5,
          shape: rounded,
          alignment: Alignment.center,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),

      /* Nút bấm icon (Icon Button) */
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.text,
          disabledForegroundColor: c.muted.withValues(alpha: .5),
          minimumSize: Size(48, controlHeight),
          padding: const EdgeInsets.all(12),
          shape: const CircleBorder(),
        ),
      ),

      /* Ô nhập văn bản (TextField / TextFormField) */
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: c.field,
        border: plainInput,
        enabledBorder: plainInput,
        disabledBorder: plainInput,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: c.accent, width: 0.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ui(16, min: 14, max: 20),
          vertical: ui(14, min: 12, max: 16),
        ),
        hintStyle: text.bodyMedium?.copyWith(color: c.muted),
        labelStyle: text.bodySmall,
        floatingLabelStyle: text.bodySmall?.copyWith(color: c.accent),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: error),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
      ),

      /* Màu sắc khi bôi đen / chọn văn bản */
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.mint.withValues(alpha: 0.35),
        selectionHandleColor: c.accent,
      ),

      /* Mục danh sách (ListTile) */
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 16,
        horizontalTitleGap: 16,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        textColor: c.text,
        iconColor: c.muted,
        selectedColor: c.text,
        selectedTileColor: c.field,
        shape: const RoundedRectangleBorder(),
      ),

      /* Đường kẻ phân cách (Divider) */
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: AppSizes.dividerThickness,
        space: 1,
      ),

      /* Chip pill gọn, phẳng; màu chọn dùng nền nhấn nhẹ của Sollume. */
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: c.field,
        secondarySelectedColor: c.field,
        disabledColor: c.field,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(color: c.muted),
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: c.text,
          fontWeight: FontWeight.w600,
        ),
        padding: EdgeInsets.zero,
        // Native Chip đã có chiều cao nền 32; nới nhẹ để pill gọn khoảng 34px.
        labelPadding: EdgeInsets.symmetric(horizontal: ui(14), vertical: ui(1)),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        selectedShadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      /* Thanh tab dạng chữ và gạch chân, dùng chung qua AppTabBar. */
      tabBarTheme: TabBarThemeData(
        labelColor: c.text,
        unselectedLabelColor: c.muted,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorColor: c.text,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: c.text, width: 2),
        ),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: EdgeInsets.symmetric(horizontal: ui(16)),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return c.text.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return c.text.withValues(alpha: 0.04);
          }
          return Colors.transparent;
        }),
      ),

      /* Thanh điều hướng dưới đáy màn hình (NavigationBar) */
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        height: ui(AppSizes.navigationHeight, min: 68, max: 80),
        indicatorColor: Colors.transparent,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: ui(22, min: 20, max: 24),
            color: states.contains(WidgetState.selected) ? c.text : c.text,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected) ? c.text : c.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.normal,
            fontSize: 11
          ),
        ),
      ),

      /* Thanh điều hướng dạng cột dọc cho màn hình lớn (NavigationRail) */
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.background,
        elevation: 0,
        indicatorColor: c.soft,
        useIndicator: true,
        selectedIconTheme: IconThemeData(
          color: c.accent,
          size: ui(22, min: 20, max: 24),
        ),
        unselectedIconTheme: IconThemeData(
          color: c.muted,
          size: ui(22, min: 20, max: 24),
        ),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: c.accent),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: c.muted),
      ),

      /* Công tắc bật/tắt (Switch) */
      switchTheme: SwitchThemeData(
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.field
              : states.contains(WidgetState.selected)
              ? c.mint
              : c.divider,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.muted
              : states.contains(WidgetState.selected)
              ? c.onMint
              : c.card,
        ),
      ),

      /* Hộp kiểm (Checkbox) */
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        checkColor: WidgetStatePropertyAll(c.onCta),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.field
              : states.contains(WidgetState.selected)
              ? c.cta
              : Colors.transparent,
        ),
        side: BorderSide(color: c.muted, width: 1.5),
      ),

      /* Nút chọn một (Radio Button) */
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? c.divider
              : states.contains(WidgetState.selected)
              ? c.accent
              : c.muted,
        ),
      ),

      /* Chỉ báo tiến trình (Progress Indicator) */
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.field,
        circularTrackColor: c.field,
      ),

      /* Thanh trượt điều chỉnh (Slider) */
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.field,
        thumbColor: c.accent,
        overlayColor: c.mint.withValues(alpha: 0.2),
      ),

      /* Bảng kéo lên từ đáy màn hình (BottomSheet) */
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.background,
        modalBackgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: Colors.black54,
        constraints: const BoxConstraints(maxWidth: AppSizes.contentRail),
        showDragHandle: true,
        dragHandleColor: c.divider,
        dragHandleSize: const Size(36, 4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.divider),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      /* Hộp thoại thông báo / xác nhận (Dialog) */
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black54,
        constraints: const BoxConstraints(maxWidth: AppSizes.dialogWidth),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.divider),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      ),

      /* Thanh thông báo nhanh nổi (SnackBar) */
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.background),
        actionTextColor: isDark ? AppColors.teal : AppColors.mint,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),

      /* Khối nội dung mở rộng / thu gọn (ExpansionTile) */
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        textColor: c.text,
        collapsedTextColor: c.text,
        iconColor: c.muted,
        collapsedIconColor: c.muted,
        tilePadding: const EdgeInsets.symmetric(vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 16),
        shape: const Border(),
        collapsedShape: const Border(),
      ),
    );
  }
}
