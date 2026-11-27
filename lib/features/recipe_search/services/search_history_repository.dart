import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/async_serial_queue.dart';
import '../../../core/utils/search_utils.dart';

abstract interface class SearchHistoryRepository {
  Future<List<String>> read();
  Future<List<String>> remember(String query);
  Future<void> clear();
}

List<String> _normalize(Iterable<String> queries) {
  final seen = <String>{};
  return queries
      .map((query) => query.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where(
        (query) =>
            query.isNotEmpty &&
            query.length <= 120 &&
            seen.add(searchKey(query)),
      )
      .take(8)
      .toList(growable: false);
}

class MemorySearchHistoryRepository implements SearchHistoryRepository {
  List<String> _queries = [];
  @override
  Future<List<String>> read() async => List.unmodifiable(_queries);
  @override
  Future<List<String>> remember(String query) async {
    _queries = _normalize([query, ..._queries]);
    return read();
  }

  @override
  Future<void> clear() async {
    _queries = [];
  }
}

class LocalSearchHistoryRepository implements SearchHistoryRepository {
  // Mỗi UID có namespace riêng; khách không thấy lịch sử của tài khoản vừa đăng xuất.
  LocalSearchHistoryRepository.forUser(String? uid)
    : storageKey =
          'recipe-search-v1-${sha256.convert(utf8.encode(uid == null ? 'guest' : 'user:$uid'))}';
  final String storageKey;
  final _writes = AsyncSerialQueue();

  @override
  Future<List<String>> read() async {
    await _writes.settled;
    final preferences = await SharedPreferences.getInstance();
    return _normalize(preferences.getStringList(storageKey) ?? []);
  }

  @override
  Future<List<String>> remember(String query) => _writes.run(() async {
    final preferences = await SharedPreferences.getInstance();
    final next = _normalize([
      query,
      ...preferences.getStringList(storageKey) ?? [],
    ]);
    if (!await preferences.setStringList(storageKey, next)) {
      throw StateError('History write failed');
    }
    return next;
  });

  @override
  Future<void> clear() => _writes.run(() async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.remove(storageKey)) {
      throw StateError('History removal failed');
    }
  });
}
