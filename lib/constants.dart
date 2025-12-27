
import 'package:flutter/material.dart';

class AppConstants {
  static const String appTitle = "Synapse";
  static const int maxItemsPerPage = 150; 
  
  static const List<Map<String, String>> rssSources = [
    // HTML Sources (Specific AI/Topic Pages)
    {"name": "BBC Yapay Zeka", "url": "https://www.bbc.com/turkce/topics/cvjp20qxr1rt", "color": "0xFFbb1919", "isHtml": "true"},
    {"name": "Euronews AI", "url": "https://tr.euronews.com/tag/yapay-zeka", "color": "0xFF003399", "isHtml": "true"},

    // Major Tech RSS
    {"name": "Webrazzi", "url": "https://webrazzi.com/feed/", "color": "0xFFf37424"},
    {"name": "Webtekno", "url": "https://www.webtekno.com/rss.xml", "color": "0xFFcc3333"},
    {"name": "Technopat", "url": "https://www.technopat.net/feed/", "color": "0xFF333333"},
    {"name": "ShiftDelete", "url": "https://shiftdelete.net/feed", "color": "0xFF333333"},
    {"name": "DonanımHaber", "url": "https://www.donanimhaber.com/rss/tum/", "color": "0xFFff7c00"},
    {"name": "LOG", "url": "https://www.log.com.tr/feed/", "color": "0xFF000000"},
    {"name": "Chip Online", "url": "https://www.chip.com.tr/rss/teknoloji_16.xml", "color": "0xFF005596"},
    
    // Enterprise & Startup & Deep Tech
    {"name": "Swipeline", "url": "https://swipeline.co/feed/", "color": "0xFFFFC107"},
    {"name": "Egirişim", "url": "https://egirisim.com/feed/", "color": "0xFF3f51b5"},
    {"name": "BT Haber", "url": "https://www.bthaber.com/feed", "color": "0xFFd32f2f"},
    {"name": "StartupTeknoloji", "url": "https://startupteknoloji.com/feed/", "color": "0xFF00897b"},
    {"name": "Hardware Plus", "url": "https://hwp.com.tr/feed", "color": "0xFF212121"},
    {"name": "TeknoSafari", "url": "https://tekno-safari.com/feed/", "color": "0xFFe65100"},
    {"name": "Hardware Lab", "url": "https://www.hardwarelab.com.tr/feed/", "color": "0xFF455a64"},
    
    // Additional Tech & Future Sources
    {"name": "Digital Age", "url": "https://digitalage.com.tr/feed/", "color": "0xFF231F20"},
    {"name": "Evrim Ağacı", "url": "https://evrimagaci.org/rss.xml", "color": "0xFF4caf50"},
    {"name": "Marketing TR", "url": "https://marketingturkiye.com.tr/feed/", "color": "0xFFe91e63"},
    {"name": "Cumhuriyet Bilim", "url": "https://www.cumhuriyet.com.tr/rss/bilim-teknoloji", "color": "0xFFD32F2F"},
    {"name": "NTV Tekno", "url": "https://www.ntv.com.tr/teknoloji.rss", "color": "0xFF0065ad"},
    {"name": "T24 Bilim", "url": "https://t24.com.tr/rss/haber/bilim-teknoloji", "color": "0xFF2196F3"},
  ];

  static const List<String> strictBlacklist = [
    "kimdir", "nereli", "kaç yaşında", "tutuklandı", "gözaltı", "cinayet",
    "magazin", "sevgili", "boşandı", "evlendi", "tehdit etti", "ünlü",
    "fiyatı", "kutu açılışı", "inceleme", "özellikleri belli oldu",
    "fragman", "dizi", "film", "sinema", "izle", "ne zaman", "vizyon",
    "en çok arananlar", "türkiye'de", "burç", "astroloji", "hava durumu",
    "masterchef", "survivor", "futbol", "maç", "skor", "transfer",
    "mah batarya", "megapiksel", "kılıf", "ekran koruyucu", "render görüntüleri",
    "tasarımı ortaya çıktı", "renk seçenekleri", "geekbench", "antutu",
    "a101", "bim", "şok", "indirim", "kampanya", "tl altı", "tl üstü",
    "en iyi laptoplar", "tavsiyesi", "fiyat listesi", "indirime girdi",
    "meteor", "göktaşı", "yağmuru", "astronomi", "gözlem",
    "epic games", "steam", "playstation", "xbox", "geforce now", "ücretsiz oyun", "bedava oyun",
    "sistem gereksinimleri", "kaç tl", "fiyatı ne kadar", "ne zaman çıkacak", "oyun konsolu",
    "gizlilik politikası", "kullanım koşulları", "hakkımızda", "künye", "iletişim", "bize ulaşın",
    "çerez politikası", "kvkk", "aydınlatma metni", "site haritası", "reklam", "künye ve iletişim"
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
    "copilot", "generative", "üretken", "algoritma", "transformer modeli", "npu",
    "veri analitiği", "büyük veri", "otomasyon", "akıllı sistem", "sanal asistan",
    "dijital dönüşüm", "siber güvenlik", "bulut bilişim", "teknoloji trendleri"
  ];

  static const Map<String, int> hotKeywords = {
    "satın aldı": 50, "satıldı": 50, "iflas": 80, "rekor": 60,
    "yatırım aldı": 90, "yatırım yaptı": 90, "fon": 70,
    "nvidia": 100, "openai": 100, "deepseek": 100, "google": 80, "microsoft": 80,
    "gpt-5": 100, "sora": 100, "gemini": 90, "claude": 90, "blackwell": 95,
    "yapay zeka": 70, "ai": 70, "robot": 80, "yeni model": 60
  };
}
