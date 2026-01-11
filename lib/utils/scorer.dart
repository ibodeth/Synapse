import '../constants.dart';

class Scorer {
  static int calculateScore(String title, String description) {
    String text = "$title $description".toLowerCase();
    int score = 0;

    AppConstants.hotKeywords.forEach((word, points) {
      if (text.contains(word)) score += points;
    });

    if (AppConstants.hotKeywords.keys.any((word) => title.toLowerCase().contains(word))) {
      score += 20;
    }

    for (String kw in AppConstants.aiRequiredKeywords) {
      if (text.contains(kw)) {
        score += 40;
        break; 
      }
    }

    return score;
  }

  static bool hasAiKeywordRegex(String text) {
    String textLower = text.toLowerCase();
    for (String kw in AppConstants.aiRequiredKeywords) {
      // Simple contains check is usually enough, regex for word boundary is better but expensive
      // Using RegExp with word boundaries
      if (RegExp(r'\b' + RegExp.escape(kw.trim()) + r'\b').hasMatch(textLower)) {
        return true;
      }
    }
    return false;
  }

  static bool hasMeaningfulAiContext(String text) {
    String textLower = text.toLowerCase();
    if (!hasAiKeywordRegex(textLower)) return false;
    
    List<String> sentences = textLower.split(RegExp(r'[.!?]+'));
    for (String sentence in sentences) {
      if (hasAiKeywordRegex(sentence)) {
        List<String> words = sentence.trim().split(RegExp(r'\s+'));
        if (words.length >= 5 && !["kategori:", "etiket:", "tags:", "topics:"].any((x) => sentence.contains(x))) {
          return true;
        }
      }
    }
    return false;
  }

  static bool analyzeRelevance(String title, String description) {
    String titleLower = (title).toLowerCase();
    String descLower = (description).toLowerCase();

    if (AppConstants.strictBlacklist.any((bad) => titleLower.contains(bad))) return false;

    bool brandMatch = AppConstants.mobileBrandsToFilter.any((brand) => titleLower.contains(brand));
    bool hasAi = hasAiKeywordRegex(titleLower) || hasAiKeywordRegex(descLower);

    if (brandMatch && !hasAi) return false;

    if (hasAiKeywordRegex(titleLower)) return true;
    if (hasMeaningfulAiContext(descLower)) return true;

    return false;
  }
}
