// lib/screens/hymn_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:provider/provider.dart';

class HymnDetailScreen extends StatelessWidget {
  final Hymn hymn;

  const HymnDetailScreen({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${hymn.number}. ${hymn.title}'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, child) {
              final isFav = favoritesProvider.isFavorite(hymn.number);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
                onPressed: () {
                  favoritesProvider.toggleFavorite(hymn.number);
                },
              );
            },
          ),
        ],
      ),
      // Use a Stack to layer the composer on top of the lyrics.
      body: Stack(
        children: [
          // --- Layer 1: The scrollable lyrics ---
          SingleChildScrollView(
            // We increase the bottom padding to prevent the composer
            // text from overlapping the last line of the lyrics.
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
            child: SelectableText(
              hymn.lyrics,
              style: GoogleFonts.lato(fontSize: 18.0, height: 1.5),
            ),
          ),

          // --- Layer 2: The composer, docked at the bottom right ---
          // This only builds the widget if the composer exists.
          if (hymn.composer != null && hymn.composer!.isNotEmpty)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '- ${hymn.composer!}', // The composer's name
                  style: GoogleFonts.lato(
                    fontSize: 14.0,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}