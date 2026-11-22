/*
 * AppRadius định nghĩa các hằng số bán kính bo góc (border radius)
 * chuẩn cho toàn bộ giao diện của ứng dụng Sollume.
 */
abstract final class AppRadius {
  /* Bo góc nhỏ (8.0) - Dùng cho các badge, thẻ phụ, nhãn nhỏ */
  static const small = 8.0;

  /* Bo góc ô nhập liệu (10.0) - Dùng cho TextField, input, snackbar */
  static const field = 10.0;

  static const button = 10.0;
  static const search = 12.0;
  static const media = 12.0;

  /* Bo góc thẻ chuẩn (12.0) - Dùng cho các Card, container thông tin chính */
  static const card = 12.0;

  /* Bo góc lớn (20.0) - Dùng cho hộp thoại Dialog, pop-up */
  static const large = 20.0;

  /* Bo góc thanh điều hướng (24.0) - Dùng cho Navigation bar, banner */
  static const navigation = 24.0;

  /* Bo góc bảng kéo đáy (28.0) - Dùng cho viền đỉnh của Bottom Sheet */
  static const sheet = 28.0;

  /* Bo góc dạng viên thuốc (999.0) - Bo tròn tuyệt đối cho chip, button pill, indicator */
  static const pill = 999.0;
}
