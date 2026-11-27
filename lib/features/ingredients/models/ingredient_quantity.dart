import 'ingredient_catalog.dart';

/// Giỏ cũ lưu chuỗi đã định dạng; đọc lại vẫn trình bày nhất quán mà không sửa dữ liệu.
String formatWholeStoredIngredientQuantity(String text) {
  final match = RegExp(r'^([0-9]+(?:[.,][0-9]+)?(?:[eE][+-]?[0-9]+)?)\s+(.+)$')
      .firstMatch(text);
  if (match == null) return text;
  var amount = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (amount == null || !amount.isFinite) return text;
  var unit = match.group(2)!;
  if (unit == 'kg' || unit == 'l') {
    amount *= 1000;
    unit = unit == 'kg' ? 'g' : 'ml';
  }
  return '${formatIngredientQuantity(amount: amount, wholeNumbers: true)} $unit';
}

String formatIngredientQuantity({
  double? amount,
  IngredientUnit? unit,
  bool toTaste = false,
  double ratio = 1,
  bool wholeNumbers = false,
}) {
  if (toTaste) return 'Vừa đủ';
  if (amount == null || !amount.isFinite) return '';
  var value = amount * ratio;
  if (!value.isFinite) return '';
  if (wholeNumbers) {
    final rounded = value.round();
    final text = rounded == 0 && value > 0 ? '<1' : '$rounded';
    return '$text ${unit?.label ?? ''}'.trim();
  }
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
