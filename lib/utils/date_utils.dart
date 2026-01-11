import 'package:intl/intl.dart';

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
    
    // Manual parsing for RFC1123 (Web compatible)
    // Format: Sat, 27 Dec 2025 01:21:00 +0300
    try {
      List<String> parts = s.split(' ');
      if (parts.length >= 5) {
        int day = int.parse(parts[1]);
        String monthStr = parts[2];
        int year = int.parse(parts[3]);
        List<String> timeParts = parts[4].split(':');
        int hour = int.parse(timeParts[0]);
        int minute = int.parse(timeParts[1]);
        int second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
        
        int month = 1;
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        month = months.indexOf(monthStr) + 1;
        if (month == 0) month = 1;

        // Ignore timezone for now or assume local/UTC mapping,
        // but creating a UTC object is safest for display logic
        return DateTime.utc(year, month, day, hour, minute, second);
      }
    } catch (_) {}

    // Manual cleanup for loose parsing
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
        return DateFormat(fmt, 'en_US').parseLoose(s);
      } catch (e) {
        continue;
      }
    }
    
    // Fallback: ISO-8601 direct parse
    try {
      return DateTime.parse(s);
    } catch (e) {
      return null;
    }
  }

  static DateTime parseDateFromDesc(String desc) {
     RegExp regExp = RegExp(r"(\d{2}\.\d{2}\.\d{4})");
     var match = regExp.firstMatch(desc);
     if (match != null) {
       try {
         return DateFormat("dd.MM.yyyy").parse(match.group(1)!);
       } catch (_) {}
     }
     // If we can't find a date, return "now" but maybe we should flag it?
     // For now, consistent with legacy behavior.
     return DateTime.now();
  }
  static DateTime? parseTurkishDate(String dateStr) {
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
      trMonths.forEach((tr, en) {
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
           var d = DateFormat(f, 'en_US').parseLoose(norm);
           if (d.year == 1970) {
              d = DateTime(now.year, d.month, d.day, d.hour, d.minute);
           }
           return d;
         } catch (_) {}
      }
    } catch (_) {}
    return null;
  }
}
