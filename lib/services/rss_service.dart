import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/news_item.dart';
import '../utils/scorer.dart';
import '../utils/date_utils.dart';
import '../utils/string_utils.dart';
import 'parser_isolate.dart';

// Placeholder check constant
const String kPlaceholderImage = "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80";

enum _FetchMethod { direct, googleCache, proxy }
enum _ProxyProvider { allorigins, codetabs, corsproxy }

class RssService {
  
  // Fetches feeds incrementally and calls onBatchReceived for each completed source
  Future<List<NewsItem>> streamFeeds({
    required Function(List<NewsItem>) onBatchReceived,
  }) async {
    List<Future<void>> tasks = [];
    List<NewsItem> allCollectedNews = [];

    for (var source in AppConstants.rssSources) {
      if (source["isHtml"] == "true") {
        tasks.add(_fetchAndParseHtml(source).then((items) {
          if (items.isNotEmpty) {
            onBatchReceived(items);
            allCollectedNews.addAll(items);
          }
        }));
      } else {
        tasks.add(_fetchAndParseFeed(source).then((items) {
          if (items.isNotEmpty) {
            onBatchReceived(items);
            allCollectedNews.addAll(items);
          }
        }));
      }
    }

    await Future.wait(tasks);
    
    // Fallback if empty
    if (allCollectedNews.isEmpty) {
       // Return some error or empty state handled by UI
    }

    return allCollectedNews;
  }

  // Backwards compatibility for now, but should ideally use streamFeeds
  Future<List<NewsItem>> fetchAllFeeds() async {
    List<NewsItem> allItems = [];
    await streamFeeds(onBatchReceived: (items) {
      allItems.addAll(items);
    });
    return _deduplicateItems(allItems);
  }

  Future<List<NewsItem>> _fetchAndParseFeed(Map<String, String> source) async {
    String originalUrl = source['url']!;
    
    // ... (Proxy logic hidden for brevity, assume fetch returns `content`) ...
    // Note: Since I am replacing the whole function, I need to keep the fetch logic.
    // I will just show the modified part where I call compute.

    List<String> proxyTemplates = [];
    if (kIsWeb) {
      proxyTemplates = [
        "https://api.allorigins.win/get?url=${Uri.encodeComponent(originalUrl)}", // JSON return
        "https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}", // Raw return
        "https://thingproxy.freeboard.io/fetch/${originalUrl}", // Raw return
      ];
    } else {
      proxyTemplates = [originalUrl];
    }

    for (String url in proxyTemplates) {
      try {
        bool isAllOrigins = url.contains("allorigins.win");
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
           String content;
           if (isAllOrigins) {
              try {
                final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
                content = jsonResponse['contents'];
              } catch (e) {
                content = utf8.decode(response.bodyBytes, allowMalformed: true);
              }
           } else {
              try {
                content = utf8.decode(response.bodyBytes);
              } catch (e) {
                 try {
                    content = latin1.decode(response.bodyBytes);
                 } catch (_) {
                    content = response.body; 
                 }
              }
           }

           if (content.isEmpty) throw Exception("Empty content");

           // Offload parsing to Isolate
           return await compute(parseFeedIsolate, {
             'content': content,
             'sourceName': source['name'],
             'sourceColor': source['color'],
             'sourceUrl': originalUrl
           });
        }
      } catch (e) {
        continue;
      }
    }
    return [];
  }

  Future<List<NewsItem>> _fetchAndParseHtml(Map<String, String> source) async {
    try {
      final response = await http.get(Uri.parse(source["url"]!), headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
      }).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) return [];
      
      // Offload HTML parsing to Isolate
      return await compute(parseHtmlIsolate, {
        'content': response.body,
        'sourceName': source['name'],
        'sourceColor': source['color'],
        'sourceUrl': source['url']
      });
      
    } catch (e) {
      return [];
    }
  }

  // ROBUST IMAGE FETCHING (Ported from oldsynapse)
  Future<String> _attemptFetchPipeline(String targetUrl) async {
    // 1. Direct Fetch
    String? htmlBody = await _fetchBody(targetUrl, method: _FetchMethod.direct);
    String? image = _extractImageFromHtml(htmlBody, targetUrl);
    if (image != null) return image;

    // 2. Google Cache
    htmlBody = await _fetchBody(targetUrl, method: _FetchMethod.googleCache);
    image = _extractImageFromHtml(htmlBody, targetUrl);
    if (image != null) return image;

    // 3. Proxy Rotator (Only used if strictly necessary, can be slow)
    // Skipping for now to keep speed, or limit to one proxy?
    return "";
  }

  Future<String?> _fetchBody(String url, {required _FetchMethod method}) async {
    try {
       Map<String, String> headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      };

      String finalUrl = url;
      int timeoutSeconds = 6;

      switch (method) {
        case _FetchMethod.direct:
          timeoutSeconds = 6;
          break;
        case _FetchMethod.googleCache:
          finalUrl = "http://webcache.googleusercontent.com/search?q=cache:${Uri.encodeComponent(url)}";
          timeoutSeconds = 8;
          break;
        default:
          break;
      }

      final response = await http.get(Uri.parse(finalUrl), headers: headers).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    } catch (_) {}
    return null;
  }

  String? _extractImageFromHtml(String? htmlBody, String targetUrl) {
    if (htmlBody == null || htmlBody.isEmpty) return null;

    try {
      var document = html_parser.parse(htmlBody);
      String? foundInfo;

      // 1. JSON-LD
      var scripts = document.querySelectorAll('script[type="application/ld+json"]');
      for (var script in scripts) {
        try {
          var data = json.decode(script.text);
          var nodes = (data is List) ? data : (data['@graph'] as List? ?? [data]);
          for (var node in nodes) {
             var type = node['@type'];
             if (type == 'NewsArticle' || type == 'Article' || type == 'BlogPosting') {
                var img = node['image'];
                if (img is String) foundInfo = img;
                else if (img is Map && img['url'] is String) foundInfo = img['url'];
                else if (img is List && img.isNotEmpty) {
                   if (img[0] is String) foundInfo = img[0];
                   else if (img[0] is Map) foundInfo = img[0]['url'];
                }
                if (foundInfo != null) break;
             }
          }
        } catch (_) {}
        if (foundInfo != null) break;
      }

      // 2. Meta tags
      if (foundInfo == null) {
        foundInfo = document.querySelector('meta[property="og:image"]')?.attributes['content'];
      }
      if (foundInfo == null) {
        foundInfo = document.querySelector('meta[name="twitter:image"]')?.attributes['content'];
      }
      if (foundInfo == null) {
        foundInfo = document.querySelector('link[rel="image_src"]')?.attributes['href'];
      }
      
      if (foundInfo != null && foundInfo.isNotEmpty) {
         try {
           Uri base = Uri.parse(targetUrl);
           Uri resolved = base.resolve(foundInfo);
           return resolved.toString();
         } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  List<NewsItem> _deduplicateItems(List<NewsItem> items) {
     final Map<String, NewsItem> uniqueMap = {};
     
     for (var item in items) {
       String key = item.title.toLowerCase().substring(0, item.title.length > 40 ? 40 : item.title.length);
       if (!uniqueMap.containsKey(key)) {
         uniqueMap[key] = item;
       } else {
         if (item.dateObj.isAfter(uniqueMap[key]!.dateObj)) {
           uniqueMap[key] = item;
         }
       }
     }
     
     var result = uniqueMap.values.toList();
     result.sort((a, b) => b.dateObj.compareTo(a.dateObj));
     return result;
  }
}
