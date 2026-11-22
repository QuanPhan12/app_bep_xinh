import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../../sollume/shared/app_text_field.dart' as sollume;
import '../../messages/widgets/chat_recipe_card.dart';
import '../cubits/ai_chat_cubit.dart';
import '../widgets/ai_chat_entry.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});
  @override
  Widget build(BuildContext context) => const _AiChatPage();
}

class _AiChatPage extends StatefulWidget {
  const _AiChatPage();
  @override
  State<_AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<_AiChatPage> {
  final scroll = ScrollController();
  final input = TextEditingController();
  AiChatCubit? bound;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cubit = context.watch<AiChatCubit>();
    if (identical(bound, cubit)) return;
    bound = cubit;
    input.text = cubit.state.draft;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cubit.ensureLoaded();
      _bottom();
    });
  }

  @override
  void dispose() {
    scroll.dispose();
    input.dispose();
    super.dispose();
  }

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });
  @override
  Widget build(BuildContext context) => BlocConsumer<AiChatCubit, AiChatState>(
    listenWhen: (a, b) => a.messages != b.messages || a.sending != b.sending,
    listener: (context, state) {
      if (!state.sending && state.draft.isEmpty) input.clear();
      if (state.messages.isNotEmpty || state.sending) _bottom();
    },
    builder: (context, state) {
      final cubit = context.read<AiChatCubit>(),
          colors = Theme.of(context).colorScheme;
      return AppPageScaffold(
        appBar: AppSliverAppBar(
          title: 'Bếp Xinh AI',
          onBackPressed: () =>
              context.canPop() ? context.pop() : context.go('/messages'),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Expanded(
                    child: state.loading
                        ? const AppLoadState(isLoading: true)
                        : state.loadFailed
                        ? AppLoadState(
                            message: state.error,
                            onRetry: cubit.load,
                          )
                        : ListView(
                            controller: scroll,
                            padding: const EdgeInsets.all(16),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            children: [
                              if (state.messages.isEmpty) ...[
                                const SizedBox(height: 24),
                                const Center(
                                  child: AppAvatar(
                                    name: 'Bếp Xinh AI',
                                    assetPath: aiAvatarAsset,
                                    size: 88,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Hôm nay mình nấu gì?',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Hỏi về món ăn, nguyên liệu hoặc cách dùng Bếp Xinh. Tin nhắn trong cuộc trò chuyện này được gửi tới dịch vụ AI do quản trị viên cấu hình.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                for (final question in [
                                  'Gợi ý món dễ nấu trong 30 phút',
                                  'Tôi có trứng và cà chua, nấu món gì?',
                                  'Làm sao lưu món vào thực đơn?',
                                ])
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton(
                                      onPressed: state.sending
                                          ? null
                                          : () {
                                              input.text = question;
                                              cubit.change(question);
                                            },
                                      child: Text(question),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                              ],
                              for (final message in state.messages)
                                Align(
                                  alignment: message.fromAi
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    constraints: const BoxConstraints(
                                      maxWidth: 580,
                                    ),
                                    decoration: BoxDecoration(
                                      color: message.fromAi
                                          ? colors.surfaceContainerLow
                                          : colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (message.fromAi) ...[
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              AppAvatar(
                                                name: 'Bếp Xinh AI',
                                                assetPath: aiAvatarAsset,
                                                size: 26,
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Bếp Xinh AI',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                        SelectableText(
                                          message.text,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(height: 1.6),
                                        ),
                                        for (final recipe in message.recipes)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            child: ChatRecipeCard(
                                              recipe: recipe,
                                              onTap: () {
                                                context.push(
                                                  '/recipe/${Uri.encodeComponent(recipe.id)}',
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (state.sending) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(state.draft),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Bếp Xinh AI đang trả lời…',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  if (state.error != null && !state.loadFailed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: sollume.AppTextField(
                                controller: input,
                                hintText: 'Hỏi Bếp Xinh AI…',
                                enabled:
                                    !state.sending &&
                                    !state.loading &&
                                    !state.loadFailed,
                                minLines: 1,
                                maxLines: 4,
                                // Tách bộ đếm khỏi field để nút gửi không căn theo dòng đếm.
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(2000),
                                ],
                                onChanged: cubit.change,
                                textInputAction: TextInputAction.newline,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: 'Gửi cho AI',
                              onPressed:
                                  state.sending ||
                                      state.loading ||
                                      state.loadFailed ||
                                      state.draft.trim().isEmpty
                                  ? null
                                  : cubit.send,
                              icon: const Icon(
                                PhosphorIconsRegular.paperPlaneTilt,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.draft.characters.length}/2000',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
