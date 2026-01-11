import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlVal;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/news_item.dart';
import '../utils/scorer.dart';
import '../utils/date_utils.dart';
import '../utils/string_utils.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:io';

// Placeholder check constant
const String kPlaceholderImage = "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80";



enum _FetchMethod { direct, googleCache, proxy }
enum _ProxyProvider { allorigins, codetabs, corsproxy }

class RssService {
  // Fetches feeds incrementally and calls onBatchReceived for each completed source
  static Future<List<NewsItem>> streamFeeds({
    required Function(List<NewsItem>) onBatchReceived,
    required Function(String) logger,
  }) async {
    List<Future<void>> tasks = [];
    List<NewsItem> allCollectedNews = [];

    // Deduplication map to avoid duplicates across different sources immediately
    // Note: Ideally deduplication happens in provider, but doing a basic check here helps too.
    // We will leave global deduplication to the provider/consumer.

    for (var source in AppConstants.rssSources) {
      tasks.add(fetchAndParseFeed(source, logger).then((items) {
        if (items.isNotEmpty) {
          onBatchReceived(items);
          allCollectedNews.addAll(items);
        }
      }));
    }

    // Wait for all to finish
    await Future.wait(tasks);
    
    // Fallback if empty (same logic as before)
    if (allCollectedNews.isEmpty && kIsWeb) {
      logger("Network failed. Loading MOCK DATA for demonstration.");
      List<NewsItem> mocks = _getMockNews();
      onBatchReceived(mocks);
      allCollectedNews.addAll(mocks);
    }

    return allCollectedNews;
  }

  // Deprecated: Use streamFeeds instead for better performance
  static Future<List<NewsItem>> fetchAllFeeds(Function(String) logger) async {
    List<NewsItem> allNews = [];
    await streamFeeds(
      onBatchReceived: (items) => allNews.addAll(items),
      logger: logger
    );
    
    // Legacy deduplication was here, moving logic to streamFeeds or keep simple
    Map<String, NewsItem> uniqueMap = {};
    for (var item in allNews) {
      String key = item.title.toLowerCase().trim();
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = item;
      } else {
        if (item.dateObj.isAfter(uniqueMap[key]!.dateObj)) {
          uniqueMap[key] = item;
        }
      }
    }
    return uniqueMap.values.toList();
  }


  static Future<List<NewsItem>> fetchAndParseFeed(Map<String, dynamic> source, Function(String) logger) async {
    String originalUrl = source['url'];
    
    // List of proxies to try in order
    List<String> proxyTemplates = [];
    if (kIsWeb) {
      proxyTemplates = [
        "https://api.allorigins.win/get?url=${Uri.encodeComponent(originalUrl)}", // JSON return
        "https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(originalUrl)}", // Raw return
        "https://thingproxy.freeboard.io/fetch/${originalUrl}", // Raw return
      ];
    } else {
      proxyTemplates = [originalUrl]; // Direct fetch on Native (Windows/Android/iOS)
    }

    for (String url in proxyTemplates) {
      try {
        bool isAllOrigins = url.contains("allorigins.win");
        
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) {
           String content;
           // Handle AllOrigins JSON wrapper
           if (isAllOrigins) {
              try {
                final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
                content = jsonResponse['contents'];
              } catch (e) {
                content = utf8.decode(response.bodyBytes, allowMalformed: true);
              }
           } else {
              content = utf8.decode(response.bodyBytes, allowMalformed: true);
           }

           if (content.isEmpty) throw Exception("Empty content");

           // Successful fetch, now parse
           logger("Fetched ${source['name']} successfully via ${kIsWeb ? 'proxy' : 'direct'}.");
           return _parseContent(content, source['name'], Color(source['color']), originalUrl, logger);
        }
      } catch (e) {
        // Continue to next proxy
        continue;
      }
    }

    // If all failed
    logger("Failed to fetch ${source['name']} after trying all methods.");
    return [];
  }

  static List<NewsItem> _parseContent(String content, String sourceName, Color sourceColor, String sourceUrl, Function(String) logger) {
    List<NewsItem> newsList = [];
    DateTime now = DateTime.now();

    try {
      var document = XmlDocument.parse(content);
      var items = document.findAllElements('item');
      if (items.isEmpty) {
        items = document.findAllElements('entry');
      }

      for (var node in items) {
        try {
          String title = node.findElements('title').firstOrNull?.innerText ?? "";
          String link = node.findElements('link').firstOrNull?.getAttribute("href") ?? node.findElements('link').firstOrNull?.innerText ?? "";
          if (link.isEmpty) {
             link = node.findElements('guid').firstOrNull?.innerText ?? "";
          }
          
          // CLEANUP: Remove AMP and mobile suffixes to force desktop view
          if (link.contains("?")) {
            link = link.replaceAll(RegExp(r'(\?|&)amp=1'), '');
          }
          // Some sites like Webtekno might have specific mobile URL patterns?
          // Usually standard clean link is fine.
          link = link.trim();

          String rawDesc = node.findElements('description').firstOrNull?.innerText ?? 
                             node.findElements('content:encoded').firstOrNull?.innerText ?? 
                             node.findElements('summary').firstOrNull?.innerText ?? 
                             node.findElements('content').firstOrNull?.innerText ?? 
                             "";
            
          String cleanedDesc = StringUtils.cleanAndTruncateContent(rawDesc);
          if (!Scorer.analyzeRelevance(title, cleanedDesc)) continue;
          int score = Scorer.calculateScore(title, cleanedDesc);

          String? dateStr;
          for (var tag in ['pubDate', 'pubdate', 'updated', 'dc:date', 'date']) {
             var el = node.findElements(tag).firstOrNull;
             if (el != null) {
               dateStr = el.innerText;
               break;
             }
          }

          DateTime? dtObj = DateUtilsHelper.parseRssDate(dateStr);
          if (dtObj == null) {
             dtObj = DateUtilsHelper.parseDateFromDesc(rawDesc);
          }
          
          // Future check 
          if (dtObj.isAfter(now.add(const Duration(hours: 24)))) dtObj = now;
          if (now.difference(dtObj).inDays > 180) continue;

          String image = kPlaceholderImage;
          
          // Try to extract image
          // 1. media:content or media:thumbnail
          var media = node.findElements('media:content').firstOrNull ?? node.findElements('media:thumbnail').firstOrNull;
          if (media != null) {
            image = media.getAttribute('url') ?? image;
          } else {
            // 2. enclosure
             var enclosure = node.findElements('enclosure').firstOrNull;
             if (enclosure != null && (enclosure.getAttribute('type')?.contains("image") ?? false)) {
               image = enclosure.getAttribute('url') ?? image;
             }
          }
           // 3. regex on description? StringUtils handles mainly text. 
           // Python parsed html to find img tag.
           if (image.contains("unsplash") && rawDesc.contains("<img")) {
              RegExp imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
              var match = imgRegex.firstMatch(rawDesc);
              if (match != null) {
                image = match.group(1) ?? image;
              }
           }

          newsList.add(NewsItem(
            title: title.trim(),
            description: cleanedDesc.length > 200 ? "${cleanedDesc.substring(0, 200)}..." : cleanedDesc,
            dateStr: DateUtilsHelper.cleanDateString(dtObj.toString()), // Simplified formatting
            dateObj: dtObj,
            source: sourceName,
            sourceColor: sourceColor,
            url: link,
            image: image,
            score: score
          ));

        } catch (e) {
          continue;
        }
      }
      return newsList;

    } catch (e) {
      logger("Exception processing $sourceName: $e");
      return [];
    }
  }

  static List<NewsItem> _getMockNews() {
    return [
      NewsItem(
        title: "[DEMO] Yapay Zeka Devrimi: Yeni Modeller Tanıtıldı",
        description: "Network bağlantısı sağlanamadığı için demo içerik gösteriliyor. OpenAI ve Google yeni yapay zeka modellerini duyurdu.",
        dateStr: "10 Dec 2025",
        dateObj: DateTime.now(),
        source: "Teknoloji Gündem",
        sourceColor: const Color(0xFF1E88E5),
        url: "https://google.com",
        image: "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80",
        score: 100
      ),
      NewsItem(
        title: "[DEMO] Apple'ın Yeni VR Gözlüğü Satış Rekorları Kırıyor",
        description: "Apple Vision Pro'nun yeni versiyonu piyasaya sürüldü ve stoklar tükenmek üzere.",
        dateStr: "09 Dec 2025",
        dateObj: DateTime.now().subtract(const Duration(days: 1)),
        source: "DonanımHaber",
        sourceColor: const Color(0xFFff9900),
        url: "https://donanimhaber.com",
        image: "https://images.unsplash.com/photo-1592478411213-61535fdd861d?w=800&q=80",
        score: 90
      ),
      NewsItem(
        title: "[DEMO] Tesla Yeni Otonom Sürüş Güncellemesini Yayınladı",
        description: "Elon Musk, FSD v13'ün insan sürüşünden 10 kat daha güvenli olduğunu iddia etti.",
        dateStr: "09 Dec 2025",
        dateObj: DateTime.now().subtract(const Duration(hours: 5)),
        source: "Webtekno",
        sourceColor: const Color(0xFFcc3333),
        url: "https://webtekno.com",
        image: "https://images.unsplash.com/photo-1560958089-b8a1929cea89?w=800&q=80",
        score: 85
      ),
    ];
  }

  static Future<void> enrichImages(List<NewsItem> items, Function(String) logger, {Function? onUpdate}) async {
    // Priority Queue: Sort by date to prioritize top items (just in case they aren't sorted)
    // Actually items are already sorted in provider. Just iterate sequentially.
    
    // Process in small batches (e.g., 3) to allow rapid UI updates for top items
    // If we do them all in parallel, network might choke and nothing shows for 5s.
    // Sequential or small batch is better for "Top to Bottom" feel.
    
    int batchSize = 3;
    for (int i = 0; i < items.length; i += batchSize) {
      int end = (i + batchSize < items.length) ? i + batchSize : items.length;
      List<NewsItem> batch = items.sublist(i, end);
      
      List<Future> futures = [];
      for (var item in batch) {
         if (item.image == kPlaceholderImage) {
           futures.add(_fetchArticleImage(item));
         }
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
        if (onUpdate != null) onUpdate();
      }
    }
    
    logger("All images processed.");
  }

  static Future<void> _fetchArticleImage(NewsItem item) async {
    String foundImage = await _attemptFetchPipeline(item.url);
    if (foundImage.isNotEmpty && foundImage != kPlaceholderImage) {
      item.image = foundImage;
    }
  }

  static Future<String> _attemptFetchPipeline(String targetUrl) async {
    // 1. Direct Fetch (Fastest, check first)
    // We give it a short timeout (5s) so we don't waste time if blocked.
    debugPrint("🔍 Attempting Direct Fetch for: $targetUrl");
    String? htmlBody = await _fetchBody(targetUrl, method: _FetchMethod.direct);
    String? image = _extractImageFromHtml(htmlBody, targetUrl);
    if (image != null) return image;

    // 2. Google Cache (High success rate for blocked sites)
    debugPrint("🔍 Attempting Google Cache for: $targetUrl");
    htmlBody = await _fetchBody(targetUrl, method: _FetchMethod.googleCache);
    image = _extractImageFromHtml(htmlBody, targetUrl);
    if (image != null) return image;

    // 3. Proxy Rotator (Try multiple proxies)
    // CodeTabs, AllOrigins, CorsProxy
    List<_ProxyProvider> proxies = [
      _ProxyProvider.codetabs,
      _ProxyProvider.corsproxy,
      _ProxyProvider.allorigins,
    ];

    for (var proxy in proxies) {
       debugPrint("🔍 Attempting Proxy (${proxy.name}) for: $targetUrl");
       htmlBody = await _fetchBody(targetUrl, method: _FetchMethod.proxy, proxyProvider: proxy);
       image = _extractImageFromHtml(htmlBody, targetUrl);
       if (image != null) return image;
    }

    debugPrint("❌ ALL ATTEMPTS FAILED for: $targetUrl");
    return "";
  }
  


  static Future<String?> _fetchBody(String url, {
    required _FetchMethod method, 
    _ProxyProvider? proxyProvider
  }) async {
    try {
       Map<String, String> headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
        "Referer": "https://www.google.com/",
        "Upgrade-Insecure-Requests": "1"
      };

      String finalUrl = url;
      Map<String, String>? requestHeaders = headers;
      int timeoutSeconds = 6;

      switch (method) {
        case _FetchMethod.direct:
          timeoutSeconds = 6;
          break;
        case _FetchMethod.googleCache:
          finalUrl = "http://webcache.googleusercontent.com/search?q=cache:${Uri.encodeComponent(url)}";
          timeoutSeconds = 10;
          break;
        case _FetchMethod.proxy:
          requestHeaders = null; // Proxies usually handle headers or don't want them
          timeoutSeconds = 15; // Proxies are slow
          
          switch (proxyProvider!) {
            case _ProxyProvider.allorigins:
              finalUrl = "https://api.allorigins.win/get?url=${Uri.encodeComponent(url)}";
              break;
            case _ProxyProvider.codetabs:
              finalUrl = "https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}";
              break;
            case _ProxyProvider.corsproxy:
              finalUrl = "https://corsproxy.io/?${Uri.encodeComponent(url)}";
              break;
          }
          break;
      }

      final response = await http.get(Uri.parse(finalUrl), headers: requestHeaders).timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        String content;
        // Parse AllOrigins JSON
        if (method == _FetchMethod.proxy && proxyProvider == _ProxyProvider.allorigins) {
             try {
               final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
               content = jsonResponse['contents'];
             } catch (e) { return null; }
        } else {
             // Others return raw HTML
             content = utf8.decode(response.bodyBytes, allowMalformed: true);
        }

        if (content.length < 100) return null;
        
        // Anti-bot check
        if (method == _FetchMethod.direct) {
           String lower = content.toLowerCase();
           if (lower.contains("security check") || lower.contains("bit.ly") || lower.contains("just a moment")) return null;
        }
        
        return content;
      }
    } catch (_) {
      // debugPrint("Fetch failed for $url via $method: $_");
    }
    return null;
  }

  static String? _extractImageFromHtml(String? htmlBody, String targetUrl) {
    if (htmlBody == null || htmlBody.isEmpty) return null;

    try {
      var document = htmlVal.parse(htmlBody);
      String? foundInfo;

      // 1. JSON-LD
      var scripts = document.querySelectorAll('script[type="application/ld+json"]');
      debugPrint("ℹ️ Found ${scripts.length} JSON-LD scripts for $targetUrl");
      
      for (var script in scripts) {
        try {
          var data = json.decode(script.text);
          var nodes = (data is List) ? data : (data['@graph'] as List? ?? [data]);
          for (var node in nodes) {
             var type = node['@type'];
             if (type == 'NewsArticle' || type == 'Article' || type == 'BlogPosting' || type == 'TechArticle') {
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
      
      // 3. Webtekno specific
      if (foundInfo == null && targetUrl.contains("webtekno")) {
         foundInfo = document.querySelector('.content-image')?.attributes['src'];
      }

      // 4. Heuristics
      if (foundInfo == null) {
          var container = document.querySelector('article') ?? 
                          document.querySelector('main') ?? 
                          document.querySelector('#content') ?? 
                          document.querySelector('.content') ??
                          document.body;
                          
          var images = container?.querySelectorAll('img') ?? [];
          List<Map<String, dynamic>> candidates = [];
          
          for (var img in images) {
             String? src = img.attributes['src'] ?? img.attributes['data-src'] ?? img.attributes['lazy-src'];
             if (src != null && src.length > 10 && !src.contains("logo") && !src.contains("icon") && !src.contains("avatar")) {
                int width = int.tryParse(img.attributes['width'] ?? "0") ?? 0;
                int height = int.tryParse(img.attributes['height'] ?? "0") ?? 0;
                if (width > 0 && width < 200) continue;
                candidates.add({"src": src, "area": width * height, "index": candidates.length});
             }
          }
          
          debugPrint("ℹ️ Heuristics found ${candidates.length} candidate images for $targetUrl");
          
          if (candidates.isNotEmpty) {
            candidates.sort((a, b) {
               int areaCmp = b['area'].compareTo(a['area']);
               if (areaCmp != 0) return areaCmp;
               return a['index'].compareTo(b['index']);
            });
            foundInfo = candidates.first['src'];
          }
      }

      if (foundInfo != null && foundInfo.isNotEmpty) {
         try {
           // Robust URL resolution using Uri.resolve
           // This handles /path, path, ../path, //domain.com, and full URLs automatically.
           Uri base = Uri.parse(targetUrl);
           Uri resolved = base.resolve(foundInfo);
           String finalUrl = resolved.toString();
           
           if (finalUrl.startsWith("http")) {
             debugPrint("✅ IMAGE FOUND: $finalUrl (Source: $targetUrl)");
             return finalUrl;
           }
         } catch (e) {
           debugPrint("❌ URL RESOLVE ERROR: $e");
         }
      }
    } catch (_) {}
    return null;
  }
}
