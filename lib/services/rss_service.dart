
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/news_item.dart';

class RssService {
  
  // User-Agent'ı Mobil Android olarak güncelledik.
  // Çoğu site masaüstü user-agent ile gelen mobil istekleri bot sanıp engelleyebilir.
  static Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
    'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
  };

  final Map<String, String> _trMonths = {
    "Oca": "Jan", "Şub": "Feb", "Mar": "Mar", "Nis": "Apr", "May": "May", "Haz": "Jun",
    "Tem": "Jul", "Ağu": "Aug", "Eyl": "Sep", "Eki": "Oct", "Kas": "Nov", "Ara": "Dec",
    "Pzt": "Mon", "Sal": "Tue", "Çar": "Wed", "Per": "Thu", "Cum": "Fri", "Cmt": "Sat", "Paz": "Sun"
  };

  final Map<String, int> _statusCounts = {};

  Future<List<NewsItem>> fetchAllFeeds() async {
    _statusCounts.clear();
    List<Future<List<NewsItem>>> tasks = [];
    for (var source in AppConstants.rssSources) {
      if (source["isHtml"] == "true") {
        tasks.add(_fetchAndParseHtml(source));
      } else {
        tasks.add(_fetchAndParseFeed(source));
      }
    }
    
    final results = await Future.wait(tasks);
    List<NewsItem> allItems = [];
    for (var list in results) {
      allItems.addAll(list);
    }

    if (allItems.isEmpty) {
        return [NewsItem(
            title: "Haber Alınamadı", 
            desc: "Bağlantı sorunu veya veri yok. Lütfen internetinizi kontrol edin.",
            dateObj: DateTime.now(),
            source: "Sistem",
            sourceColor: "0xFF333333",
            url: "",
            image: "",
            score: 0
        )];
    }
    
    return _deduplicateItems(allItems);
  }

  Future<List<NewsItem>> _fetchAndParseFeed(Map<String, String> source) async {
    try {
      // Timeout süresini 30 saniyeye çıkardık (Mobil ağlar yavaş olabilir)
      final response = await http.get(Uri.parse(source["url"]!), headers: _headers).timeout(Duration(seconds: 30));
      
      _statusCounts[source['name']!] = response.statusCode;
      if (response.statusCode != 200) return [];
      
      String content;
      try {
        content = utf8.decode(response.bodyBytes);
      } catch (e) {
        try {
           content = latin1.decode(response.bodyBytes);
        } catch (_) {
           content = response.body; 
        }
      }

      var items = await _parseFeedContent(content, source);
      
      if (items.isEmpty && response.statusCode == 200) {
        items = await _fetchAndParseHtml(source);
      }

      return items;
    } catch (e) {
      _statusCounts[source['name']!] = 999; 
      return [];
    }
  }

  Future<List<NewsItem>> _parseFeedContent(String content, Map<String, String> source) async {
    List<NewsItem> items = [];
    try {
      final document = html_parser.parse(content);
      
      final channelItems = document.getElementsByTagName('item');
      final entryItems = document.getElementsByTagName('entry');
      
      final allNodes = [...channelItems, ...entryItems];
      final now = DateTime.now();

      List<Map<String, dynamic>> tempItems = [];

      for (var node in allNodes) {
        try {
          String title = _getText(node, ['title']);
          String link = _getLink(node);
          String rawDesc = _getText(node, ['content:encoded', 'content', 'description', 'summary']);

          title = _cleanText(title);
          String cleanedDesc = _cleanAndTruncateContent(rawDesc);
          
          if (!_analyzeRelevance(title, cleanedDesc)) continue;
          
          int score = _calculateScore(title, cleanedDesc);
          
          String? dateStr = _getText(node, ['pubDate', 'pubdate', 'updated', 'dc:date', 'date']);
          if (dateStr.isEmpty) dateStr = null;
          
          DateTime? dateObj = _parseRssDate(dateStr);
          if (dateObj == null && dateStr != null) {
             dateObj = _parseTurkishDate(dateStr);
          }
          
          if (dateObj == null) {
            final dateMatch = RegExp(r"(\d{2}\.\d{2}\.\d{4})").firstMatch(rawDesc);
            if (dateMatch != null) {
               try {
                 dateObj = DateFormat("dd.MM.yyyy").parse(dateMatch.group(1)!);
               } catch (_) {}
            }
          }

          dateObj ??= now;
          if (now.difference(dateObj).inDays > 35) continue;
          if (dateObj.isAfter(now.add(Duration(days: 2)))) dateObj = now;

          tempItems.add({
            "node": node,
            "title": title.trim(),
            "desc": cleanedDesc.length > 200 ? cleanedDesc.substring(0, 200) + "..." : cleanedDesc,
            "date": dateObj,
            "link": link,
            "rawDesc": rawDesc,
            "score": score
          });

        } catch (e) {
          continue;
        }
      }

      final futures = tempItems.map((item) async {
         String image = await _extractImage(item["node"], item["rawDesc"], item["link"]);
         return NewsItem(
            title: item["title"],
            desc: item["desc"],
            dateObj: item["date"],
            source: source["name"]!,
            sourceColor: source["color"]!,
            url: item["link"],
            image: image,
            score: item["score"]
         );
      });

      items = await Future.wait(futures);

    } catch (e) {
       // Silent fail
    }
    return items;
  }

  Future<List<NewsItem>> _fetchAndParseHtml(Map<String, String> source) async {
    try {
      final response = await http.get(Uri.parse(source["url"]!), headers: _headers).timeout(Duration(seconds: 30));
      _statusCounts[source['name']!] = response.statusCode;
      if (response.statusCode != 200) return [];
      
      var document = html_parser.parse(response.body);
      
      List<Map<String, dynamic>> candidates = [];
      var seenLinks = <String>{};
      
      var anchors = document.querySelectorAll('a');
      for (var a in anchors) {
        String link = a.attributes['href'] ?? "";
        if (link.isEmpty || link.startsWith("#") || link.startsWith("javascript")) continue;
        
        if (!link.startsWith("http")) {
           var base = Uri.parse(source["url"]!);
           link = "${base.scheme}://${base.host}$link";
        }
        
        if (seenLinks.contains(link)) continue;
        
        String text = a.text.trim();
        String? imgUrl;
        
        var img = a.querySelector('img');
        if (img != null) {
          imgUrl = img.attributes['src'] ?? img.attributes['data-src'];
        }
        
        if (text.length < 15 && imgUrl == null) continue;
        
        if (imgUrl != null) {
           if (!imgUrl.startsWith("http")) {
             var base = Uri.parse(source["url"]!);
             imgUrl = "${base.scheme}://${base.host}$imgUrl";
           }
        }
        
        candidates.add({
           "title": text,
           "link": link,
           "image": imgUrl,
           "node": a
        });
        seenLinks.add(link);
      }
      
      List<NewsItem> items = [];
      
      for (var c in candidates) {

         
         String title = c['title'];
         if (title.length < 20) {
            var parent = (c['node'] as dom.Element).parent;
            if (parent != null) {
               var h = parent.querySelector('h1, h2, h3, h4, span.title');
               if (h != null && h.text.length > 20) title = h.text.trim();
            }
         }
         
         if (title.length < 10) continue;
         
         DateTime? date;

         String rawDesc = "Haberin detayları için tıklayın...";
         if (!_analyzeRelevance(title, rawDesc)) continue;

         String imageCandidate = c['image'] ?? "";
         
         if (imageCandidate.isNotEmpty && !imageCandidate.startsWith("http")) {
             var base = Uri.parse(source["url"]!);
             imageCandidate = "${base.scheme}://${base.host}$imageCandidate";
         }
         
         String image = "";
         if (imageCandidate.isNotEmpty) {
            image = imageCandidate;
         } else {
            image = await _extractImage(c['node'], "", c['link']);
         }
         
         var node = c['node'] as dom.Element;
         var parent = node.parent;
         
         String? dateText;
         
         var cardContainer = parent;
         if (cardContainer != null && cardContainer.parent != null) {
            cardContainer = cardContainer.parent; 
         }
         
         if (cardContainer != null) {
            var times = cardContainer.querySelectorAll('time');
            if (times.isNotEmpty) {
               dateText = times.first.attributes['datetime'] ?? times.first.text;
            } else {
               var dateSpan = cardContainer.querySelector('.date, .time, .datetime, span.tarih, div.tarih, .published, span[data-testid="card-metadata-lastupdated"]');
               if (dateSpan != null) dateText = dateSpan.text;
            }
         }
         
         if (dateText != null) {
             date = _parseRssDate(dateText) ?? _parseTurkishDate(dateText) ?? DateTime.now().subtract(Duration(days: 7));
         } else {
             date = DateTime.now().subtract(Duration(days: 7));
         }

         items.add(NewsItem(
            title: title,
            desc: "Haberin detayları için tıklayın...",
            dateObj: date,
            source: source["name"]!,
            sourceColor: source["color"]!,
            url: c['link'],
            image: image,
            score: 50
         ));
      }
      return items;
      
    } catch (e) {
      return [];
    }
  }

  String _getText(dom.Element parent, List<String> tags) {
    for (var tag in tags) {
      for (var child in parent.children) {
        if (child.localName == tag || child.previousElementSibling?.localName == "$tag:") {
             return child.text;
        }
      }
      var els = parent.getElementsByTagName(tag);
      if (els.isNotEmpty) return els.first.text;
    }
    return "";
  }

  String _getLink(dom.Element parent) {
    var links = parent.getElementsByTagName('link');
    if (links.isNotEmpty) {
      if (links.first.attributes.containsKey('href')) {
        var href = links.first.attributes['href'];
        if (href != null && href.isNotEmpty) return href;
      }
      if (links.first.text.isNotEmpty) return links.first.text;
    }
    var guids = parent.getElementsByTagName('guid');
    if (guids.isNotEmpty) return guids.first.text;
    return "";
  }

  String _cleanText(String text) {
    return text.replaceAll("<![CDATA[", "").replaceAll("]]>", "").trim();
  }

  String _cleanAndTruncateContent(String rawHtml) {
    if (rawHtml.isEmpty) return "";
    var document = html_parser.parse(rawHtml);
    if (document.body == null) return rawHtml;

    document.querySelectorAll('script, style, iframe').forEach((e) => e.remove());

    var paragraphs = document.querySelectorAll('p, div');
    for (var p in paragraphs.reversed) {
      if (p.text.toLowerCase().contains("tıklayın") || 
          p.text.toLowerCase().contains("click") ||
          p.text.toLowerCase().contains("ziyaret ed") ||
          p.text.toLowerCase().contains("abone ol") ||
          (p.querySelector('a') != null && p.text.length < 100)) {
         p.remove();
      } else {
      }
    }
    
    String text = document.body!.text;
    
    final stopPhrases = [
      "İlginizi Çekebilir", "Ayrıca Bakınız", "Devamı İçin", "Kaynak:", "Source:",
      "Bu içerik", "Yasal Uyarı", "Daha fazla oku", "İlgili Haberler", "Bunlar da ilginizi çekebilir",
      "Fotoğraflar:", "Görseller:", "Video:", "Resim:", "Yazar:", "Editör:"
    ];
    
    for (var phrase in stopPhrases) {
       int idx = text.toLowerCase().indexOf(phrase.toLowerCase());
       if (idx != -1) {
         text = text.substring(0, idx);
       }
    }
    
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _analyzeRelevance(String title, String description) {
    String tLower = title.toLowerCase();
    String dLower = description.toLowerCase();

    for (var bad in AppConstants.strictBlacklist) {
      if (tLower.contains(bad)) return false;
    }

    bool brandMatch = false;
    for (var brand in AppConstants.mobileBrandsToFilter) {
      if (tLower.contains(brand)) {
        brandMatch = true;
        break;
      }
    }

    bool titleHasAi = _hasAiKeyword(tLower);
    bool descHasAi = _hasAiKeyword(dLower);

    if (!titleHasAi && !descHasAi) return false;

    if (brandMatch) {
       if (titleHasAi) return true;
       if (_hasMeaningfulAiContext(dLower, threshold: 2)) return true;
       return false;
    }

    return true;
  }

  bool _hasAiKeyword(String text) {
    for (var kw in AppConstants.aiRequiredKeywords) {
      if (text.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  bool _hasMeaningfulAiContext(String text, {int threshold = 1}) {
    int count = 0;
    for (var kw in AppConstants.aiRequiredKeywords) {
       int idx = 0;
       while ((idx = text.indexOf(kw, idx)) != -1) {
         count++;
         idx += kw.length;
       }
    }
    return count >= threshold;
  }

  int _calculateScore(String title, String description) {
    String text = "$title $description".toLowerCase();
    int score = 0;
    
    AppConstants.hotKeywords.forEach((word, points) {
      if (text.contains(word)) score += points;
    });

    for (var kw in AppConstants.hotKeywords.keys) {
      if (title.toLowerCase().contains(kw)) {
        score += 20; 
        break;
      }
    }
    
    for (var kw in AppConstants.aiRequiredKeywords) {
       if (text.contains(kw)) {
         score += 40;
         break;
       }
    }
    return score;
  }

  DateTime? _parseRssDate(String? dateStr) {
    if (dateStr == null) return null;
    
    var s = dateStr.trim();
    _trMonths.forEach((tr, en) {
      s = s.replaceAll(tr, en);
    });
    
    s = s.replaceAll("T00:00:00Z", "T00:00:00Z").replaceAll("GMT", "+0000");
    s = s.replaceAll(RegExp(r"\s+GMT$"), " +0000");
    
    final formats = [
      "E, d MMM y H:m:s Z",
      "E, d MMM y H:m:s z",
      "yyyy-MM-dd'T'H:m:sZ",
      "yyyy-MM-dd'T'H:m:s'Z'",
      "yyyy-MM-dd H:m:s",
      "d.M.yyyy H:m:s",
      "d.M.yyyy",
      "d MMM y H:m:s",
      "E, d MMM y H:m:s"
    ];

    for (var fmt in formats) {
      try {
        return DateFormat(fmt, 'en_US').parse(s);
      } catch (_) {}
    }
    return null;
  }

  final List<String> _aiImages = [
    "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80",
    "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80",
    "https://images.unsplash.com/photo-1676299081847-824916de030a?w=800&q=80",
    "https://images.unsplash.com/photo-1531746790731-6c087fecd65a?w=800&q=80",
    "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&q=80",
    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80",
    "https://images.unsplash.com/photo-1617791160505-6f00504e3519?w=800&q=80",
    "https://images.unsplash.com/photo-1675557009383-013f715c6c20?w=800&q=80",
    "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80",
    "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&q=80",
  ];

  Future<String> _extractImage(dom.Element item, String htmlContent, String link) async {
    String? foundUrl;
    
    if (htmlContent.isNotEmpty) {
      try {
        final imgMatch = RegExp(r'<img[^>]+(data-src|src)="([^">]+)"').firstMatch(htmlContent);
        if (imgMatch != null) {
          foundUrl = imgMatch.group(2);
        }
      } catch (_) {}
    }
    
    if (foundUrl == null) {
      try {
        var medias = item.getElementsByTagName('media:content');
        if (medias.isEmpty) medias = item.getElementsByTagName('media:thumbnail');
        if (medias.isNotEmpty) foundUrl = medias.first.attributes['url'];
        
        if (foundUrl == null) {
          var enc = item.getElementsByTagName('enclosure');
          if (enc.isNotEmpty && (enc.first.attributes['type'] ?? "").contains("image")) {
             foundUrl = enc.first.attributes['url'];
          }
        }
      } catch (_) {}
    }

    if (foundUrl == null && link.startsWith("http")) {
       try {
          final response = await http.get(Uri.parse(link), headers: _headers).timeout(Duration(seconds: 4));
          if (response.statusCode == 200) {
             var doc = html_parser.parse(response.body);
             var og = doc.querySelector('meta[property="og:image"]');
             if (og != null) {
                foundUrl = og.attributes['content'];
             }
             if (foundUrl == null) {
                var tw = doc.querySelector('meta[name="twitter:image"]');
                if (tw != null) foundUrl = tw.attributes['content'];
             }
             if (foundUrl == null) {
                 var lnk = doc.querySelector('link[rel="image_src"]');
                 if (lnk != null) foundUrl = lnk.attributes['href'];
             }
          }
       } catch (_) {
       }
    }

    if (foundUrl != null && foundUrl.isNotEmpty) {
       return foundUrl;
    }

    String title = "";
    var tNode = item.getElementsByTagName('title');
    if (tNode.isNotEmpty) title = tNode.first.text.toLowerCase();
    
    if (title.contains("robot") || title.contains("otonom")) return _aiImages[0];
    if (title.contains("beyin") || title.contains("neural") || title.contains("sinir") || title.contains("öğrenme")) return _aiImages[1];
    if (title.contains("deepmind") || title.contains("gemini") || title.contains("google")) return _aiImages[2];
    if (title.contains("devre") || title.contains("donanım") || title.contains("işlemci") || title.contains("çip")) return _aiImages[3];
    if (title.contains("şehir") || title.contains("gelecek") || title.contains("cyber")) return _aiImages[4];
    if (title.contains("silikon") || title.contains("transistör")) return _aiImages[5];
    if (title.contains("veri") || title.contains("analiz") || title.contains("siber")) return _aiImages[6];
    if (title.contains("chat") || title.contains("bot") || title.contains("sohbet") || title.contains("gpt")) return _aiImages[7];
    if (title.contains("kod") || title.contains("yazılım") || title.contains("algoritma")) return _aiImages[8];
    
    int index = link.hashCode.abs() % _aiImages.length;
    return _aiImages[index];
  }



  DateTime? _parseTurkishDate(String dateStr) {
    try {
      String s = dateStr.trim().toLowerCase();
      final now = DateTime.now();

      if (s.contains("dakika önce") || s.contains("dk önce")) {
         final min = int.tryParse(RegExp(r'(\d+)').firstMatch(s)?.group(1) ?? "0") ?? 0;
         return now.subtract(Duration(minutes: min));
      }
      if (s.contains("saat önce") || s.contains("sa.")) {
         final hr = int.tryParse(RegExp(r'(\d+)').firstMatch(s)?.group(1) ?? "0") ?? 0;
         return now.subtract(Duration(hours: hr));
      }
      if (s.contains("gün önce") || s.contains("dün")) {
         final d = s.contains("dün") ? 1 : int.tryParse(RegExp(r'(\d+)').firstMatch(s)?.group(1) ?? "0") ?? 0;
         return now.subtract(Duration(days: d));
      }
      if (s.contains("bugün")) return now;

      String norm = dateStr.trim();
      _trMonths.forEach((tr, en) {
        norm = norm.replaceAll(tr, en);
        norm = norm.replaceAll(tr.toLowerCase(), en);
      });
      
      final formats = [
        "d MMMM yyyy",
        "d MMM yyyy",
        "dd.MM.yyyy",
        "dd/MM/yyyy",
        "yyyy-MM-dd",
        "d MMMM, HH:mm", 
        "d MMMM HH:mm"
      ];
      
      for (var f in formats) {
         try {
           var d = DateFormat(f, 'en_US').parse(norm);
           if (d.year == 1970) {
              d = DateTime(now.year, d.month, d.day, d.hour, d.minute);
           }
           return d;
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
