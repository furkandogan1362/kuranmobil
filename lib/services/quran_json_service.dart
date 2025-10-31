import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';
import '../models/verse.dart';

class QuranJsonService {
  // Tüm ayetler (tek seferlik yüklenir)
  static List<Verse> _allVerses = [];
  static bool _isLoaded = false;
  
  // Sayfa cache
  static Map<int, List<Verse>> _pageCache = {};
  
  // Sure cache
  static Map<int, List<Verse>> _surahCache = {};
  
  // Chapter bilgileri cache
  static Map<int, Chapter> _chaptersCache = {};
  
  // SharedPreferences key
  static const String _lastPageKey = 'last_read_page';
  static const String _lastScrollPositionKey = 'last_scroll_position';
  
  // Son okunan sayfayı kaydet
  static Future<void> saveLastReadPage(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageKey, pageNumber);
    print('💾 Son sayfa kaydedildi: $pageNumber');
  }
  
  // Son okunan sayfayı getir
  static Future<int> getLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt(_lastPageKey) ?? 1;
    print('📖 Son okunan sayfa: $page');
    return page;
  }
  
  // Son okunan sayfanın scroll pozisyonunu kaydet
  static Future<void> saveLastScrollPosition(int pageNumber, double scrollPosition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_lastScrollPositionKey}_$pageNumber', scrollPosition);
    print('📍 Sayfa $pageNumber scroll pozisyonu kaydedildi: $scrollPosition');
  }
  
  // Son okunan sayfanın scroll pozisyonunu getir
  static Future<double> getLastScrollPosition(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final position = prefs.getDouble('${_lastScrollPositionKey}_$pageNumber') ?? 0.0;
    print('📍 Sayfa $pageNumber scroll pozisyonu yüklendi: $position');
    return position;
  }
  
  // Scroll pozisyonunu temizle (sayfa tamamen okunduğunda)
  static Future<void> clearScrollPosition(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_lastScrollPositionKey}_$pageNumber');
    print('🗑️ Sayfa $pageNumber scroll pozisyonu temizlendi');
  }
  
  // Sure isimleri (manuel tanımlı)
  static final Map<int, Map<String, String>> _surahNames = {
    1: {'arabic': 'الفَاتِحَة', 'turkish': 'Fatiha'},
    2: {'arabic': 'البَقَرَة', 'turkish': 'Bakara'},
    3: {'arabic': 'آل عِمْرَان', 'turkish': 'Âl-i İmrân'},
    4: {'arabic': 'النِّسَاء', 'turkish': 'Nisâ'},
    5: {'arabic': 'المَائدة', 'turkish': 'Mâide'},
    6: {'arabic': 'الأنعَام', 'turkish': 'En\'âm'},
    7: {'arabic': 'الأعرَاف', 'turkish': 'A\'râf'},
    8: {'arabic': 'الأنفَال', 'turkish': 'Enfâl'},
    9: {'arabic': 'التَّوْبَة', 'turkish': 'Tevbe'},
    10: {'arabic': 'يُونس', 'turkish': 'Yûnus'},
    11: {'arabic': 'هُود', 'turkish': 'Hûd'},
    12: {'arabic': 'يُوسُف', 'turkish': 'Yûsuf'},
    13: {'arabic': 'الرَّعْد', 'turkish': 'Ra\'d'},
    14: {'arabic': 'إبراهِيم', 'turkish': 'İbrâhîm'},
    15: {'arabic': 'الحِجْر', 'turkish': 'Hıcr'},
    16: {'arabic': 'النَّحْل', 'turkish': 'Nahl'},
    17: {'arabic': 'الإسْرَاء', 'turkish': 'İsrâ'},
    18: {'arabic': 'الكهْف', 'turkish': 'Kehf'},
    19: {'arabic': 'مَريَم', 'turkish': 'Meryem'},
    20: {'arabic': 'طه', 'turkish': 'Tâhâ'},
    21: {'arabic': 'الأنبيَاء', 'turkish': 'Enbiyâ'},
    22: {'arabic': 'الحَج', 'turkish': 'Hacc'},
    23: {'arabic': 'المُؤمنون', 'turkish': 'Mü\'minûn'},
    24: {'arabic': 'النُّور', 'turkish': 'Nûr'},
    25: {'arabic': 'الفُرْقان', 'turkish': 'Furkān'},
    26: {'arabic': 'الشُّعَرَاء', 'turkish': 'Şuarâ'},
    27: {'arabic': 'النَّمْل', 'turkish': 'Neml'},
    28: {'arabic': 'القَصَص', 'turkish': 'Kasas'},
    29: {'arabic': 'العَنكبوت', 'turkish': 'Ankebût'},
    30: {'arabic': 'الرُّوم', 'turkish': 'Rûm'},
    31: {'arabic': 'لقمَان', 'turkish': 'Lokmân'},
    32: {'arabic': 'السَّجدَة', 'turkish': 'Secde'},
    33: {'arabic': 'الأحزَاب', 'turkish': 'Ahzâb'},
    34: {'arabic': 'سَبَأ', 'turkish': 'Sebe'},
    35: {'arabic': 'فَاطِر', 'turkish': 'Fâtır'},
    36: {'arabic': 'يس', 'turkish': 'Yâsîn'},
    37: {'arabic': 'الصَّافَّات', 'turkish': 'Sâffât'},
    38: {'arabic': 'ص', 'turkish': 'Sâd'},
    39: {'arabic': 'الزُّمَر', 'turkish': 'Zümer'},
    40: {'arabic': 'المؤمن', 'turkish': 'Mü\'min'},
    41: {'arabic': 'فُصِّلَتْ', 'turkish': 'Fussılet'},
    42: {'arabic': 'الشُّورَىٰ', 'turkish': 'Şûrâ'},
    43: {'arabic': 'الزُّخْرُف', 'turkish': 'Zuhruf'},
    44: {'arabic': 'الدُّخَان', 'turkish': 'Duhân'},
    45: {'arabic': 'الجَاثيَة', 'turkish': 'Câsiye'},
    46: {'arabic': 'الأحقاف', 'turkish': 'Ahkāf'},
    47: {'arabic': 'مُحَمَّد', 'turkish': 'Muhammed'},
    48: {'arabic': 'الفَتْح', 'turkish': 'Fetih'},
    49: {'arabic': 'الحُجُرَات', 'turkish': 'Hucurât'},
    50: {'arabic': 'ق', 'turkish': 'Kāf'},
    51: {'arabic': 'الذَّارِيَات', 'turkish': 'Zâriyât'},
    52: {'arabic': 'الطُّور', 'turkish': 'Tûr'},
    53: {'arabic': 'النَّجْم', 'turkish': 'Necm'},
    54: {'arabic': 'القَمَر', 'turkish': 'Kamer'},
    55: {'arabic': 'الرَّحْمَن', 'turkish': 'Rahmân'},
    56: {'arabic': 'الوَاقِعَة', 'turkish': 'Vâkıa'},
    57: {'arabic': 'الحَدِيد', 'turkish': 'Hadîd'},
    58: {'arabic': 'المجَادلة', 'turkish': 'Mücâdele'},
    59: {'arabic': 'الحَشْر', 'turkish': 'Haşr'},
    60: {'arabic': 'المُمتَحنَة', 'turkish': 'Mümtehıne'},
    61: {'arabic': 'الصَّف', 'turkish': 'Saff'},
    62: {'arabic': 'الجُمُعَة', 'turkish': 'Cuma'},
    63: {'arabic': 'المنَافِقون', 'turkish': 'Münâfıkūn'},
    64: {'arabic': 'التَّغَابُن', 'turkish': 'Teğâbün'},
    65: {'arabic': 'الطَّلاق', 'turkish': 'Talâk'},
    66: {'arabic': 'التَّحْرِيم', 'turkish': 'Tahrîm'},
    67: {'arabic': 'المُلْك', 'turkish': 'Mülk'},
    68: {'arabic': 'القَلَم', 'turkish': 'Kalem'},
    69: {'arabic': 'الحَاقَّة', 'turkish': 'Hâkka'},
    70: {'arabic': 'المعَارِج', 'turkish': 'Meâric'},
    71: {'arabic': 'نُوح', 'turkish': 'Nûh'},
    72: {'arabic': 'الجِنّ', 'turkish': 'Cin'},
    73: {'arabic': 'المُزَّمِّل', 'turkish': 'Müzzemmil'},
    74: {'arabic': 'المدَّثِّر', 'turkish': 'Müddessir'},
    75: {'arabic': 'القِيَامَة', 'turkish': 'Kıyâme'},
    76: {'arabic': 'الإنسَان', 'turkish': 'İnsân'},
    77: {'arabic': 'المُرسَلات', 'turkish': 'Mürselât'},
    78: {'arabic': 'النَّبَأ', 'turkish': 'Nebe'},
    79: {'arabic': 'النَّازِعَات', 'turkish': 'Nâziât'},
    80: {'arabic': 'عَبَسَ', 'turkish': 'Abese'},
    81: {'arabic': 'التَّكْوِير', 'turkish': 'Tekvîr'},
    82: {'arabic': 'الانفِطار', 'turkish': 'İnfitār'},
    83: {'arabic': 'المطفِّفِين', 'turkish': 'Mutaffifîn'},
    84: {'arabic': 'الانشِقاق', 'turkish': 'İnşikāk'},
    85: {'arabic': 'البرُوج', 'turkish': 'Burûc'},
    86: {'arabic': 'الطَّارِق', 'turkish': 'Târık'},
    87: {'arabic': 'الأعْلى', 'turkish': 'A\'lâ'},
    88: {'arabic': 'الغَاشِيَة', 'turkish': 'Ğâşiye'},
    89: {'arabic': 'الفَجْر', 'turkish': 'Fecr'},
    90: {'arabic': 'البَلَد', 'turkish': 'Beled'},
    91: {'arabic': 'الشَّمْس', 'turkish': 'Şems'},
    92: {'arabic': 'اللَّيْل', 'turkish': 'Leyl'},
    93: {'arabic': 'الضُّحَى', 'turkish': 'Duhâ'},
    94: {'arabic': 'الشَّرْح', 'turkish': 'İnşirâh'},
    95: {'arabic': 'التِّين', 'turkish': 'Tîn'},
    96: {'arabic': 'العَلَق', 'turkish': 'Alak'},
    97: {'arabic': 'القَدْر', 'turkish': 'Kadir'},
    98: {'arabic': 'البَيِّنَة', 'turkish': 'Beyyine'},
    99: {'arabic': 'الزَّلْزَلَة', 'turkish': 'Zilzâl'},
    100: {'arabic': 'العَادِيات', 'turkish': 'Âdiyât'},
    101: {'arabic': 'القَارِعَة', 'turkish': 'Kāria'},
    102: {'arabic': 'التَّكَاثُر', 'turkish': 'Tekâsür'},
    103: {'arabic': 'العَصْر', 'turkish': 'Asr'},
    104: {'arabic': 'الهُمَزَة', 'turkish': 'Hümeze'},
    105: {'arabic': 'الفِيل', 'turkish': 'Fîl'},
    106: {'arabic': 'قُرَيْش', 'turkish': 'Kureyş'},
    107: {'arabic': 'المَاعُون', 'turkish': 'Mâûn'},
    108: {'arabic': 'الكَوْثَر', 'turkish': 'Kevser'},
    109: {'arabic': 'الكَافِرُون', 'turkish': 'Kâfirûn'},
    110: {'arabic': 'النَّصْر', 'turkish': 'Nasr'},
    111: {'arabic': 'المَسَد', 'turkish': 'Tebbet'},
    112: {'arabic': 'الإخْلَاص', 'turkish': 'İhlâs'},
    113: {'arabic': 'الفَلَق', 'turkish': 'Felak'},
    114: {'arabic': 'النَّاس', 'turkish': 'Nâs'},
  };

  // JSON dosyasını yükle
  Future<void> loadAllVerses() async {
    if (_isLoaded) return;
    
    print('📖 all_verses.json yükleniyor...');
    
    try {
      final String jsonString = await rootBundle.loadString('all_verses.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      _allVerses = jsonData.map((json) => Verse.fromJson(json)).toList();
      _isLoaded = true;
      
      print('✅ ${_allVerses.length} ayet yüklendi!');
      
      // Chapter bilgilerini oluştur
      _createChapters();
      
    } catch (e) {
      print('❌ JSON yükleme hatası: $e');
      throw Exception('Veriler yüklenemedi: $e');
    }
  }
  
  // Chapter bilgilerini oluştur
  void _createChapters() {
    for (int i = 1; i <= 114; i++) {
      final verses = _allVerses.where((v) => v.chapterId == i).toList();
      
      if (verses.isNotEmpty && _surahNames.containsKey(i)) {
        _chaptersCache[i] = Chapter(
          id: i,
          nameArabic: _surahNames[i]!['arabic']!,
          nameSimple: _surahNames[i]!['turkish']!,
          nameTurkish: _surahNames[i]!['turkish']!,
          versesCount: verses.length,
          revelationOrder: 0,
          revelationPlace: '',
          pageStart: verses.first.pageNumber,
          pageEnd: verses.last.pageNumber,
        );
      }
    }
    print('✅ ${_chaptersCache.length} sure bilgisi oluşturuldu');
  }

  // Sayfa numarasına göre ayetleri getir
  Future<List<Verse>> getVersesByPage(int pageNumber) async {
    // İlk yüklemede tüm verileri yükle
    if (!_isLoaded) {
      await loadAllVerses();
    }
    
    // Cache'de varsa döndür
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }
    
    // Sayfadaki ayetleri filtrele
    final pageVerses = _allVerses
        .where((verse) => verse.pageNumber == pageNumber)
        .toList();
    
    // Cache'e ekle
    _pageCache[pageNumber] = pageVerses;
    
    return pageVerses;
  }
  
  // Sure numarasına göre ayetleri getir
  Future<List<Verse>> getVersesByChapter(int chapterId) async {
    // İlk yüklemede tüm verileri yükle
    if (!_isLoaded) {
      await loadAllVerses();
    }
    
    // Cache'de varsa döndür
    if (_surahCache.containsKey(chapterId)) {
      return _surahCache[chapterId]!;
    }
    
    // Suredeki ayetleri filtrele
    final chapterVerses = _allVerses
        .where((verse) => verse.chapterId == chapterId)
        .toList();
    
    // Cache'e ekle
    _surahCache[chapterId] = chapterVerses;
    
    return chapterVerses;
  }
  
  // Chapter bilgisini getir
  Future<Chapter> getChapterFromCache(int chapterId) async {
    // İlk yüklemede tüm verileri yükle
    if (!_isLoaded) {
      await loadAllVerses();
    }
    
    final chapter = _chaptersCache[chapterId];
    if (chapter == null) {
      throw Exception('Sure bulunamadı: $chapterId');
    }
    
    return chapter;
  }
}
