// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hymnal/providers/font_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<FontProvider>(
        builder: (context, fontProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionHeader(context, 'Header & Title Font'),
              _buildFontSizeSlider(
                context,
                'Font Size: ${fontProvider.headerFontSize.toStringAsFixed(1)}',
                fontProvider.headerFontSize,
                (value) => fontProvider.setHeaderFontSize(value),
              ),
              _buildFontFamilyDropdown(
                context,
                'Font Family',
                fontProvider.headerFontFamily,
                (family) => fontProvider.setHeaderFontFamily(family!),
                fontProvider.headerFontSize, // For preview
              ),
              const Divider(height: 40),
              _buildSectionHeader(context, 'Lyrics Font'),
              _buildFontSizeSlider(
                context,
                'Font Size: ${fontProvider.lyricsFontSize.toStringAsFixed(1)}',
                fontProvider.lyricsFontSize,
                (value) => fontProvider.setLyricsFontSize(value),
              ),
              _buildFontFamilyDropdown(
                context,
                'Font Family',
                fontProvider.lyricsFontFamily,
                (family) => fontProvider.setLyricsFontFamily(family!),
                fontProvider.lyricsFontSize, // For preview
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(
    BuildContext context,
    String label,
    double currentValue,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: currentValue,
          min: 12.0,
          max: 32.0,
          divisions: 20,
          label: currentValue.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFontFamilyDropdown(
    BuildContext context,
    String label,
    String currentFamily,
    ValueChanged<String?> onChanged,
    double previewFontSize,
  ) {
    return DropdownButtonFormField<String>(
      value: currentFamily,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: FontProvider.availableFontFamilies.map((String family) {
        return DropdownMenuItem<String>(
          value: family,
          child: Text(
            family,
            style: GoogleFonts.getFont(family, fontSize: previewFontSize),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}