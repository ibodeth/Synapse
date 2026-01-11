import 'package:synapse_app/services/rss_service.dart';
import 'package:synapse_app/models/news_item.dart';
import 'package:flutter/material.dart';

void main() async {
  print("Test script başlatılıyor... (Çoklu Kaynak Testi)");
  
  var sourcesToTest = [
    {"name": "DonanımHaber", "url": "https://www.donanimhaber.com/rss/tum/", "color": 0xFFff9900},
    {"name": "Webrazzi", "url": "https://webrazzi.com/feed/", "color": 0xFFf2542d},
    {"name": "ShiftDelete", "url": "https://shiftdelete.net/feed", "color": 0xFF3366cc}
  ];

  for (var source in sourcesToTest) {
    print("\n---------------------------------------------------");
    print("TEST: ${source['name']}");
    try {
      var news = await RssService.fetchAndParseFeed(source, (msg) {});
      print("RSS'ten ${news.length} haber çekildi.");
      
      if (news.isNotEmpty) {
        var firstItem = news.first;
        print("İlk haber: ${firstItem.title}");
        print("URL: ${firstItem.url}");
        print("Orijinal Resim (RSS): ${firstItem.image}");
        
        // FORCE SCRAPE
        print("Scraper deneniyor...");
        // Set placeholder to trigger logic
        String originalImg = firstItem.image;
        firstItem.image = "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80";
        
        await RssService.enrichImages([firstItem], (msg) => print("  LOG: $msg"));
        
        print("Scraper Sonucu: ${firstItem.image}");
        
        if (firstItem.image != "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80") {
           print("✅ BAŞARILI: Resim bulundu.");
        } else {
           print("❌ BAŞARISIZ: Resim bulunamadı.");
           // Restore original if valid
           firstItem.image = originalImg;
        }
      } else {
        print("❌ HATA: RSS boş döndü.");
      }
    } catch (e) {
      print("❌ HATA: $e");
    }
  }
}
