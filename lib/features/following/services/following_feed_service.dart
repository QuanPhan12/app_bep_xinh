import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/async_serial_queue.dart';

import '../../home/models/recipe_item.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../recipes/services/published_recipe_source.dart';

abstract interface class FollowingFeedService {
  Future<List<RecipeItem>> next(
    List<FollowedAuthor> authors, {
    bool reset = false,
  });
  bool get hasMore;
}

class FirestoreFollowingFeedService implements FollowingFeedService {
  final PublishedRecipeSource source;
  final List<List<String>> _groups = [];
  final List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _buffers = [];
  final Map<int, DocumentSnapshot<Map<String, dynamic>>> _cursors = {};
  final Set<int> _ended = {};
  String _key = '';
  final _queue = AsyncSerialQueue();
  FirestoreFollowingFeedService(this.source);
  @override
  bool get hasMore =>
      _buffers.any((b) => b.isNotEmpty) || _ended.length < _groups.length;
  Future<void> _fill(int group) async {
    if (_ended.contains(group) || _buffers[group].isNotEmpty) return;
    var query = source.firestore
        .collection('recipes')
        .where('status', isEqualTo: 'approved')
        .where('authorId', whereIn: _groups[group])
        .orderBy('submittedAt', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(10);
    if (_cursors[group] != null) {
      query = query.startAfterDocument(_cursors[group]!);
    }
    final page = await query.get(const GetOptions(source: Source.server));
    _buffers[group].addAll(page.docs);
    if (page.docs.isNotEmpty) _cursors[group] = page.docs.last;
    if (page.docs.length < 10) _ended.add(group);
  }

  int _compare(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final order = (b.data()['submittedAt'] as Timestamp).compareTo(
      a.data()['submittedAt'] as Timestamp,
    );
    return order != 0 ? order : b.id.compareTo(a.id);
  }

  @override
  Future<List<RecipeItem>> next(
    List<FollowedAuthor> authors, {
    bool reset = false,
  }) => _queue.run(() async {
    final groups = _groups.map((g) => [...g]).toList();
    final buffers = _buffers.map((b) => [...b]).toList();
    final cursors = {..._cursors}, ended = {..._ended};
    final oldKey = _key;
    try {
      return await _next(authors, reset: reset);
    } catch (_) {
      // Khôi phục cursor để lỗi mạng giữa trang không làm mất món chưa trả cho UI.
      _groups
        ..clear()
        ..addAll(groups);
      _buffers
        ..clear()
        ..addAll(buffers);
      _cursors
        ..clear()
        ..addAll(cursors);
      _ended
        ..clear()
        ..addAll(ended);
      _key = oldKey;
      rethrow;
    }
  });
  Future<List<RecipeItem>> _next(
    List<FollowedAuthor> authors, {
    bool reset = false,
  }) async {
    if (authors.length > 50) {
      throw const FormatException('Bản đầu hỗ trợ tối đa 50 tác giả theo dõi.');
    }
    final ids = authors.map((a) => a.id).toSet().toList()..sort();
    final key = ids.join('|');
    if (reset || key != _key) {
      _key = key;
      _groups.clear();
      _buffers.clear();
      _cursors.clear();
      _ended.clear();
      for (var i = 0; i < ids.length; i += 10) {
        _groups.add(ids.sublist(i, (i + 10).clamp(0, ids.length)));
        _buffers.add([]);
      }
    }
    final result = <RecipeItem>[];
    while (result.length < 20) {
      await Future.wait(List.generate(_groups.length, _fill));
      int? best;
      for (var i = 0; i < _groups.length; i++) {
        if (_buffers[i].isEmpty) continue;
        if (best == null ||
            _compare(_buffers[i].first, _buffers[best].first) < 0) {
          best = i;
        }
      }
      if (best == null) break;
      result.add(
        RecipeItem.fromRecipeJson(
          source.decodeApproved(_buffers[best].removeAt(0)),
          isFavorite: false,
        ),
      );
    }
    return result;
  }
}
