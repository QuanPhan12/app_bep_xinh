/// Chuẩn hóa tiếng Việt để tìm cả khi nhập không dấu.
String searchKey(String value) {
  var result = value.toLowerCase().trim();
  const accents = [
    'àáạảãâầấậẩẫăằắặẳẵ',
    'èéẹẻẽêềếệểễ',
    'ìíịỉĩ',
    'òóọỏõôồốộổỗơờớợởỡ',
    'ùúụủũưừứựửữ',
    'ỳýỵỷỹ',
    'đ',
  ];
  const replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
  for (var i = 0; i < accents.length; i++) {
    for (final character in accents[i].split('')) {
      result = result.replaceAll(character, replacements[i]);
    }
  }
  return result;
}
