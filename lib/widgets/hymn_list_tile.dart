// lib/widgets/hymn_list_tile.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/models/hymn.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:hymnal/screens/hymn_detail_screen.dart';
import 'package:provider/provider.dart';

class HymnListTile extends StatelessWidget {
  final Hymn hymn;

  const HymnListTile({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    

    final fontProvider = Provider.of<FontProvider>(context);
    
    return ListTile(
      leading: Text(
        hymn.number.toString(),
        style:  GoogleFonts.getFont(
          fontProvider.lyricsFontFamily,
          fontSize: fontProvider.lyricsFontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        hymn.title,
        style: GoogleFonts.getFont(
          fontProvider.lyricsFontFamily,
          fontSize: fontProvider.lyricsFontSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
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