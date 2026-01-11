import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/rss_service.dart';
import '../theme/app_theme.dart';

enum NewsMode { agenda, general }

class NewsProvider with ChangeNotifier {
  List<NewsItem> _allNews = [];
  List<NewsItem> _filteredNews = [];
  bool _isLoading = false;
  NewsMode _mode = NewsMode.agenda;
  ThemeMode _themeMode = ThemeMode.dark;
  final List<String> _logs = [];

  List<NewsItem> get news => _filteredNews;
  bool get isLoading => _isLoading;
  NewsMode get mode => _mode;
  ThemeMode get themeMode => _themeMode;
  List<String> get logs => _logs;

  Color get glassColor => _themeMode == ThemeMode.dark ? AppTheme.darkGlass : AppTheme.lightGlass;
  Color get accentColor => _themeMode == ThemeMode.dark ? AppTheme.darkAccent : AppTheme.lightAccent;

  void addLog(String message) {
    _logs.add("${DateTime.now().toIso8601String().substring(11, 19)} - $message");
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(int index) {
    _mode = index == 0 ? NewsMode.agenda : NewsMode.general;
    _filterNews();
    notifyListeners();
  }

  Future<void> fetchNews() async {
    _isLoading = true;
    _allNews = []; // Reset current news
    _filteredNews = [];
    notifyListeners();
    addLog("Fetching news started (Streamed)...");

    try {
       // 1. Fast fetch (Streamed)
       // We use a deduplication set to avoid adding duplicates during the stream
       final Set<String> processedTitles = {};
       bool firstBatchReceived = false;

       await RssService.streamFeeds(
         logger: (msg) => addLog(msg),
         onBatchReceived: (newItems) {
           List<NewsItem> uniqueBatch = [];
           for (var item in newItems) {
             String key = item.title.toLowerCase().trim();
             if (!processedTitles.contains(key)) {
               processedTitles.add(key);
               uniqueBatch.add(item);
             }
           }

           if (uniqueBatch.isNotEmpty) {
             _allNews.addAll(uniqueBatch);
             _filterNews(); // Re-sort and filter
             
             // If this is the first batch, stop loading indicator so user sees content
             if (!firstBatchReceived) {
               firstBatchReceived = true;
               _isLoading = false; 
             }
             notifyListeners();
           }
         }
       );

       addLog("Fetched ${_allNews.length} items total.");
       
       // Ensure loading is off if it wasn't already (e.g. if no batches came or all filtered)
       if (_isLoading) {
         _isLoading = false;
         notifyListeners();
       }

       // 2. Background Enrichment (Images)
       // This will update UI progressively as images are found
       RssService.enrichImages(_allNews, (msg) => addLog(msg), onUpdate: () {
          notifyListeners();
       });

    } catch (e) {
      addLog("ERROR: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterNews() {
    DateTime now = DateTime.now();
    if (_mode == NewsMode.agenda) {
      _filteredNews = _allNews.where((item) {
        return now.difference(item.dateObj).inDays <= 3 && item.score > 0;
      }).toList();
      
      _filteredNews.sort((a, b) {
        int scoreCmp = b.score.compareTo(a.score);
        if (scoreCmp != 0) return scoreCmp;
        return b.dateObj.compareTo(a.dateObj);
      });
      
      // Ensure at least one item if available (handled in UI, but list handling here)
    } else {
      _filteredNews = List.from(_allNews);
      _filteredNews.sort((a, b) => b.dateObj.compareTo(a.dateObj));
    }
  }
}
