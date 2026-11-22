import '../../recipes/models/recipe_image.dart';

enum RecipeSubmissionStatus { pending, approved, rejected, hidden, deleted }

enum RecipeVisibilityAction { hide, restore, delete }

class RecipeSubmission {
  final String id;
  final String title;
  final RecipeImage cover;
  final RecipeSubmissionStatus status;
  final DateTime submittedAt;
  final String? reviewReason;
  final String? visibilityRole;
  final String? visibilityReason;
  final String? visibilityEventId;
  const RecipeSubmission({
    required this.id,
    required this.title,
    required this.cover,
    required this.status,
    required this.submittedAt,
    this.reviewReason,
    this.visibilityRole,
    this.visibilityReason,
    this.visibilityEventId,
  });

  factory RecipeSubmission.fromJson(String id, Map<String, dynamic> data) {
    if (data['id'] != id ||
        data['content'] is! Map<String, dynamic> ||
        data['submittedAt'] is! DateTime) {
      throw const FormatException('Invalid submission');
    }
    final content = data['content'] as Map<String, dynamic>;
    return RecipeSubmission(
      id: id,
      title: content['title'] as String,
      cover: RecipeImage.fromJson(content['cover'] as Map<String, dynamic>),
      status: RecipeSubmissionStatus.values.byName(data['status'] as String),
      submittedAt: (data['submittedAt'] as DateTime).toUtc(),
      reviewReason: data['reviewReason'] as String?,
      visibilityRole: data['visibilityRole'] as String?,
      visibilityReason: data['visibilityReason'] as String?,
      visibilityEventId: data['visibilityEventId'] as String?,
    );
  }
}
