import 'dart:ui';

class AppConstants {
  static const String appTitle = "Synapse";
  static const int maxItemsPerPage = 100;
  
  static const List<Map<String, dynamic>> rssSources = [
    {"name": "DonanımHaber", "url": "https://www.donanimhaber.com/rss/tum/", "color": 0xFFff9900},
    {"name": "Webtekno", "url": "https://www.webtekno.com/rss.xml", "color": 0xFFcc3333},
    {"name": "ShiftDelete", "url": "https://shiftdelete.net/feed", "color": 0xFF3366cc},
    {"name": "Webrazzi", "url": "https://webrazzi.com/feed/", "color": 0xFFf2542d},
    {"name": "LOG", "url": "https://www.log.com.tr/feed/", "color": 0xFF000000},
    {"name": "Evrim Ağacı", "url": "https://evrimagaci.org/rss.xml", "color": 0xFF4caf50},
    {"name": "Technopat", "url": "https://www.technopat.net/feed/", "color": 0xFF333333},
    {"name": "Swipeline", "url": "https://swipeline.co/feed/", "color": 0xFFFFC107},
    {"name": "Hardware Plus", "url": "https://hwp.com.tr/feed", "color": 0xFF00bcd4},
    {"name": "Tamindir", "url": "https://www.tamindir.com/rss/haber/", "color": 0xFF4caf50},
    {"name": "Egirişim", "url": "https://egirisim.com/feed/", "color": 0xFF3f51b5},
    {"name": "Marketing TR", "url": "https://marketingturkiye.com.tr/feed/", "color": 0xFFe91e63},
    {"name": "BBC Türkçe (Tek)", "url": "http://feeds.bbci.co.uk/turkce/topics/technology/rss.xml", "color": 0xFFB80000},
    {"name": "Independent TR", "url": "https://www.indyturk.com/rss/bilim-teknoloji", "color": 0xFFE30613},
    {"name": "Chip Online", "url": "https://www.chip.com.tr/rss/teknoloji_16.xml", "color": 0xFF005596},
    {"name": "Digital Age", "url": "https://digitalage.com.tr/feed/", "color": 0xFF231F20},
    {"name": "AA Bilim Teknoloji", "url": "https://www.aa.com.tr/tr/rss/default?cat=bilim-teknoloji", "color": 0xFF1295D8},
  ];

  static const List<String> strictBlacklist = [
    "kimdir", "nereli", "kaç yaşında", "tutuklandı", "gözaltı", "cinayet",
    "magazin", "sevgili", "boşandı", "evlendi", "tehdit etti", "ünlü",
    "fiyatı", "kutu açılışı", "inceleme", "özellikleri belli oldu", "tanıtıldı", "duyuruldu",
    "satışa çıktı", "robot süpürge", "ilk bakış", "ön inceleme", "satışa sunuldu",
    "fragman", "dizi", "film", "sinema", "izle", "ne zaman", "vizyon",
    "en çok arananlar", "türkiye'de", "burç", "astroloji", "hava durumu",
    "masterchef", "survivor", "futbol", "maç", "skor", "transfer",
    "mah batarya", "megapiksel", "kılıf", "ekran koruyucu", "render görüntüleri",
    "tasarımı ortaya çıktı", "renk seçenekleri", "geekbench", "antutu",
    "a101", "bim", "şok", "indirim", "kampanya", "tl altı", "tl üstü",
    "en iyi laptoplar", "tavsiyesi", "fiyat listesi", "indirime girdi",
    "meteor", "göktaşı", "yağmuru", "astronomi", "gözlem"
  ];

  static const List<String> mobileBrandsToFilter = [
    "honor", "oppo", "vivo", "infinix", "tecno", "realme", "redmi", "poco",
    "oneplus", "motorola", "moto", "nokia", "tcl", "omix", "reeder", "xiaomi",
    "samsung", "apple", "huawei", "lenovo", "asus", "msi", "monster", "casper"
  ];

  static const List<String> aiRequiredKeywords = [
    "yapay zeka", "artificial intelligence", "genai", "chatgpt",
    "gemini", "sora", "llm", "büyük dil modeli", "deep learning", "neural", "sinir ağı",
    "otonom", "robot", "nvidia", "apple intelligence", "deepseek", "anthropic",
    "machine learning", "makine öğrenimi", "computer vision", "doğal dil işleme", "nlp",
    "copilot", "generative", "üretken", "algoritma", "transformer modeli", "npu"
  ];

  static const Map<String, int> hotKeywords = {
    "satın aldı": 50, "satıldı": 50, "iflas": 80, "rekor": 60,
    "yatırım aldı": 90, "yatırım yaptı": 90, "fon": 70,
    "nvidia": 100, "openai": 100, "deepseek": 100, "google": 80, "microsoft": 80,
    "gpt-5": 100, "sora": 100, "gemini": 90, "claude": 90, "blackwell": 95,
    "yapay zeka": 70, "ai": 70, "robot": 80
  };
}
