import 'package:equatable/equatable.dart';
import 'package:app_bep_xinh/core/services/json_reader.dart';

class HomeCategory extends Equatable {
  final String id;
  final String title;
  final String icon;

  const HomeCategory({
    required this.id,
    required this.title,
    required this.icon,
  });

  factory HomeCategory.fromJson(Map<String, dynamic> json) => HomeCategory(
    id: JsonReader(json).string('id'),
    title: JsonReader(json).string('title'),
    icon: JsonReader(json).string('icon', fallback: 'default'),
  );

  @override
  List<Object> get props => [id, title, icon];
}
