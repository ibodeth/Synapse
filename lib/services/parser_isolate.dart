import 'dart:async';
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:xml/xml.dart';
import '../models/news_item.dart';
import '../utils/scorer.dart';
import '../utils/date_utils.dart';
import '../utils/string_utils.dart';
import '../constants.dart';

// Top-level function for Isolate
Future<List<NewsItem>> parseFeedIsolate(Map<String, dynamic> data) async {
  String content = data['content'];
  String sourceName = data['sourceName'];
  String sourceColor = data['sourceColor'];
  String sourceUrl = data['sourceUrl'];
  
  // Re-initialize constants if needed, but static consts from AppConstants should be available if imported.
  // However, simpler to just access them directly if they are static.
  
  List<NewsItem> newsList = [];
  DateTime now = DateTime.now();
  const String kPlaceholderImage = "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80";

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
        
        if (link.contains("?")) {
          link = link.replaceAll(RegExp(r'(\?|&)amp=1'), '');
        }
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
        
        if (dtObj.isAfter(now.add(const Duration(hours: 48)))) dtObj = now;
        if (now.difference(dtObj).inDays > 180) continue;

        String image = kPlaceholderImage;
        
        var media = node.findElements('media:content').firstOrNull ?? node.findElements('media:thumbnail').firstOrNull;
        if (media != null) {
          image = media.getAttribute('url') ?? image;
        } else {
           var enclosure = node.findElements('enclosure').firstOrNull;
           if (enclosure != null && (enclosure.getAttribute('type')?.contains("image") ?? false)) {
             image = enclosure.getAttribute('url') ?? image;
           }
        }
        
         if (image == kPlaceholderImage && rawDesc.contains("<img")) {
            RegExp imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
            var match = imgRegex.firstMatch(rawDesc);
            if (match != null) {
              image = match.group(1) ?? image;
            }
         }

        newsList.add(NewsItem(
          title: title.trim(),
          desc: cleanedDesc.length > 200 ? "${cleanedDesc.substring(0, 200)}..." : cleanedDesc,
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
    return [];
  }
}

// Top-level function for HTML Parsing Isolate
Future<List<NewsItem>> parseHtmlIsolate(Map<String, dynamic> data) async {
  String content = data['content'];
  String sourceName = data['sourceName'];
  String sourceColor = data['sourceColor'];
  String sourceUrl = data['sourceUrl'];
  const String kPlaceholderImage = "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80";

  try {
    var document = html_parser.parse(content);
    
    List<Map<String, dynamic>> candidates = [];
    var seenLinks = <String>{};
    
    var anchors = document.querySelectorAll('a');
    for (var a in anchors) {
      String link = a.attributes['href'] ?? "";
      if (link.isEmpty || link.startsWith("#") || link.startsWith("javascript")) continue;
      
      if (!link.startsWith("http")) {
         var base = Uri.parse(sourceUrl);
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
      
      if (imgUrl != null && !imgUrl.startsWith("http")) {
          var base = Uri.parse(sourceUrl);
          imgUrl = "${base.scheme}://${base.host}$imgUrl";
      }

      // Broad date extraction
      DateTime? date;
      String? dateText;
      var cardContainer = (a as dom.Element).parent;

      // Aggressive date search
      for (int i = 0; i < 4; i++) {
        if (cardContainer == null) break;
        
        // Match ANY likely date container
        var timeEl = cardContainer.querySelector(
          'time, '
          '[class*="date"], [class*="time"], ' // wildcards for date/time classes
          '[id*="date"], [id*="time"], '
          '[data-testid*="date"], [data-testid*="time"], [data-testid*="lastupdated"]'
        );

        if (timeEl != null) {
           dateText = timeEl.attributes['datetime'] ?? 
                      timeEl.attributes['title'] ?? 
                      timeEl.text.trim();
           if (dateText != null && dateText!.length > 5 && dateText!.length < 60) {
              // Found a candidate
              break;
           }
        }
        cardContainer = cardContainer.parent;
      }
      
      if (dateText != null) {
         date = DateUtilsHelper.parseRssDate(dateText) ?? DateUtilsHelper.parseTurkishDate(dateText);
      }

      candidates.add({
         "title": text,
         "link": link,
         "image": imgUrl,
         "node": a,
         "date": date ?? DateTime.now()
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
       
       String rawDesc = "Haberin detayları için tıklayın...";
       if (!Scorer.analyzeRelevance(title, rawDesc)) continue;

       String image = c['image'] ?? kPlaceholderImage;

       items.add(NewsItem(
          title: title,
          desc: "Haberin detayları için tıklayın...",
          dateObj: c['date'],
          source: sourceName,
          sourceColor: sourceColor,
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
