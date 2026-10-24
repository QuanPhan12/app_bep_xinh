import 'package:app_bep_xinh/core/constants/app_assets.dart';
import '../models/recipe_item.dart';

class HomeMockData {
  const HomeMockData._();

  static const List<RecipeItem> trendingRecipes = [
    RecipeItem(
      id: 'bo_ne_tieu_den',
      title: 'Bò né sốt tiêu đen bánh mì',
      image: AppAssets.dishBoNe,
      rating: 4.9,
      cookTimeMinutes: 20,
      tag: 'Dễ làm',
      difficulty: 'Dễ làm',
      calories: 450,
      isFavorite: false,
    ),
    RecipeItem(
      id: 'salad_uc_ga_me_rang',
      title: 'Salad ức gà sốt mè rang',
      image: AppAssets.dishSaladGa,
      rating: 4.8,
      cookTimeMinutes: 15,
      tag: 'Eat Clean',
      difficulty: 'Dễ làm',
      calories: 280,
      isFavorite: true,
    ),
    RecipeItem(
      id: 'ca_hoi_ap_chao',
      title: 'Cá hồi áp chảo bơ tỏi',
      image: AppAssets.dishCaHoi,
      rating: 5.0,
      cookTimeMinutes: 25,
      tag: 'Nhanh gọn',
      difficulty: 'Trung bình',
      calories: 390,
      isFavorite: false,
    ),
    RecipeItem(
      id: 'canh_kim_chi_thit_heo',
      title: 'Canh kim chi thịt heo đậu hũ',
      image: AppAssets.dishCanhKimChi,
      rating: 4.9,
      cookTimeMinutes: 30,
      tag: 'Đậm đà',
      difficulty: 'Dễ làm',
      calories: 320,
      isFavorite: false,
    ),
  ];
}
