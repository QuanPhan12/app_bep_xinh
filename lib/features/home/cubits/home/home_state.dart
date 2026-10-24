import 'package:equatable/equatable.dart';

import '../../models/home_data.dart';
import '../../models/recipe_item.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final HomeData? data;
  final String selectedCategory;
  final Set<String> savingFavorites;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.data,
    this.selectedCategory = 'all',
    this.savingFavorites = const {},
    this.errorMessage,
  });

  List<RecipeItem> get recipes => data?.recipes ?? const [];
  bool get hasContent => data != null && !data!.isEmpty;

  HomeState copyWith({
    HomeStatus? status,
    HomeData? data,
    String? selectedCategory,
    Set<String>? savingFavorites,
    String? errorMessage,
  }) => HomeState(
    status: status ?? this.status,
    data: data ?? this.data,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    savingFavorites: savingFavorites == null
        ? this.savingFavorites
        : Set.unmodifiable(savingFavorites),
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    data,
    selectedCategory,
    savingFavorites,
    errorMessage,
  ];
}
