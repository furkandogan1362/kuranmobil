import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chapter.dart';
import '../models/verse.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.acikkuran.com';
  
  // Sayfa cache
  static Map<int, List<Verse>> _pageCache = {};
  
  // Sure cache - sadece yüklenen sureler
  static Map<int, List<Verse>> _surahCache = {};
  
  // Chapter bilgileri cache - sadece yüklenen sureler
  static Map<int, Chapter> _chaptersCache = {};

  // Belirli bir surenin ayetlerini getir
  Future<List<Verse>> getVersesByChapter(int chapterId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surah/$chapterId?author=11'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verses = (data['data']['verses'] as List)
            .map((json) => Verse.fromJson(json))
            .toList();
        return verses;
      } else {
        throw Exception('Ayetler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  // Sayfa numarasına göre ayetleri getir - YENİ AKILLI ALGORİTMA
  Future<List<Verse>> getVersesByPage(int pageNumber) async {
    try {
      // Cache'de varsa ANINDA döndür
      if (_pageCache.containsKey(pageNumber)) {
        print('✓ Sayfa $pageNumber cache\'den geldi');
        return _pageCache[pageNumber]!;
      }
      
      print('⏳ Sayfa $pageNumber yükleniyor...');
      
      // YENİ AKILLI YAKLAŞIM: Sayfa numarasından sure tahmini
      // İlk 10 sayfa -> Fatiha + Bakara
      // Sonraki sayfalar -> yaklaşık sure ID hesapla
      
      List<Verse> pageVerses = [];
      int startSurah = _estimateStartSurah(pageNumber);
      int endSurah = startSurah + 3; // En fazla 3-4 sure kontrol et
      
      if (endSurah > 114) endSurah = 114;
      
      // Sadece tahmin edilen sureleri yükle
      for (int surahId = startSurah; surahId <= endSurah; surahId++) {
        if (!_surahCache.containsKey(surahId)) {
          await _loadSurah(surahId);
        }
        
        // Bu suredeki ayetleri kontrol et
        final verses = _surahCache[surahId] ?? [];
        final matchingVerses = verses.where((v) => v.pageNumber == pageNumber).toList();
        
        if (matchingVerses.isNotEmpty) {
          pageVerses.addAll(matchingVerses);
        }
        
        // Sayfayı bulduysak DUR
        if (pageVerses.isNotEmpty) {
          print('✓ Sayfa $pageNumber bulundu (Sure $surahId)');
          break;
        }
      }
      
      // Hala bulamadıysak, TÜM sureleri kontrol et (602-604 için gerekli)
      if (pageVerses.isEmpty) {
        print('⚠ Geniş arama yapılıyor - Tüm sureler kontrol ediliyor...');
        for (int surahId = 1; surahId <= 114; surahId++) {
          // Cache'de yoksa yükle
          if (!_surahCache.containsKey(surahId)) {
            await _loadSurah(surahId);
          }
          
          final verses = _surahCache[surahId] ?? [];
          final matchingVerses = verses.where((v) => v.pageNumber == pageNumber).toList();
          if (matchingVerses.isNotEmpty) {
            pageVerses.addAll(matchingVerses);
            print('✓ Sayfa $pageNumber bulundu (Sure $surahId) - Geniş aramada');
            break;
          }
        }
      }
      
      // Hala bulamadıysak warning ver
      if (pageVerses.isEmpty) {
        print('⚠️ UYARI: Sayfa $pageNumber için hiç ayet bulunamadı!');
      }
      
      // Cache'e ekle
      _pageCache[pageNumber] = pageVerses;
      
      return pageVerses;
    } catch (e) {
      print('❌ Sayfa yükleme hatası: $e');
      throw Exception('Sayfa ayetleri yüklenemedi: $e');
    }
  }
  
  // Sayfa numarasından sure tahmini yap (HIZLANDIRMA)
  int _estimateStartSurah(int pageNumber) {
    if (pageNumber <= 2) return 1;  // Fatiha
    if (pageNumber <= 49) return 2;  // Bakara
    if (pageNumber <= 76) return 3;  // Al-i İmran
    if (pageNumber <= 106) return 4; // Nisa
    if (pageNumber <= 127) return 5; // Maide
    if (pageNumber <= 151) return 6; // Enam
    if (pageNumber <= 177) return 7; // Araf
    if (pageNumber <= 187) return 8; // Enfal
    if (pageNumber <= 207) return 9; // Tevbe
    if (pageNumber <= 221) return 10; // Yunus
    if (pageNumber <= 235) return 11; // Hud
    if (pageNumber <= 249) return 12; // Yusuf
    if (pageNumber <= 255) return 13; // Rad
    if (pageNumber <= 261) return 14; // İbrahim
    if (pageNumber <= 267) return 15; // Hicr
    if (pageNumber <= 281) return 16; // Nahl
    if (pageNumber <= 293) return 17; // İsra
    if (pageNumber <= 305) return 18; // Kehf
    if (pageNumber <= 312) return 19; // Meryem
    if (pageNumber <= 321) return 20; // Taha
    
    // Orta sureleri yaklaşık hesapla
    if (pageNumber <= 400) return ((pageNumber - 320) ~/ 5) + 21;
    
    // Son sayfalar (Kısa sureler)
    if (pageNumber <= 500) return 67; // Mülk civarı
    if (pageNumber <= 550) return 78; // Nebe civarı
    if (pageNumber <= 580) return 87; // Ala civarı
    
    return 100; // Son sureler
  }
  
  // Tek bir sureyi yükle ve Chapter bilgisini de cache'e ekle
  Future<void> _loadSurah(int surahId) async {
    if (_surahCache.containsKey(surahId)) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/surah/$surahId?author=11'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Chapter bilgisini cache'e ekle
        final surahData = data['data'];
        _chaptersCache[surahId] = Chapter.fromJson(surahData);
        
        // Ayetleri cache'e ekle
        final verses = (surahData['verses'] as List)
            .map((json) => Verse.fromJson(json))
            .toList();
        
        _surahCache[surahId] = verses;
        print('✓ Sure $surahId yüklendi (${verses.length} ayet)');
      }
    } catch (e) {
      print('❌ Sure $surahId yüklenirken hata: $e');
    }
  }
  
  // Chapter bilgisini getir - Lazy loading
  Future<Chapter> getChapterFromCache(int chapterId) async {
    // Cache'de varsa ANINDA döndür
    if (_chaptersCache.containsKey(chapterId)) {
      return _chaptersCache[chapterId]!;
    }
    
    // Yoksa sadece o sureyi yükle
    await _loadSurah(chapterId);
    
    final chapter = _chaptersCache[chapterId];
    if (chapter == null) {
      throw Exception('Sure bulunamadı: $chapterId');
    }
    
    return chapter;
  }
}

