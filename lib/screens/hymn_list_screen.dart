import 'package:flutter/material.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/widgets/hymn_list_tile.dart';
import 'package:collection/collection.dart' show groupBy;

class HymnListScreen extends StatelessWidget {
  // Assume you get your full list of hymns from a provider or database.
  final List<Hymn> allHymns;

  const HymnListScreen({super.key, required this.allHymns, required List<Hymn> hymns});

  @override
  Widget build(BuildContext context) {
    // --- 1. Group the hymns by category ---
    final groupedHymns = groupBy(allHymns, (Hymn hymn) => hymn.category);

    // --- 2. Flatten the map into a single list for the ListView.builder ---
    // This is the most efficient way to build the list. We create a single
    // list containing both category strings and Hymn objects.
    final List<dynamic> displayList = [];
    groupedHymns.forEach((category, hymns) {
      displayList.add(category); // Add the category header text
      displayList.addAll(hymns); // Add all the hymns for that category
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hymns'),
      ),
      body: ListView.builder(
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final item = displayList[index];

          // --- 3. Build the appropriate widget based on the item's type ---
          if (item is String) {
            // If the item is a String, it's a category header.
            return _buildCategoryHeader(item);
          } else if (item is Hymn) {
            // If the item is a Hymn, it's a hymn tile.
            return HymnListTile(hymn: item);
          }
          // Failsafe, should not happen.
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// A helper widget to build the styled category headers.
  Widget _buildCategoryHeader(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey.shade200, // A subtle background color for the header
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}