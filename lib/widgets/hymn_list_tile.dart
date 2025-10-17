// lib/widgets/hymn_list_tile.dart
import 'package:flutter/material.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/screens/hymn_detail_screen.dart';

class HymnListTile extends StatelessWidget {
  final Hymn hymn;

  const HymnListTile({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        hymn.number.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(hymn.title),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HymnDetailScreen(hymn: hymn),
          ),
        );
      },
    );
  }
}