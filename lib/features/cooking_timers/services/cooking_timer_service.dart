import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/utils/async_serial_queue.dart';
import '../../kitchen/models/kitchen_entry.dart';
import '../../kitchen/services/kitchen_local_storage.dart';

class CookingTimer {
  final String id;
  final String label;
  final String? groupId;
  final DateTime? endAt;
  final int pausedMilliseconds;
  final int durationMilliseconds;
  const CookingTimer({
    required this.id,
    required this.label,
    this.groupId,
    this.endAt,
    this.pausedMilliseconds = 0,
    this.durationMilliseconds = 0,
  });
  bool get paused => endAt == null;
  Duration remaining(DateTime now) => Duration(
    milliseconds: endAt == null
        ? pausedMilliseconds
        : max(0, endAt!.difference(now).inMilliseconds),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (groupId != null) 'groupId': groupId,
    'endAt': endAt?.toUtc().toIso8601String(),
    'pausedMilliseconds': pausedMilliseconds,
    'durationMilliseconds': durationMilliseconds,
  };
  factory CookingTimer.fromJson(Map<String, dynamic> json) => CookingTimer(
    id: kitchenKey(json['id']),
    label: kitchenText(json['label'], 160),
    groupId: json['groupId'] == null ? null : kitchenKey(json['groupId']),
    endAt: json['endAt'] == null
        ? null
        : DateTime.parse(json['endAt'] as String).toUtc(),
    pausedMilliseconds: kitchenInt(json['pausedMilliseconds'], 0, 86400000),
    durationMilliseconds: kitchenInt(
      json['durationMilliseconds'] ?? 0,
      0,
      86400000,
    ),
  );
}

class CookingTimerService extends ChangeNotifier {
  final KitchenLocalStorage storage;
  final String storageKey;
  final void Function() checkSession;
  final DateTime Function() now;
  final AsyncSerialQueue _writes = AsyncSerialQueue();
  List<CookingTimer> _items = [];
  List<CookingTimer> get items => List.unmodifiable(_items);
  Future<void>? _load;
  Timer? _ticker;
  bool _closed = false;
  CookingTimerService({
    required this.storage,
    required this.storageKey,
    required this.checkSession,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  Future<void> load() => _load ??= _read().catchError((Object error) {
    _load = null;
    throw error;
  });
  Future<void> _read() async {
    checkSession();
    final raw = await storage.read(storageKey);
    checkSession();
    if (_closed) return;
    if (raw != null) {
      _items = (jsonDecode(raw) as List)
          .map(
            (e) => CookingTimer.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_closed) notifyListeners();
    });
    notifyListeners();
  }

  Future<void> _change(List<CookingTimer> Function() change) =>
      _writes.run(() async {
        await load();
        checkSession();
        if (_closed) throw StateError('Phiên đã đóng.');
        final next = change();
        if (next.length > 8) {
          throw const FormatException('Tối đa 8 hẹn giờ cùng lúc.');
        }
        await storage.write(
          storageKey,
          jsonEncode(next.map((t) => t.toJson()).toList()),
        );
        checkSession();
        if (_closed) return;
        _items = next;
        notifyListeners();
      });
  Future<void> start(
    String label,
    Duration duration, {
    String? id,
    String? groupId,
  }) => _change(() {
    if (id != null && _items.any((timer) => timer.id == id)) return _items;
    if (duration.inMilliseconds <= 0 || duration.inHours >= 24) {
      throw const FormatException('Chọn thời gian lớn hơn 0 và dưới 24 giờ.');
    }
    return [
      ..._items,
      CookingTimer(
        id: id == null ? kitchenId() : kitchenKey(id),
        groupId: groupId == null ? null : kitchenKey(groupId),
        label: kitchenText(label, 160),
        endAt: now().toUtc().add(duration),
        durationMilliseconds: duration.inMilliseconds,
      ),
    ];
  });
  Future<void> toggle(String id) => _change(
    () => _items.map((timer) {
      if (timer.id != id) return timer;
      final remaining = timer.remaining(now());
      return timer.paused
          ? CookingTimer(
              id: id,
              label: timer.label,
              groupId: timer.groupId,
              endAt: now().toUtc().add(remaining),
              durationMilliseconds: timer.durationMilliseconds,
            )
          : CookingTimer(
              id: id,
              label: timer.label,
              groupId: timer.groupId,
              pausedMilliseconds: remaining.inMilliseconds,
              durationMilliseconds: timer.durationMilliseconds,
            );
    }).toList(),
  );
  Future<void> remove(String id) =>
      _change(() => _items.where((timer) => timer.id != id).toList());
  Future<void> removeGroup(String id) =>
      _change(() => _items.where((timer) => timer.groupId != id).toList());
  Future<void> clear() async {
    await _writes.settled;
    await storage.remove(storageKey);
    if (!_closed) {
      _items = [];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _closed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
