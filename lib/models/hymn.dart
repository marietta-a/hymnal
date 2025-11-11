// lib/models/hymn.dart
import 'package:hymnal/data/hymn_data.dart';

class Hymn {
  final int number;
  final String title;
  final String lyrics;
  final String? category;
  final String? firstLine;
  final String? composer;
  final String? src;

  Hymn({
    required this.number,
    required this.title,
    required this.lyrics,
    this.firstLine,
    this.composer,
    this.category,
    this.src
  });

  
  factory Hymn.fromJson(Map<String, dynamic> json){
    try{
      return Hymn(
        number: json['number'], 
        title: json['title'], 
        lyrics: json['lyrics'],
        firstLine: json['firstLine'],
        composer: json['composer'],
        category: json['category'],
      );
    }
    catch(err){
      rethrow;
    }
  }

  static List<Hymn> hymns = List<Hymn>.from((hymnJson).map((item) => Hymn.fromJson(item)));
}