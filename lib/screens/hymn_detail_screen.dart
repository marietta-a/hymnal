// lib/screens/hymn_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/favorites_provider.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HymnDetailScreen extends StatelessWidget {
  final Hymn hymn;

  const HymnDetailScreen({super.key, required this.hymn});

  bool get hasYouTubeLink {
    return hymn.src != null && hymn.src!.isNotEmpty;
  }

  Future<void> _launchYouTube(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FontProvider>(
      builder: (context, fontProvider, child) {
        return Scaffold(
          appBar: AppBar(
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
          body: Stack(
            children: [
              // --- Layer 1: The scrollable lyrics ---
              SingleChildScrollView(
                // Increased bottom padding to ensure text doesn't hide behind the footer row
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: SelectableText(
                  hymn.lyrics,
                  style: GoogleFonts.getFont(
                    fontProvider.lyricsFontFamily,
                    fontSize: fontProvider.lyricsFontSize,
                    height: 1.5,
                  ),
                ),
              ),

              // --- Layer 2: Bottom Row (YouTube Button & Composer) ---
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  // Optional: adds a slight gradient or solid background to make the row readable over text
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.0),
                        Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT: Small YouTube Button
                      if (hasYouTubeLink)
                        TextButton.icon(
                          onPressed: () => _launchYouTube(context, hymn.src!),
                          icon: const Icon(
                            Icons.play_circle_fill,
                            size: 30,
                            color: Color(0xFFFF0000), // YouTube Red
                          ),
                          label: const Text(
                            "Play",
                            style: TextStyle(
                              color: Color(0xFFFF0000),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // RIGHT: Composer
                      if (hymn.composer != null && hymn.composer!.isNotEmpty)
                        Expanded(
                          child: Text(
                            '- ${hymn.composer!}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.getFont(
                              fontProvider.lyricsFontFamily,
                              fontSize: fontProvider.lyricsFontSize - 4,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                    ],
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