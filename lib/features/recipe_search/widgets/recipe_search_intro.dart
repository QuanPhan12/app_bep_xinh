import 'package:app_bep_xinh/core/constants/app_assets.dart';
import 'package:app_bep_xinh/core/widgets/app_feature_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/recipe_search_cubit.dart';

class RecipeSearchIntro extends StatelessWidget {
  const RecipeSearchIntro({super.key});
  @override
  Widget build(BuildContext context) {
    final hasQuery = context.select(
      (RecipeSearchCubit cubit) => cubit.state.request.query.isNotEmpty,
    );
    if (hasQuery || MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AppFeatureHeader(
        eyebrow: 'CẢM HỨNG CHO BỮA ĂN',
        title: 'Hôm nay, mình nấu gì?',
        description:
            'Một món quen, một hương vị mới. Tìm công thức hợp với bạn.',
        imageAsset: AppAssets.dishSaladGa,
      ),
    );
  }
}
