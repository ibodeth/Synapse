import 'package:intl/intl.dart';

class NewsItem {
  final String title;
  final String desc;
  final DateTime dateObj;
  final String source;
  final String sourceColor;
  final String url;
  final String image;
  final int score;

  NewsItem({
    required this.title,
    required this.desc,
    required this.dateObj,
    required this.source,
    required this.sourceColor,
    required this.url,
    required this.image,
    required this.score,
  });

  String get dateStr {
    return DateFormat("d MMMM, HH:mm", 'tr_TR').format(dateObj);
  }
}
