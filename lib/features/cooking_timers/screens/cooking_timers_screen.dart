import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../kitchen/services/kitchen_services.dart';
import '../../kitchen/widgets/kitchen_page.dart';
import '../../kitchen/widgets/kitchen_entry_form.dart';
import '../services/cooking_timer_service.dart';
import '../widgets/cooking_timer_card.dart';

class CookingTimersState {
  final List<CookingTimer> items;
  final bool loading, busy;
  final String? error;
  const CookingTimersState({
    this.items = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

class CookingTimersCubit extends Cubit<CookingTimersState> {
  final CookingTimerService service;
  CookingTimersCubit(this.service) : super(const CookingTimersState()) {
    service.addListener(_refresh);
  }
  void _refresh() {
    if (!isClosed) {
      emit(
        CookingTimersState(
          items: service.items,
          loading: false,
          busy: state.busy,
        ),
      );
    }
  }

  Future<void> load() async {
    try {
      await service.load();
      _refresh();
    } catch (_) {
      if (!isClosed) {
        emit(
          const CookingTimersState(
            loading: false,
            error: 'Chưa khôi phục được hẹn giờ.',
          ),
        );
      }
    }
  }

  Future<bool> run(Future<void> Function() action) async {
    if (state.busy) return false;
    emit(CookingTimersState(items: service.items, loading: false, busy: true));
    try {
      await action();
      if (!isClosed) {
        emit(CookingTimersState(items: service.items, loading: false));
      }
      return !isClosed;
    } catch (error) {
      if (!isClosed) {
        emit(
          CookingTimersState(
            items: service.items,
            loading: false,
            error: error is FormatException
                ? error.message.toString()
                : 'Chưa lưu được hẹn giờ.',
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() async {
    service.removeListener(_refresh);
    await super.close();
  }
}

Future<bool> showCookingTimerEditor(
  BuildContext context, {
  String label = '',
  int minutes = 5,
}) async {
  final cubit = CookingTimersCubit(KitchenScope.of(context).timers);
  final title = TextEditingController(text: label),
      minute = TextEditingController(text: '$minutes'),
      second = TextEditingController(text: '0');
  final result = await showKitchenEntryForm<(String, Duration)>(
    context,
    title: 'Đặt hẹn giờ',
    fields: (_, _) => [
      kitchenInput(title, 'Tên hẹn giờ', maxLength: 160),
      kitchenInput(minute, 'Phút', number: true, maxLength: 4),
      kitchenInput(second, 'Giây', number: true, maxLength: 2),
    ],
    value: () {
      final m = int.tryParse(minute.text), s = int.tryParse(second.text);
      if (m == null ||
          s == null ||
          m < 0 ||
          s < 0 ||
          s > 59 ||
          m * 60 + s <= 0 ||
          m * 60 + s >= 86400) {
        throw const FormatException('Chọn thời gian lớn hơn 0 và dưới 24 giờ.');
      }
      return (title.text.trim(), Duration(minutes: m, seconds: s));
    },
    save: (value) => cubit.run(() => cubit.service.start(value.$1, value.$2)),
  );
  title.dispose();
  minute.dispose();
  second.dispose();
  await cubit.close();
  return result != null;
}

class CookingTimersScreen extends StatelessWidget {
  const CookingTimersScreen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => CookingTimersCubit(KitchenScope.of(context).timers)..load(),
    child: const _TimersPage(),
  );
}

class _TimersPage extends StatelessWidget {
  const _TimersPage();
  @override
  Widget build(BuildContext context) => KitchenPage(
    title: 'Hẹn giờ nấu ăn',
    onBack: () => context.canPop() ? context.pop() : context.go('/home'),
    child: BlocConsumer<CookingTimersCubit, CookingTimersState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          AppMessenger.showError(context, state.error!),
      builder: (context, state) {
        final cubit = context.read<CookingTimersCubit>();
        if (state.loading) return const AppLoadState(isLoading: true);
        return AppContentScrollView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Hẹn giờ được tính tiếp khi rời màn hình. Thông báo hết giờ hiển thị trong ứng dụng.',
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Thêm hẹn giờ',
              icon: Icons.timer_outlined,
              onPressed: state.busy
                  ? null
                  : () => showCookingTimerEditor(context),
            ),
            const SizedBox(height: 16),
            if (state.items.isEmpty)
              const Text(
                'Chưa có hẹn giờ. Bạn cũng có thể đặt từ một bước nấu.',
              ),
            for (final timer in state.items)
              CookingTimerCard(
                timer: timer,
                now: cubit.service.now(),
                busy: state.busy,
                onToggle: () {
                  cubit.run(() => cubit.service.toggle(timer.id));
                },
                onRemove: () {
                  cubit.run(() => cubit.service.remove(timer.id));
                },
              ),
            if (state.error != null)
              TextButton(
                onPressed: cubit.load,
                child: const Text('Thử khôi phục lại'),
              ),
          ],
        );
      },
    ),
  );
}
