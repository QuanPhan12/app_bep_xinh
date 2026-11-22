import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_bep_xinh/features/messages/cubits/conversation_cubit.dart';
import 'package:app_bep_xinh/features/messages/cubits/chat_recipes_cubit.dart';
import 'package:app_bep_xinh/features/messages/models/chat_recipe.dart';

import '../../support/communication_fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  test('recipe-only send retains payload on failure and reuses request ID without upload', () async {
    final repository = FakeMessageRepository(), images = FakeChatImageService();
    final cubit = ConversationCubit(
      id: repository.thread.id,
      repository: repository,
      images: images,
    );
    await cubit.load();
    await flush();
    final recipe = repository.recipeOptions.first;
    expect(ChatRecipe.fromJson(recipe.toJson()), recipe);
    await cubit.pickRecipe(() async => recipe);
    expect(cubit.state.canSend, true);
    repository.onSend = () => Future.error(StateError('offline'));
    await cubit.send();
    expect(cubit.state.recipe, recipe);
    expect(cubit.state.error, isNotNull);
    final requestId = repository.requestIds.single;
    await cubit.pickRecipe(() async => null);
    repository.onSend = null;
    await cubit.send();
    await flush();
    expect(repository.requestIds.last, requestId);
    expect(repository.thread.messages.last.recipe, recipe);
    expect(repository.thread.messages.last.text, '');
    expect(cubit.state.recipe, isNull);
    expect(images.uploads, 0);
    await cubit.close();
    await repository.dispose();
  });
  test(
    'caption survives switching attachments and canceling selection',
    () async {
      final repository = FakeMessageRepository(),
          images = FakeChatImageService();
      final cubit = ConversationCubit(
        id: repository.thread.id,
        repository: repository,
        images: images,
      );
      await cubit.load();
      await flush();
      cubit.changeDraft('Nấu món này nhé');
      await cubit.pickImage();
      final image = cubit.state.image;
      await cubit.pickRecipe(() async => null);
      expect(cubit.state.image, image);
      await cubit.pickRecipe(() async => repository.recipeOptions.first);
      expect(cubit.state.image, isNull);
      expect(cubit.state.recipe, isNotNull);
      images.selection = null;
      await cubit.pickImage();
      expect(cubit.state.recipe, isNotNull);
      expect(cubit.state.draft, 'Nấu món này nhé');
      cubit.removeRecipe();
      expect(cubit.state.recipe, isNull);
      expect(cubit.state.draft, 'Nấu món này nhé');
      await cubit.close();
      await repository.dispose();
    },
  );
  test(
    'different recipe resets retry ID and caption can accompany recipe',
    () async {
      final repository = FakeMessageRepository();
      final cubit = ConversationCubit(
        id: repository.thread.id,
        repository: repository,
      );
      await cubit.load();
      await flush();
      final first = repository.recipeOptions.first;
      await cubit.pickRecipe(() async => first);
      repository.onSend = () => Future.error(StateError('offline'));
      await cubit.send();
      final oldId = repository.requestIds.single;
      await cubit.pickRecipe(
        () async =>
            ChatRecipe(id: 'r_other', title: 'Món khác', cover: first.cover),
      );
      cubit.changeDraft('Thử món này');
      repository.onSend = null;
      await cubit.send();
      await flush();
      expect(repository.requestIds.last, isNot(oldId));
      expect(repository.thread.messages.last.recipe!.id, 'r_other');
      expect(repository.thread.messages.last.text, 'Thử món này');
      expect(cubit.state.draft, '');
      await cubit.close();
      await repository.dispose();
    },
  );
  test(
    'picking blocks sends and late result cannot update a closed conversation',
    () async {
      final repository = FakeMessageRepository();
      final cubit = ConversationCubit(
        id: repository.thread.id,
        repository: repository,
      );
      await cubit.load();
      await flush();
      cubit.changeDraft('Lời nhắn');
      final pending = Completer<ChatRecipe?>();
      final selection = cubit.pickRecipe(() => pending.future);
      expect(cubit.state.canSend, false);
      await cubit.send();
      expect(repository.requestIds, isEmpty);
      await cubit.close();
      pending.complete(repository.recipeOptions.first);
      await selection;
      expect(repository.requestIds, isEmpty);
      await repository.dispose();
    },
  );
  test('picker searches without accents and retries after failure', () async {
    final repository = FakeMessageRepository();
    repository.onRecipes = () => Future.error(StateError('offline'));
    final cubit = ChatRecipesCubit(repository);
    await cubit.load();
    expect(cubit.state.error, isNotNull);
    cubit.search('TRUNG CHIEN');
    repository.onRecipes = null;
    await cubit.load();
    expect(cubit.state.visible.single.title, 'Trứng chiên hành');
    expect(cubit.state.error, isNull);
    cubit.search('không có');
    expect(cubit.state.visible, isEmpty);
    await cubit.close();
    await repository.dispose();
  });
  test('malformed recipe IDs and device-only covers are rejected', () async {
    final repo = FakeMessageRepository();
    final recipe = repo.recipeOptions.first;
    expect(
      () => ChatRecipe.fromJson({...recipe.toJson(), 'id': '../private'}),
      throwsFormatException,
    );
    expect(
      () => ChatRecipe.fromJson({
        ...recipe.toJson(),
        'cover': {'id': 'local', 'name': 'local', 'assetPath': 'local.png'},
      }),
      throwsFormatException,
    );
    await repo.dispose();
  });
}
