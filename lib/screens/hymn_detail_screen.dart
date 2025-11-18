// lib/screens/hymn_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/font_provider.dart'; // Import FontProvider
import 'package:provider/provider.dart';

class HymnDetailScreen extends StatelessWidget {
  final Hymn hymn;

  const HymnDetailScreen({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to get the latest font settings and rebuild when they change
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        return Scaffold(
          appBar: AppBar(
            // Apply header font to the AppBar title
            title: Text(
              '${hymn.number}. ${hymn.title}',
              style: GoogleFonts.getFont(
                fontProvider.headerFontFamily,
                fontSize: fontProvider.headerFontSize,
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
          // Use a Stack to layer the composer on top of the lyrics
          body: Stack(
            children: [
              // --- Layer 1: The scrollable lyrics ---
              SingleChildScrollView(
                // Add bottom padding to prevent composer from overlapping the last line
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 60.0),
                child: SelectableText(
                  hymn.lyrics,
                  // Apply dynamic lyrics font from the provider
                  style: GoogleFonts.getFont(
                    fontProvider.lyricsFontFamily,
                    fontSize: fontProvider.lyricsFontSize,
                    height: 1.5,
                  ),
                ),
              ),

              // --- Layer 2: The composer, docked at the bottom right ---
              if (hymn.composer != null && hymn.composer!.isNotEmpty)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '- ${hymn.composer!}',
                      // Use lyrics font family for consistency, but smaller and italic
                      style: GoogleFonts.getFont(
                        fontProvider.lyricsFontFamily,
                        fontSize: fontProvider.lyricsFontSize - 4,
                        fontStyle: FontStyle.italic,
                        // This color adapts to both light and dark themes
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}