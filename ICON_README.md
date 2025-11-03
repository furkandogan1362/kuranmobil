# Uygulama İkonu Yönetimi - Android

Bu doküman, **İslam Rehberi** uygulamasının Android ikonunun nasıl yönetileceğini açıklar.

## 📱 Mevcut Durum

Uygulama ikonu şu anda `assets/images/islam_rehberi_icon.png` dosyasından alınmaktadır.
- **Arka Plan Rengi**: `#2B8A8A` (Turkuaz/Teal)
- **Platform**: Sadece Android
- **Özellik**: Adaptive Icon (Responsive & Dinamik)

## 🎯 Adaptive Icon Nedir?

Android'deki **Adaptive Icon** özelliği, ikonunuzun farklı telefon üreticilerinin ve kullanıcı tercihlerinin belirlediği şekillere uyum sağlamasını sağlar:

- 🔵 **Samsung**: Yuvarlak veya squircle (yuvarlatılmış kare)
- � **Xiaomi**: Kare veya yuvarlak
- 🔵 **OnePlus**: Yuvarlak
- 🔵 **Google Pixel**: Yuvarlak

Bu sayede uygulamanız tüm Android cihazlarda **native (yerli)** görünür ve **responsive (dinamik)** çalışır.

## ⚠️ Önemli: Safe Zone Kuralı

Adaptive icon'larda önemli içerik (logo, metin vb.) **merkezde %66'lık alanda** kalmalıdır. Kenar kısımlar farklı şekillerde maskelendiği için kesilir.

```
[100% Alan]
  ├─ %17 Kenar (kesilebilir)
  ├─ %66 Güvenli Alan (Safe Zone) ← İçerik buraya
  └─ %17 Kenar (kesilebilir)
```

## �🔧 İkon Değiştirme Adımları

### 1. İkon Dosyasını Hazırlayın
- **Minimum boyut**: 1024x1024 piksel (önerilen)
- **Format**: PNG (şeffaf arka plan olabilir)
- **İçerik yerleşimi**: Önemli içerik merkezde %66'lık alanda

### 2. İkon Dosyasını Yerleştirin
Yeni ikonu `assets/images/` klasörüne yerleştirin.

### 3. Yapılandırmayı Güncelleyin
`flutter_launcher_icons.yaml` dosyasını düzenleyin:

#### İkon Dosyasını Değiştirmek İçin:
```yaml
flutter_launcher_icons:
  image_path: "assets/images/YENİ_İKON_ADI.png"
  adaptive_icon_foreground: "assets/images/YENİ_İKON_ADI.png"
```

#### Arka Plan Rengini Değiştirmek İçin:
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#RENK_KODU"  # Örnek: #2B8A8A
```

**Önemli**: Arka plan rengi, ikonunuzun arka plan rengiyle uyumlu olmalı ki kesilen kısımlar belli olmasın.

### 4. İkonları Oluşturun
Terminal'de şu komutu çalıştırın:

```powershell
dart run flutter_launcher_icons:main
```

### 5. Uygulamayı Yeniden Derleyin
İkonların görünmesi için:

```powershell
flutter clean
flutter build apk
```

veya debug modda test için:

```powershell
flutter run
```

## 🎨 Renk Değiştirme

Eğer ikonunuzun arka plan rengi farklı bir ton ise, `flutter_launcher_icons.yaml` dosyasındaki renk kodunu değiştirin:

```yaml
adaptive_icon_background: "#2B8A8A"  # Mevcut renk (Turkuaz)
# adaptive_icon_background: "#1A5F5F"  # Daha koyu ton
# adaptive_icon_background: "#3DA9A9"  # Daha açık ton
```

## 🔍 Sorun Giderme

### İkon Kenarlardan Kesiliyor
**Çözüm 1**: Arka plan rengini ikonunuzun arka planıyla eşleştirin
**Çözüm 2**: İkon görselini daha küçük yapın (merkezde daha fazla boşluk bırakın)

### İkon Güncellenmedi
1. `flutter clean` komutunu çalıştırın
2. Uygulamayı telefondan tamamen silin
3. Yeniden yükleyin
4. Bazı telefonlarda cihazı yeniden başlatmanız gerekebilir

### Renk Görünmüyor
`android/app/src/main/res/values/colors.xml` dosyasını kontrol edin:
```xml
<color name="ic_launcher_background">#2B8A8A</color>
```

## 📱 Test Etme

Farklı şekillerde nasıl göründüğünü görmek için:

1. **Telefon Ayarları** → **Ana Ekran** → **İkon Şekli**
2. Yuvarlak, kare, squircle seçeneklerini deneyin
3. Uygulamanızın ikonu her şekle uyum sağlamalı

## 🔗 İlgili Dosyalar

- `flutter_launcher_icons.yaml` - İkon yapılandırma dosyası
- `android/app/src/main/res/values/colors.xml` - Arka plan rengi
- `android/app/src/main/res/mipmap-*/` - Oluşturulan ikon dosyaları
- `assets/images/islam_rehberi_icon.png` - Kaynak ikon dosyası

## 📚 Daha Fazla Bilgi

- [Flutter Launcher Icons Paketi](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons Dokümantasyonu](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
