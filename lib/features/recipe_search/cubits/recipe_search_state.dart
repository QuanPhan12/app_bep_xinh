import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/features/home/models/recipe_item.dart';

import '../models/recipe_search_request.dart';

enum RecipeSearchStatus { initial, loading, ready, failure }

class RecipeSearchState extends Equatable {
  final RecipeSearchRequest request;
  final RecipeSearchStatus status;
  final List<RecipeItem> recipes;
  final Set<String> savingFavorites;
  final String? message;
  final int noticeId;
  final List<String> recentQueries;
  RecipeSearchState({
    this.request = const RecipeSearchRequest(),
    this.status = RecipeSearchStatus.initial,
    List<RecipeItem> recipes = const [],
    Set<String> savingFavorites = const {},
    this.message,
    this.noticeId = 0,
    List<String> recentQueries = const [],
  }) : recentQueries = List.unmodifiable(recentQueries),
       recipes = List.unmodifiable(recipes),
       savingFavorites = Set.unmodifiable(savingFavorites);

  RecipeSearchState copyWith({
    RecipeSearchRequest? request,
    RecipeSearchStatus? status,
    List<RecipeItem>? recipes,
    Set<String>? savingFavorites,
    String? message,
    int? noticeId,
    List<String>? recentQueries,
  }) => RecipeSearchState(
    request: request ?? this.request,
    status: status ?? this.status,
    recipes: recipes ?? this.recipes,
    savingFavorites: savingFavorites ?? this.savingFavorites,
    message: message,
    noticeId: noticeId ?? this.noticeId,
    recentQueries: recentQueries ?? this.recentQueries,
  );

  @override
  List<Object?> get props => [
    request,
    status,
    recipes,
    savingFavorites,
    message,
    noticeId,
    recentQueries,
  ];
}
