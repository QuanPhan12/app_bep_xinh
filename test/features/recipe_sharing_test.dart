import 'package:app_bep_xinh/features/recipe_sharing/services/recipe_sharing_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('web handoff is recorded while cancellation and unknown native results are not', () {
    expect(
      recordsShareResult(ShareResultStatus.unavailable, web: true),
      isTrue,
    );
    expect(
      recordsShareResult(ShareResultStatus.unavailable, web: false),
      isFalse,
    );
    expect(recordsShareResult(ShareResultStatus.dismissed, web: true), isFalse);
  });
  test('only a successful share sheet selection records a share', () async {
    final recorded = <String>[];
    for (final status in ShareResultStatus.values) {
      final service = RecipeSharingService(
        record: (id, channel) async => recorded.add('$id:$channel'),
        shareSheet: (_) async => ShareResult('', status),
      );
      await service.share('r_dish', const Rect.fromLTWH(0, 0, 1, 1));
    }
    expect(recorded, ['r_dish:sheet']);
  });
  test(
    'copy records after clipboard success; stats failure does not fail sharing',
    () async {
      final recorded = <String>[];
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final service = RecipeSharingService(
        record: (id, channel) async {
          recorded.add('$id:$channel');
          throw StateError('offline');
        },
      );
      await service.copy('r_dish');
      await Future<void>.delayed(Duration.zero);
      expect(copied, 'https://bepxinh-b0be7.web.app/recipe/r_dish');
      expect(recorded, ['r_dish:copy']);
    },
  );
}
