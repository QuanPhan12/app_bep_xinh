import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KitchenLocalStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Chỉ lưu cache có thể tải lại và timer; không lưu token hoặc ghi chú riêng.
class PreferencesKitchenStorage implements KitchenLocalStorage {
  final SharedPreferencesAsync preferences;
  PreferencesKitchenStorage([SharedPreferencesAsync? preferences])
    : preferences = preferences ?? SharedPreferencesAsync();
  @override
  Future<String?> read(String key) => preferences.getString(key);
  @override
  Future<void> write(String key, String value) =>
      preferences.setString(key, value);
  @override
  Future<void> remove(String key) => preferences.remove(key);
}
