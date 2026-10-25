import 'package:app_bep_xinh/core/widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_bep_xinh/core/router/app_router.dart';
import 'package:app_bep_xinh/core/utils/app_layout.dart';
import 'package:app_bep_xinh/core/widgets/app_app_bar.dart';
import 'package:app_bep_xinh/core/widgets/app_messenger.dart';
import 'package:app_bep_xinh/features/recipes/services/recipe_favorites_service.dart';

import '../cubits/recipe_search_cubit.dart';
import '../models/recipe_search_request.dart';
import '../services/recipe_search_service.dart';
import '../widgets/recipe_search_filters.dart';
import '../widgets/recipe_search_input.dart';
import '../widgets/recipe_search_results.dart';
import '../widgets/recipe_search_intro.dart';

class RecipeSearchScreen extends StatelessWidget {
  final RecipeSearchRequest initialRequest;
  const RecipeSearchScreen({
    super.key,
    this.initialRequest = const RecipeSearchRequest(),
  });
  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(initialRequest),
    create: (context) => RecipeSearchCubit(
      service: context.read<RecipeSearchService>(),
      favorites: context.read<RecipeFavoritesService>(),
      initialRequest: initialRequest,
    )..load(),
    child: const AppFeatureTheme(child: _RecipeSearchPage()),
  );
}

class _RecipeSearchPage extends StatelessWidget {
  const _RecipeSearchPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppAppBar(
      title: 'Tìm món ngon',
      onBack: () {
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
            child: const Column(
              children: [
                RecipeSearchIntro(),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: RecipeSearchInput(),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RecipeSearchFilters(),
                  ),
                ),
                Expanded(child: RecipeSearchResults()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
