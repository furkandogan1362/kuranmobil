# Arabic Quran Reader – Parts Index

Bu klasör, `arabic_quran_reader_screen.dart` dosyasından ayrılan parça (part) dosyalarını içerir. Her dosyanın amacı kısaca:

- `parts/state_contract.dart`: Mixin'lerin ihtiyaç duyduğu tüm alan ve metod imzalarını tanımlayan sözleşme (contract).
- `parts/base_state.dart`: Ekranın `State` sınıfı için contract'ı uygulayan temel sınıf.
- `parts/data_mixin.dart`: Veri yükleme, önbellekleme ve başlangıç (init) akışları.
- `parts/navigation_mixin.dart`: Sayfa geçişi, scroll yönetimi, görünür sure tespiti ve sayfa/jump animasyonları.
- `parts/build_widgets_mixin.dart`: UI alt bileşenleri; header, bottom bar ve sayfa/ayet render işlemleri.

Not: Bu dosyalar `part`/`part of` yapısı ile ana dosyaya bağlıdır; doğrudan import edilmezler. Ana dosya: `lib/screens/arabic_quran_reader_screen.dart`.
