import 'package:equatable/equatable.dart';
import '../../data/home_mock_data.dart';
import '../../models/recipe_item.dart';

enum HomeStatus { initial, loading, success, failure }

/// State quản lý dữ liệu Trang chủ & Khám phá
class HomeState extends Equatable {
  final HomeStatus status;
  final String selectedCategory;
  final List<RecipeItem> recipes;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.selectedCategory = 'all',
    this.recipes = HomeMockData.trendingRecipes,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? selectedCategory,
    List<RecipeItem>? recipes,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      recipes: recipes ?? this.recipes,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedCategory,
        recipes,
        errorMessage,
      ];
}
