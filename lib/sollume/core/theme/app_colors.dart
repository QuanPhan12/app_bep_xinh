import 'package:flutter/material.dart';

/*
 * AppColors: bảng màu gốc của Sollume.
 * Phong cách Instagram: bề mặt trung tính (trắng / đen), chữ gần đen,
 * viền mảnh thay cho bóng, màu cam Bếp Xinh là màu nhấn thương hiệu.
 */
abstract final class AppColors {
  /* Giữ tên token tương thích Sollume; màu thương hiệu thuộc Bếp Xinh. */
  static const brandOrange = Color(0xFFE8590C);
  static const primary = brandOrange;

  /* ---------- Light ---------- */
  static const background = Color(0xFFFFFFFF); // nền màn hình
  //trùng nền
  static const onText = Color(0xFFFFFFFF); // nền màn hình
  static const card = Color(0xFFFFFFFF); // thẻ (tách bằng viền divider)
  static const field = Color(0xFFEFEFEF); // ô nhập, nút phụ
  static const text = Color(0xFF000000); // chữ chính (trung tính)
  static const textSecondary = Color(0xFF737373); // chữ phụ (trung tính)
  static const divider = Color(0xFFDBDBDB); // viền mảnh 1px
  static const soft = Color(0xFFFFF4E6); // nền nhấn cam nhẹ (dùng ít)

  /* ---------- Dark ---------- */
  static const darkBackground = Color(0xFF000000);

  static const darkCard = Color(0xFF121212);
  static const darkField = Color(0xFF262626);
  static const darkText = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA8A8A8);
  static const darkDivider = Color(0xFF262626);
  static const darkSoft = Color(0xFF331B10);

  /* ---------- Palette Bếp Xinh, không dùng teal/mint Sollume ---------- */
  static const teal = brandOrange;
  static const mint = Color(0xFFFFD8A8);
  static const warm = Color(0xFFEDAA60);
  static const sourceRed = Color(0xFFF2555A);

  /* SOS: đỏ riêng, chữ trắng đạt >= 4.5:1 trên nền sáng */
  static const sos = Color(0xFFD62F3C);
  static const darkSos = Color(0xFFF05A66);

  /*
   * Vòng gradient quanh avatar / check-in cảm xúc (giống story ring).
   * Chỉ dùng cho vòng viền, không dùng làm nền.
   */
  static const ringGradient = LinearGradient(
    colors: [teal, warm],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /* Dải màu thương hiệu cũ (giữ để không làm hỏng chỗ đang dùng) */
  static const gradient = LinearGradient(
    colors: [teal, mint, warm],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/*
 * AppThemeColors: màu ngữ cảnh theo theme sáng/tối.
 * Giữ nguyên tên trường cũ; chỉ THÊM `sos`, `onSos` (có giá trị mặc định).
 */
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.card,
    required this.field,
    required this.text,
    required this.muted,
    required this.divider,
    required this.accent,
    required this.soft,
    required this.onSoft,
    required this.cta,
    required this.onCta,
    required this.onMint,
    required this.header,
    required this.headerEnd,
    required this.previewBackground,
    this.sos = AppColors.sos,
    this.onSos = const Color(0xFFFFFFFF),
    this.teal = AppColors.teal,
    this.mint = AppColors.mint,
    this.warm = AppColors.warm,
  });

  final Color background;
  final Color card;
  final Color field;
  final Color text;
  final Color muted;
  final Color divider;
  final Color accent;
  final Color soft;
  final Color onSoft;
  final Color cta;
  final Color onCta;
  final Color onMint;

  /* Header phẳng như Instagram: header == headerEnd == background */
  final Color header;
  final Color headerEnd;
  final Color previewBackground;

  /* Nút SOS và chữ trên nút SOS */
  final Color sos;
  final Color onSos;

  final Color teal;
  final Color mint;
  final Color warm;

  /* ---------- Light ---------- */
  static const light = AppThemeColors(
    background: AppColors.background,
    card: AppColors.card,
    field: AppColors.field,
    text: AppColors.text,
    muted: AppColors.textSecondary,
    divider: AppColors.divider,
    accent: Color(0xFFBF4006),
    soft: AppColors.soft,
    onSoft: Color(0xFF7A2804),
    cta: Color(0xFFBF4006),
    onCta: Color(0xFFFFFFFF),
    onMint: Color(0xFF7A2804),
    header: Color(0xFFFFFFFF),
    headerEnd: Color(0xFFFFFFFF),
    previewBackground: Color(0xFFF2F2F2),
  );

  /* ---------- Dark ---------- */
  static const dark = AppThemeColors(
    background: AppColors.darkBackground,
    card: AppColors.darkCard,
    field: AppColors.darkField,
    text: AppColors.darkText,
    muted: AppColors.darkTextSecondary,
    divider: AppColors.darkDivider,
    accent: Color(0xFFFFAA66),
    soft: AppColors.darkSoft,
    onSoft: Color(0xFFFFCFAC),
    cta: Color(0xFFFF922B),
    onCta: Color(0xFF3D1707),
    onMint: Color(0xFF3D1707),
    header: Color(0xFF000000),
    headerEnd: Color(0xFF000000),
    previewBackground: Color(0xFF0A0A0A),
    sos: AppColors.darkSos,
    onSos: Color(0xFF1A0003),
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? card,
    Color? field,
    Color? text,
    Color? muted,
    Color? divider,
    Color? accent,
    Color? soft,
    Color? onSoft,
    Color? cta,
    Color? onCta,
    Color? onMint,
    Color? header,
    Color? headerEnd,
    Color? previewBackground,
    Color? sos,
    Color? onSos,
    Color? teal,
    Color? mint,
    Color? warm,
  }) => AppThemeColors(
    background: background ?? this.background,
    card: card ?? this.card,
    field: field ?? this.field,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    divider: divider ?? this.divider,
    accent: accent ?? this.accent,
    soft: soft ?? this.soft,
    onSoft: onSoft ?? this.onSoft,
    cta: cta ?? this.cta,
    onCta: onCta ?? this.onCta,
    onMint: onMint ?? this.onMint,
    header: header ?? this.header,
    headerEnd: headerEnd ?? this.headerEnd,
    previewBackground: previewBackground ?? this.previewBackground,
    sos: sos ?? this.sos,
    onSos: onSos ?? this.onSos,
    teal: teal ?? this.teal,
    mint: mint ?? this.mint,
    warm: warm ?? this.warm,
  );

  @override
  AppThemeColors lerp(covariant AppThemeColors? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppThemeColors(
      background: blend(background, other.background),
      card: blend(card, other.card),
      field: blend(field, other.field),
      text: blend(text, other.text),
      muted: blend(muted, other.muted),
      divider: blend(divider, other.divider),
      accent: blend(accent, other.accent),
      soft: blend(soft, other.soft),
      onSoft: blend(onSoft, other.onSoft),
      cta: blend(cta, other.cta),
      onCta: blend(onCta, other.onCta),
      onMint: blend(onMint, other.onMint),
      header: blend(header, other.header),
      headerEnd: blend(headerEnd, other.headerEnd),
      previewBackground: blend(previewBackground, other.previewBackground),
      sos: blend(sos, other.sos),
      onSos: blend(onSos, other.onSos),
      teal: blend(teal, other.teal),
      mint: blend(mint, other.mint),
      warm: blend(warm, other.warm),
    );
  }
}

/* Truy cập nhanh: context.appColors */
extension AppThemeContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppThemeColors.dark
          : AppThemeColors.light);
}
