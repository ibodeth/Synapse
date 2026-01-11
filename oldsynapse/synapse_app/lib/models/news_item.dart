import 'package:flutter/material.dart';

class NewsItem {
  final String title;
  final String description;
  final String dateStr;
  final DateTime dateObj;
  final String source;
  final Color sourceColor;
  final String url;
  String image;
  final int score;

  NewsItem({
    required this.title,
    required this.description,
    required this.dateStr,
    required this.dateObj,
    required this.source,
    required this.sourceColor,
    required this.url,
    required this.image,
    required this.score,
  });
}
