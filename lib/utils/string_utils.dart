import 'package:html/parser.dart';

class StringUtils {
  static const List<String> stopPhrases = [
    "İlginizi Çekebilir", "İlginizi çekebilir", "Ayrıca Bakınız", "Ayrıca bakınız",
    "Ayrıca Bkz", "Bunlara da Göz Atın", "Daha Fazla Oku", "Devamı İçin Tıklayınız",
    "İlgili Haberler", "Benzer İçerikler", "Editörün Önerisi", "Kaynak:", "Source:",
    "Bu içerik", "Yasal Uyarı"
  ];

  static String cleanAndTruncateContent(String? rawHtml) {
    if (rawHtml == null || rawHtml.isEmpty) return "";
    
    // Parse HTML to get text
    var document = parse(rawHtml);
    String text = document.body?.text ?? "";
    text = text.trim();

    // Remove stop phrases
    for (String phrase in stopPhrases) {
      if (text.contains(phrase)) {
        text = text.split(phrase)[0];
      }
    }

    return text.trim();
  }
}
