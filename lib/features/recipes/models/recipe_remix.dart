import 'package:equatable/equatable.dart';

import '../../../core/services/json_reader.dart';

/// Nguồn là snapshot của công thức công khai; không thay tác giả của bản đăng mới.
class RecipeRemix extends Equatable {
  const RecipeRemix({
    required this.recipeId,
    required this.title,
    required this.authorId,
    required this.authorName,
    required this.sourceHash,
    this.changes = '',
  });
  final String recipeId, title, authorId, authorName, sourceHash, changes;
  RecipeRemix withChanges(String value) => RecipeRemix(
    recipeId: recipeId,
    title: title,
    authorId: authorId,
    authorName: authorName,
    sourceHash: sourceHash,
    changes: value,
  );
  factory RecipeRemix.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    final value = RecipeRemix(
      recipeId: r.string('recipeId'),
      title: r.string('title'),
      authorId: r.string('authorId'),
      authorName: r.string('authorName'),
      sourceHash: r.string('sourceHash'),
      changes: r.string('changes', allowEmpty: true),
    );
    if (!RegExp(r'^r_[A-Za-z0-9_-]{1,62}$').hasMatch(value.recipeId) ||
        value.title.length > 80 ||
        value.authorId.length > 128 ||
        value.authorName.length > 60 ||
        value.changes.length > 500 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(value.sourceHash)) {
      throw const FormatException('Invalid remix source');
    }
    return value;
  }
  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'title': title,
    'authorId': authorId,
    'authorName': authorName,
    'sourceHash': sourceHash,
    'changes': changes,
  };
  @override
  List<Object?> get props => [
    recipeId,
    title,
    authorId,
    authorName,
    sourceHash,
    changes,
  ];
}
