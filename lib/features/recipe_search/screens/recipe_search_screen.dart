import 'package:app_bep_xinh/core/widgets/app_sliver_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_page_scaffold.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/recipe_search_cubit.dart';
import '../models/recipe_search_request.dart';
import '../services/recipe_search_service.dart';
import '../services/search_history_repository.dart';
import '../../recipes/widgets/recipe_discovery_theme.dart';
import '../widgets/recipe_search_filters.dart';
import '../widgets/recipe_search_input.dart';
import '../widgets/recipe_search_results.dart';
import '../widgets/recipe_search_history.dart';

class RecipeSearchScreen extends StatelessWidget {
  final RecipeSearchRequest initialRequest;
  const RecipeSearchScreen({
    super.key,
    this.initialRequest = const RecipeSearchRequest(),
  });
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(initialRequest),
    create: (context) {
      SearchHistoryRepository? history;
      try {
        history = context.read<SearchHistoryRepository>();
      } catch (_) {
        /* Test/preview dùng lịch sử trong phiên. */
      }
      return RecipeSearchCubit(
          service: context.read<RecipeSearchService>(),
          favorites: context.read<RecipeFavoritesService>(),
          initialRequest: initialRequest,
          history: history,
        )
        ..loadHistory()
        ..load();
    },
    child: const RecipeDiscoveryTheme(
      child: AppFeatureTheme(child: _RecipeSearchPage()),
    ),
  );
}

class _RecipeSearchPage extends StatelessWidget {
  const _RecipeSearchPage();
  @override
  Widget build(BuildContext context) => AppPageScaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppSliverAppBar(
      title: 'Tìm món ngon',
      onBackPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(PathRouter.homeScreen);
        }
      },
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppLayout.pageWidth(context)),
          child: BlocListener<RecipeSearchCubit, RecipeSearchState>(
            listenWhen: (a, b) => a.noticeId != b.noticeId,
            listener: (context, state) {
              if (state.message != null) {
                AppMessenger.showError(context, state.message!);
              }
            },
            // Một vùng cuộn cho cả bộ lọc và kết quả để bàn phím trên tablet
            // ngang không ép phần kết quả xuống chiều cao âm.
            child: const RecipeSearchResults(
              headerSlivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: RecipeSearchInput(),
                  ),
                ),
                SliverToBoxAdapter(child: RecipeSearchHistory()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RecipeSearchFilters(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
