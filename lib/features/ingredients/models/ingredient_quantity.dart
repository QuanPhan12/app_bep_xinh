import 'ingredient_catalog.dart';

String formatIngredientQuantity({
  double? amount,
  IngredientUnit? unit,
  bool toTaste = false,
  double ratio = 1,
}) {
  if (toTaste) return 'Vừa đủ';
  if (amount == null || !amount.isFinite) return '';
  var value = amount * ratio;
  if (!value.isFinite) return '';
  // Giữ nguyên số đã nhập. Chỉ làm gọn sai số khi tính lại khẩu phần;
  // lượng rất nhỏ vẫn phải hiển thị khác 0.
  if (ratio != 1) {
    final rounded = double.parse(value.toStringAsFixed(3));
    value = rounded == 0 && value != 0
        ? double.parse(value.toStringAsPrecision(3))
        : rounded;
  }
  final text = value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
  return '${text.replaceAll('.', ',')} ${unit?.label ?? ''}'.trim();
}
