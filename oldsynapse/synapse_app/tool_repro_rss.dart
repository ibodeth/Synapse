import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

// Copy of DateUtilsHelper logic for testing
class DateUtilsHelper {
  static const Map<String, String> trMonths = {
    "Oca": "Jan", "Şub": "Feb", "Mar": "Mar", "Nis": "Apr", "May": "May", "Haz": "Jun",
    "Tem": "Jul", "Ağu": "Aug", "Eyl": "Sep", "Eki": "Oct", "Kas": "Nov", "Ara": "Dec",
    "Pzt": "Mon", "Sal": "Tue", "Çar": "Wed", "Per": "Thu", "Cum": "Fri", "Cmt": "Sat", "Paz": "Sun"
  };

  static String cleanDateString(String dateStr) {
    String cleaned = dateStr.trim();
    trMonths.forEach((tr, en) {
      cleaned = cleaned.replaceAll(tr, en);
    });
    return cleaned;
  }

  static DateTime? parseRssDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    String s = cleanDateString(dateStr);
    // Mimic the file logic exactly
    s = s.replaceAll("T00:00:00Z", "T00:00:00Z").replaceAll("GMT", "+0000");
    s = s.replaceAll(RegExp(r"\s+GMT$"), " +0000");

    List<String> formats = [
      "EEE, d MMM yyyy HH:mm:ss Z",
      "EEE, d MMM yyyy HH:mm:ss z",
      "yyyy-MM-dd'T'HH:mm:ssZ",
      "yyyy-MM-dd HH:mm:ss",
      "dd.MM.yyyy HH:mm:ss",
      "dd.MM.yyyy",
      "d MMM yyyy HH:mm:ss",
      "EEE, d MMM yyyy HH:mm:ss"
    ];

    for (String fmt in formats) {
      try {
        var d = DateFormat(fmt, 'en_US').parseLoose(s);
        print("  -> Parsed successfully with format '$fmt': $d");
        return d;
      } catch (e) {
        // print("  -> Failed format '$fmt'");
      }
    }
    
    try {
      return DateTime.parse(s);
    } catch (e) {
      return null;
    }
  }
}

void main() async {
  List<String> urls = [
    "https://www.donanimhaber.com/rss/tum/",
    "https://www.webtekno.com/rss.xml",
    "https://shiftdelete.net/feed",
  ];

  for (String url in urls) {
    print("--- Fetching $url ---");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        String content = utf8.decode(response.bodyBytes, allowMalformed: true);
        var document = XmlDocument.parse(content);
        
        var items = document.findAllElements('item');
        if (items.isEmpty) items = document.findAllElements('entry');

        if (items.isNotEmpty) {
           var item = items.first;
           String? dateStr;
           for (var tag in ['pubDate', 'pubdate', 'updated', 'dc:date', 'date']) {
             var el = item.findElements(tag).firstOrNull;
             if (el != null) {
               dateStr = el.innerText;
               print("Found dateStr: $dateStr");
               DateUtilsHelper.parseRssDate(dateStr);
               break; // Only test the first valid date tag found
             }
           }
           
           if (dateStr == null) print("No date tag found!");
           
           // Check for ShiftDelete specific issues if needed
           if (url.contains("shiftdelete")) {
             String link = item.findElements('link').firstOrNull?.innerText ?? "";
             print("ShiftDelete Link: $link");
             if (link.isNotEmpty) {
                 print("Fetching article page to look for og:image...");
                 var artResponse = await http.get(Uri.parse(link));
                 String artBody = artResponse.body;
                 // look for og:image
                 RegExp ogImg = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"');
                 var m = ogImg.firstMatch(artBody);
                 if (m != null) {
                     print("Found og:image: ${m.group(1)}");
                 } else {
                     print("No og:image found.");
                 }
             }
           }
        }
      } 
    } catch (e) {
      print("Error: $e");
    }
    print("\n");
  }
}
