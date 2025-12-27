# synapse_mobile

Synapse News Application Mobile Port


## Nasıl Çalıştırılır (How to Run)

### Android Studio ile Açma (Recommended)
1. **Android Studio**'yu açın.
2. **Open** (Aç) butonuna tıklayın.
3. Proje klasörü olarak `D:\Projects\Synapse\synapse_mobile` yolunu seçin.
4. Android Studio projeyi tarayıp `build.gradle` dosyalarını indeksleyene kadar bekleyin.
5. Sağ üst köşedeki cihaz seçim menüsünden bir **Emülatör** veya bağlı telefonunuzu seçin.
6. Yeşil **Play (Run)** butonuna basın.

### Terminal (VS Code / CMD)
```bash
cd synapse_mobile
flutter pub get
flutter run
```

### Build (APK Çıktısı)
```bash
flutter build apk --release
```
Dosya konumu: `build/app/outputs/flutter-apk/app-release.apk`

