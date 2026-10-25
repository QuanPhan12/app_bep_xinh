import '../cubits/recipe_editor/recipe_editor_state.dart';

export 'package:app_bep_xinh/features/recipes/presentation/recipe_labels.dart';

extension RecipeEditorStepLabel on RecipeEditorStep {
  String get label => switch (this) {
    RecipeEditorStep.details => 'Thông tin',
    RecipeEditorStep.ingredients => 'Nguyên liệu',
    RecipeEditorStep.instructions => 'Cách nấu',
    RecipeEditorStep.review => 'Xem trước',
  };

  String get title => switch (this) {
    RecipeEditorStep.details => 'Chia sẻ món ngon của bạn',
    RecipeEditorStep.ingredients => 'Nguyên liệu & định lượng',
    RecipeEditorStep.instructions => 'Các bước chế biến',
    RecipeEditorStep.review => 'Sẵn sàng chia sẻ món ngon?',
  };

  String get description => switch (this) {
    RecipeEditorStep.details =>
      'Bắt đầu bằng một bức ảnh đẹp và câu chuyện về món ăn.',
    RecipeEditorStep.ingredients =>
      'Chia nguyên liệu thành từng nhóm để mọi người dễ chuẩn bị.',
    RecipeEditorStep.instructions =>
      'Viết từng bước rõ ràng, thêm thời gian và ảnh minh họa nếu có.',
    RecipeEditorStep.review =>
      'Kiểm tra công thức trước khi gửi đến Bếp Xinh duyệt.',
  };
}
