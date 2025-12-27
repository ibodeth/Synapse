# Synapse 🧠

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

**Synapse**, teknoloji dünyasındaki en son gelişmeleri ve özellikle yapay zeka (AI) alanındaki kırılımları tek bir merkezde toplayan, modern ve akıllı bir mobil haber uygulamasıdır. 

"Liquid Glass" (Akışkan Cam) tasarım diliyle geliştirilen arayüzü, kullanıcıya premium bir okuma deneyimi sunar.

---

## 📸 Ekran Görüntüleri

| Ana Sayfa (Gündem) | Haber Detay (Glass) | Kaynak İçi Tarayıcı | Hakkında Overlay |
|:-----------------:|:-------------------:|:-------------------:|:----------------:|
| <img src="assets/ss1.png" width="200" /> | <img src="assets/ss2.png" width="200" /> | <img src="assets/ss3.png" width="200" /> | <img src="assets/ss4.png" width="200" /> |

*(Not: Projenizi forklayıp `assets` klasörüne ss1.png, ss2.png gibi ekran görüntüleri eklerseniz yukarıdaki alanlar otomatik dolar.)*

---

## ✨ Temel Özellikler

### 🚀 Gelişmiş Haber Motoru
*   **20+ Seçkin Kaynak:** ShiftDelete, Webtekno, DonanımHaber, BBC AI, Euronews, Swipeline ve daha fazlası.
*   **Akıllı Filtreleme:** Magazin, spam veya alakasız içerikleri temizleyen, sadece "Teknoloji ve AI" odaklı içerikleri süzen özel algoritma.
*   **Yapay Zeka Odaklı:** Başlık ve içerik taraması yaparak AI ile ilgili haberleri önceliklendirir ve puanlar.
*   **Otomatik Görsel Çıkarımı:** RSS akışında görsel olmayan haberler için sitenin `OG-Tags` verilerini tarayarak orijinal kapak fotoğrafını bulur.

### 🎨 Modern & Akışkan Arayüz (Glassmorphism)
*   **Apple-Style Liquid Glass:** Yüksek blur, ışık kırılmaları ve gradyan geçişleriyle zenginleştirilmiş UI bileşenleri.
*   **Immersive Experience:** Tam ekran modu ile dikkat dağıtıcı unsurlardan arındırılmış okuma.
*   **Dinamik Tema:** Cihaz ayarlarına veya kullanıcı tercihine göre Koyu/Açık mod desteği.
*   **İnteraktif Animasyonlar:** Sayfa geçişleri, açılır pencereler ve butonlarda akıcı animasyonlar.

### 📱 Kullanıcı Deneyimi (UX)
*   **Uygulama İçi Tarayıcı:** Haberlerin tamamını okumak için uygulamadan çıkmanıza gerek kalmaz.
*   **Geliştirici Paneli:** YouTube, GitHub ve LinkedIn bağlantılarına hızlı erişim sağlayan özel info overlay.
*   **Offline First:** Son çekilen haberleri bellekte tutarak hızlı açılış sağlar.

---

## 🛠 Kullanılan Teknolojiler ve Kütüphaneler

Bu proje **Flutter** kullanılarak geliştirilmiştir.

*   **Http & Html Parser:** RSS ve HTML tabanlı sitelerden veri kazıma (Web Scraping).
*   **Cached Network Image:** Görsellerin önbelleğe alınması ve performans optimizasyonu.
*   **Url Launcher:** Dış bağlantıların ve uygulama içi tarayıcının yönetimi.
*   **Intl:** Tarih formatlama ve yerelleştirme işlemleri.
*   **Font Awesome:** Sosyal medya ikonları ve görsel materyaller.
*   **Google Fonts:** Modern tipografi (Inter font ailesi).

---

## 📥 Kurulum (APK)

Uygulamanın en son sürümünü (APK) indirmek için **[Releases](https://github.com/ibodeth/Synapse/releases)** sayfasını ziyaret edebilirsiniz.

Kendi ortamınızda çalıştırmak için:

```bash
# Projeyi klonlayın
git clone https://github.com/ibodeth/Synapse.git

# Proje dizinine gidin
cd Synapse

# Paketleri yükleyin
flutter pub get

# Uygulamayı başlatın
flutter run
```

---

## 👨‍💻 Geliştirici

<div align="center">

**İbrahim Nuryağınlı**

[![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@ibrahim.python)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ibodeth)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/ibrahimnuryaginli/)
[![Website](https://img.shields.io/badge/Website-2196F3?style=for-the-badge&logo=google-chrome&logoColor=white)](https://ibodeth.github.io/)

</div>

---

## 📄 Lisans

Bu proje MIT lisansı ile lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakabilirsiniz.
