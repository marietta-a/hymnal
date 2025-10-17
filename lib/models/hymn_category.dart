// Assumes the JSON data is in a separate file for cleanliness.
// You could also place the 'hymnCategoriesJson' constant directly in this file if you prefer.
import 'package:hymnal/data/hymn_categories_data.dart';

class HymnCategory {
  final String category;
  final List<int> hymns;

  const HymnCategory({
    required this.category,
    required this.hymns,
  });

  /// Creates a [HymnCategory] instance from a JSON map.
  factory HymnCategory.fromJson(Map<String, dynamic> json) {
    // The 'hymns' field in the JSON is a List<dynamic>, so it needs to be cast to List<int>.
    var hymnsFromJson = json['hymns'] as List;
    List<int> hymnList = hymnsFromJson.map((hymn) => hymn as int).toList();

    return HymnCategory(
      category: json['category'],
      hymns: hymnList,
    );
  }

  /// A static list of all hymn categories, loaded from the JSON data.
  static List<HymnCategory> categories = List<HymnCategory>.from(
      (hymnCategoriesJson).map((item) => HymnCategory.fromJson(item)));
}