import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/notifications/cubits/notifications_cubit.dart';
import 'package:app_bep_xinh/features/notifications/models/inbox_notification.dart';
import 'package:app_bep_xinh/features/messages/cubits/messages_cubit.dart';
import 'package:app_bep_xinh/features/messages/cubits/conversation_cubit.dart';
import 'package:app_bep_xinh/features/messages/cubits/recipients_cubit.dart';

import '../../support/communication_fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('image preview, remove, upload failure and send retry preserve draft without reupload', () async {
    final repository = FakeMessageRepository();
    final images = FakeChatImageService();
    final cubit = ConversationCubit(
      id: repository.thread.id,
      repository: repository,
      images: images,
    );
    await cubit.load();
    await flush();
    await cubit.pickImage();
    expect(cubit.state.image, images.selection);
    expect(cubit.state.canSend, true);
    expect(images.uploads, 0);
    cubit.removeImage();
    expect(cubit.state.image, isNull);
    expect(cubit.state.canSend, false);
    await cubit.pickImage();
    cubit.changeDraft('Lời nhắn kèm ảnh');
    images.onUpload = () => Future.error(StateError('upload offline'));
    await cubit.send();
    expect(cubit.state.image, isNotNull);
    expect(cubit.state.draft, 'Lời nhắn kèm ảnh');
    expect(repository.requestIds, isEmpty);
    images.onUpload = null;
    repository.onSend = () => Future.error(StateError('write offline'));
    await cubit.send();
    expect(images.uploads, 2);
    expect(cubit.state.canSend, true);
    repository.onSend = null;
    await cubit.send();
    await flush();
    expect(images.uploads, 2);
    expect(repository.requestIds.first, repository.requestIds.last);
    expect(cubit.state.image, isNull);
    expect(cubit.state.draft, '');
    expect(repository.thread.messages.last.image, FakeChatImageService.remote);
    await cubit.close();
    await repository.dispose();
  });

  test('cancel image selection retains prior image and late upload does not send after close', () async {
    final repository = FakeMessageRepository();
    final images = FakeChatImageService();
    final cubit = ConversationCubit(
      id: repository.thread.id,
      repository: repository,
      images: images,
    );
    await cubit.load();
    await flush();
    await cubit.pickImage();
    final selected = cubit.state.image;
    images.selection = null;
    await cubit.pickImage();
    expect(cubit.state.image, selected);
    final upload = Completer<void>();
    images.onUpload = () => upload.future;
    final sending = cubit.send();
    await cubit.send();
    expect(images.uploads, 1);
    await cubit.close();
    upload.complete();
    await sending;
    expect(repository.requestIds, isEmpty);
    await repository.dispose();
  });
  test(
    'notification realtime, read filter, late notification and recovery',
    () async {
      final repository = FakeNotificationRepository();
      final cubit = NotificationsCubit(repository);
      await cubit.load();
      await flush();
      expect(cubit.state.unreadCount, 1);
      cubit.filterUnread(true);
      final pending = Completer<void>();
      repository.onMark = () => pending.future;
      final marking = cubit.markRead(null);
      repository.publish([
        ...repository.items,
        const InboxNotification(
          id: 'new',
          title: 'Mới',
          body: 'Thông báo mới',
          timeLabel: '10:00',
          kind: NotificationKind.recipe,
        ),
      ]);
      await flush();
      pending.complete();
      await marking;
      await flush();
      expect(cubit.state.visibleItems.map((item) => item.id), ['new']);
      repository.changes.addError(StateError('offline'));
      await flush();
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.items.length, 2);
      repository.publish(repository.items);
      await flush();
      expect(cubit.state.error, isNull);
      await cubit.close();
      expect(repository.cancellations, 1);
      await repository.dispose();
    },
  );

  test('failed read retains unread state and allows retry', () async {
    final repository = FakeNotificationRepository();
    final cubit = NotificationsCubit(repository);
    await cubit.load();
    await flush();
    repository.onMark = () => Future.error(StateError('offline'));
    await cubit.markRead('n1');
    expect(cubit.state.unreadCount, 1);
    expect(cubit.state.updating, false);
    repository.onMark = null;
    await cubit.markRead('n1');
    await flush();
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
    await repository.dispose();
  });

  test(
    'inbox search and filter survive realtime updates and reconnect',
    () async {
      final repository = FakeMessageRepository();
      final cubit = MessagesCubit(repository);
      await cubit.load();
      await flush();
      cubit.search('mai');
      cubit.filterUnread(true);
      expect(cubit.state.visibleItems.length, 1);
      repository.inboxChanges.add([repository.thread.copyWith(unreadCount: 0)]);
      await flush();
      expect(cubit.state.visibleItems, isEmpty);
      repository.inboxChanges.addError(StateError('offline'));
      await flush();
      expect(cubit.state.items.length, 1);
      await cubit.load();
      await flush();
      expect(cubit.state.query, 'mai');
      expect(cubit.state.unreadOnly, true);
      expect(repository.cancellations, 1);
      await cubit.close();
      await repository.dispose();
    },
  );

  test(
    'sending deduplicates taps and retries same request without losing draft',
    () async {
      final repository = FakeMessageRepository();
      final cubit = ConversationCubit(
        id: repository.thread.id,
        repository: repository,
      );
      await cubit.load();
      await flush();
      cubit.changeDraft('   ');
      await cubit.send();
      expect(repository.requestIds, isEmpty);
      cubit.changeDraft('  Xin chào  ');
      final pending = Completer<void>();
      repository.onSend = () => pending.future;
      final sending = cubit.send();
      await cubit.send();
      cubit.changeDraft('Không ghi đè khi đang gửi');
      expect(cubit.state.draft, '  Xin chào  ');
      pending.completeError(StateError('offline'));
      await sending;
      expect(cubit.state.draft, '  Xin chào  ');
      expect(cubit.state.sending, false);
      repository.onSend = null;
      await cubit.send();
      await flush();
      expect(repository.requestIds.length, 2);
      expect(repository.requestIds.first, repository.requestIds.last);
      expect(cubit.state.draft, '');
      expect(
        cubit.state.conversation!.messages
            .where((m) => m.text == 'Xin chào')
            .length,
        1,
      );
      await cubit.close();
      await repository.dispose();
    },
  );

  test('closing conversation ignores late send completion', () async {
    final repository = FakeMessageRepository();
    final cubit = ConversationCubit(
      id: repository.thread.id,
      repository: repository,
    );
    await cubit.load();
    await flush();
    cubit.changeDraft('Tin đang gửi');
    final pending = Completer<void>();
    repository.onSend = () => pending.future;
    final sending = cubit.send();
    await cubit.close();
    pending.complete();
    await sending;
    expect(cubit.isClosed, true);
    await repository.dispose();
  });

  test(
    'recipient search and real conversation creation return destination',
    () async {
      final repository = FakeMessageRepository();
      final cubit = RecipientsCubit(repository);
      await cubit.load();
      cubit.search('không có');
      expect(cubit.state.visibleItems, isEmpty);
      cubit.search('Mai');
      expect(
        await cubit.start(cubit.state.visibleItems.single),
        repository.thread.id,
      );
      await cubit.close();
      await repository.dispose();
    },
  );
}
