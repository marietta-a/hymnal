import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/data/hymn_data.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:provider/provider.dart';

class FontSettingsScreen extends StatelessWidget {
  const FontSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Font Settings'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
      ),
      body: Consumer<FontProvider>(
        builder: (context, fontProvider, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _sectionLabel(context, 'Header & Title Text'),
              _settingsCard(context, [
                _fontSizeSlider(
                  context,
                  label: 'Text Size',
                  value: fontProvider.headerFontSize,
                  onChanged: fontProvider.setHeaderFontSize,
                ),
                _divider(),
                _fontDropdown(
                  context,
                  label: 'Text Style',
                  currentFamily: fontProvider.headerFontFamily,
                  onChanged: (f) => fontProvider.setHeaderFontFamily(f!),
                ),
              ]),

              _sectionLabel(context, 'Lyrics Text'),
              _settingsCard(context, [
                _fontSizeSlider(
                  context,
                  label: 'Text Size',
                  value: fontProvider.lyricsFontSize,
                  onChanged: fontProvider.setLyricsFontSize,
                ),
                _divider(),
                _fontDropdown(
                  context,
                  label: 'Text Style',
                  currentFamily: fontProvider.lyricsFontFamily,
                  onChanged: (f) => fontProvider.setLyricsFontFamily(f!),
                ),
              ]),

              _sectionLabel(context, 'Preview'),
              _settingsCard(context, [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hymn ${hymnJson[0]['number']} — ${hymnJson[0]['title']}',
                        style: GoogleFonts.getFont(
                          fontProvider.headerFontFamily,
                          fontSize: fontProvider.headerFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (hymnJson[0]['lyrics'] as String).split('\n\n').first,
                        style: GoogleFonts.getFont(
                          fontProvider.lyricsFontFamily,
                          fontSize: fontProvider.lyricsFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 16);

  Widget _fontSizeSlider(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: 12.0,
              max: 32.0,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fontDropdown(
    BuildContext context, {
    required String label,
    required String currentFamily,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: DropdownButtonFormField<String>(
        initialValue: currentFamily,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        items: FontProvider.availableFontFamilies.map((String family) {
          return DropdownMenuItem<String>(
            value: family,
            child: Text(family, style: GoogleFonts.getFont(family, fontSize: 15)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
