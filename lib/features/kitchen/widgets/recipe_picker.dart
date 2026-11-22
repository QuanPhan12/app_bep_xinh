import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_adaptive_sheet.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/app_load_state.dart';
import '../../home/models/recipe_item.dart';
import '../../recipe_detail/models/recipe_detail.dart';
import '../../recipe_search/models/recipe_search_request.dart';
import '../services/kitchen_services.dart';

class RecipePickerState {
  final List<RecipeItem> items;
  final bool loading, busy;
  final String? error;
  const RecipePickerState({
    this.items = const [],
    this.loading = true,
    this.busy = false,
    this.error,
  });
}

class RecipePickerCubit extends Cubit<RecipePickerState> {
  final KitchenServices services;
  Timer? _debounce;
  int _revision = 0;
  RecipePickerCubit(this.services) : super(const RecipePickerState());
  void search(String query) {
    _debounce?.cancel();
    final revision = ++_revision;
    emit(const RecipePickerState());
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final items = await services.search.search(
          RecipeSearchRequest(query: query),
        );
        if (!isClosed && revision == _revision) {
          emit(RecipePickerState(items: items, loading: false));
        }
      } catch (_) {
        if (!isClosed && revision == _revision) {
          emit(
            const RecipePickerState(
              loading: false,
              error: 'Chưa tìm được món. Thử lại nhé.',
            ),
          );
        }
      }
    });
  }

  Future<RecipeDetail?> select(RecipeItem item) async {
    if (state.busy) return null;
    emit(RecipePickerState(items: state.items, loading: false, busy: true));
    try {
      return (await services.details.fetchRecipe(item.id)).recipe;
    } catch (_) {
      if (!isClosed) {
        emit(
          RecipePickerState(
            items: state.items,
            loading: false,
            error: 'Món không còn khả dụng hoặc chưa tải được.',
          ),
        );
      }
      return null;
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await super.close();
  }
}

Future<RecipeDetail?> showKitchenRecipePicker(BuildContext context) {
  final services = KitchenScope.of(context);
  return showAppAdaptiveSheet<RecipeDetail>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => RecipePickerCubit(services)..search(''),
      child: const _RecipePicker(),
    ),
  );
}

class _RecipePicker extends StatelessWidget {
  const _RecipePicker();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: (constraints.maxHeight - MediaQuery.viewInsetsOf(context).bottom)
          .clamp(0, 620),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Chọn công thức')),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            AppSearchBar(
              hintText: 'Tìm tên món hoặc nguyên liệu',
              onChanged: context.read<RecipePickerCubit>().search,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<RecipePickerCubit, RecipePickerState>(
                builder: (context, state) {
                  if (state.loading) return const AppLoadState(isLoading: true);
                  if (state.error != null) {
                    return AppLoadState(
                      message: state.error,
                      onRetry: () =>
                          context.read<RecipePickerCubit>().search(''),
                    );
                  }
                  if (state.items.isEmpty) {
                    return const AppLoadState(message: 'Chưa có món phù hợp.');
                  }
                  return ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text('${item.cookTimeMinutes} phút'),
                        trailing: const Icon(Icons.chevron_right),
                        enabled: !state.busy,
                        onTap: () async {
                          final recipe = await context
                              .read<RecipePickerCubit>()
                              .select(item);
                          if (context.mounted && recipe != null) {
                            Navigator.of(context).pop(recipe);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
