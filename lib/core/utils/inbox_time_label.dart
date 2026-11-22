/// Nhãn thời gian lấy từ dữ liệu thật; không giả lập trạng thái online.
String inboxTimeLabel(DateTime? value) {
  if (value == null) return 'Đang đồng bộ';
  final local = value.toLocal();
  final now = DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) {
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
  if (today.difference(day).inDays == 1) return 'Hôm qua';
  return '${local.day}/${local.month}/${local.year}';
}
