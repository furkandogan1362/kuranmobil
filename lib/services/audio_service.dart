import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sesli meal servisi
/// Diyanet sesli meal dosyalarını indirir ve oynatır
class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Ses durumları
  bool _isPlaying = false;
  bool _isLoading = false;
  int? _currentSurah;
  int? _currentAyah;
  int _totalAyahs = 0;
  int? _visibleSurah; // Scroll ile görünen sure
  List<int> _highlightedAyahs = [];
  double _playbackSpeed = 1.0;
  bool _isCancelled = false; // İşlem iptal edildi mi?
  int _currentSessionId = 0; // Aktif oynatma session ID'si
  
  // Sayfa değiştirme callback'i
  Function(int surahId, int ayahNumber)? onPageChangeNeeded;
  
  // Sure bilgileri (sonraki sureye geçiş için)
  Map<int, dynamic>? _chaptersMap; // Chapter modellerini sakla
  
  // Boş ayetleri takip et (1 saniyelik sessiz dosyalar)
  Map<String, int> _silentAyahsCount = {}; // "surah_ayah" -> count
  
  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  int? get currentSurah => _currentSurah;
  int? get currentAyah => _currentAyah;
  int? get visibleSurah => _visibleSurah;
  List<int> get highlightedAyahs => _highlightedAyahs;
  double get playbackSpeed => _playbackSpeed;
  
  // Base URL
  static const String baseUrl = 'https://webdosya.diyanet.gov.tr/kuran/kuranikerim/Sound/tr_seyfullahkartal';
  
  AudioService() {
    _initAudioPlayer();
  }
  
  void _initAudioPlayer() {
    // Ses oynatma bittiğinde otomatik geçiş
    _audioPlayer.onPlayerComplete.listen((_) {
      _onAudioComplete();
    });
    
    // Ses pozisyon değişimlerini dinle
    _audioPlayer.onPositionChanged.listen((position) {
      // Ses pozisyonuna göre ayet vurgulama yapılabilir
    });
  }
  
  /// İzin kontrolü ve isteme
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true; // iOS için şimdilik true
  }
  
  /// Ses dosyası yolunu al (cache'den veya indir)
  Future<String?> _getAudioFilePath(int surah, int ayah) async {
    try {
      // Cache dizinini al
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }
      
      final fileName = '${surah}_$ayah.mp3';
      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);
      
      // Dosya zaten varsa direkt döndür
      if (await file.exists()) {
        print('🎵 Ses dosyası cache\'den alındı: $fileName');
        return filePath;
      }
      
      // Dosya yoksa indir
      print('📥 Ses dosyası indiriliyor: $fileName');
      final url = '$baseUrl/$fileName';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('✅ Ses dosyası indirildi ve kaydedildi: $fileName');
        
        // 1 saniyelik sessiz dosya mı kontrol et (yaklaşık 16KB'dan küçük)
        if (response.bodyBytes.length < 20000) {
          print('🔇 Sessiz ayet tespit edildi: $fileName (${response.bodyBytes.length} bytes)');
          _silentAyahsCount['${surah}_$ayah'] = 1;
        } else {
          _silentAyahsCount.remove('${surah}_$ayah');
        }
        
        return filePath;
      } else {
        print('❌ Ses dosyası indirilemedi: $fileName (Status: ${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('❌ Ses dosyası hatası: $e');
      return null;
    }
  }
  
  /// Sure ve ayet seslendirmeyi başlat
  Future<void> playAyah(int surah, int ayah, {
    int totalAyahs = 0, 
    Map<int, dynamic>? chapters,
    bool skipSurahName = false, // Yeni parametre: True ise 0. ayeti atla
  }) async {
    try {
      // Önceki işlemi iptal et
      _isCancelled = true;
      _currentSessionId++; // Yeni session başlat
      final sessionId = _currentSessionId; // Bu session'ın ID'sini sakla
      
      await _audioPlayer.stop();
      await Future.delayed(Duration(milliseconds: 100)); // Önceki işlemin durmasını bekle
      
      // Yeni işlem başlıyor
      _isCancelled = false;
      _isLoading = true;
      notifyListeners();
      
      // Chapters map'ini sakla (sonraki sure için)
      if (chapters != null) {
        _chaptersMap = chapters;
      }
      
      // İzin kontrolü
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('❌ Depolama izni verilmedi');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _currentSurah = surah;
      _currentAyah = ayah;
      _totalAyahs = totalAyahs;
      
      // Eğer ilk ayet ise VE skipSurahName false ise önce sure adını çal (x_0)
      if (ayah == 1 && !skipSurahName) {
        // 0. ayeti çal (sure adı + besmele)
        final surahNamePath = await _getAudioFilePath(surah, 0);
        if (surahNamePath != null && !_isCancelled && sessionId == _currentSessionId) {
          // 0. ayet çalınıyor olarak işaretle
          _currentAyah = 0;
          _highlightedAyahs = [0];
          _isPlaying = true;
          _isLoading = false;
          notifyListeners();
          
          print('🎵 Çalınıyor: $surah:0 (Sure adı + Besmele)');
          await _audioPlayer.play(DeviceFileSource(surahNamePath));
          await _audioPlayer.setPlaybackRate(_playbackSpeed);
          
          // Session kontrolü
          if (sessionId != _currentSessionId || _isCancelled) {
            print('⏹️ Sure adı çalarken session değişti');
            return;
          }
          
          // Sure adı bitene kadar bekle
          await _audioPlayer.onPlayerComplete.first;
          
          // Session kontrolü tekrar
          if (sessionId != _currentSessionId || _isCancelled) {
            print('⏹️ Sure adı bitti ama session değişti');
            return;
          }
          
          print('✅ Sure adı tamamlandı, ayetlere geçiliyor');
        }
      }
      
      // Loading'i kapat
      _isLoading = false;
      notifyListeners();
      
      // Session hala aktif mi kontrol et
      if (sessionId == _currentSessionId && !_isCancelled) {
        // Şimdi ayeti çal (1. ayetten başla)
        await _playAyahRecursive(surah, ayah, totalAyahs, sessionId);
      }
      
    } catch (e) {
      print('❌ Ses çalma hatası: $e');
      _isLoading = false;
      _isPlaying = false;
      notifyListeners();
    }
  }
  
  /// Ayetleri sırayla çal (sessiz olanları biriktir)
  Future<void> _playAyahRecursive(int surah, int ayah, int totalAyahs, int sessionId) async {
    // Session kontrolü - bu session hala aktif mi?
    if (sessionId != _currentSessionId) {
      print('⏹️ Eski session durduruldu (session $sessionId != $_currentSessionId)');
      return;
    }
    
    // İptal kontrolü
    if (_isCancelled) {
      print('⏹️ Oynatma iptal edildi');
      return;
    }
    
    if (ayah > totalAyahs) {
      // Tüm ayetler bitti
      _stopPlaying();
      return;
    }
    
    final filePath = await _getAudioFilePath(surah, ayah);
    
    // Session ve iptal kontrolü tekrar (download sırasında değişmiş olabilir)
    if (sessionId != _currentSessionId || _isCancelled) {
      print('⏹️ Oynatma iptal edildi veya session değişti');
      return;
    }
    
    if (filePath == null) {
      // Dosya indirilemedi, sonraki ayete geç
      await _playAyahRecursive(surah, ayah + 1, totalAyahs, sessionId);
      return;
    }
    
    // Sessiz ayet mi kontrol et
    final isSilent = _silentAyahsCount.containsKey('${surah}_$ayah');
    
    if (isSilent) {
      print('⏭️ Sessiz ayet atlandı: $surah:$ayah');
      // Sessiz ayeti atla, sonraki ayete geç
      await _playAyahRecursive(surah, ayah + 1, totalAyahs, sessionId);
    } else {
      // Normal ayet - sadece bu ayeti vurgula
      _currentAyah = ayah;
      _currentSurah = surah;
      
      // Sadece çalan ayeti vurgula
      _highlightedAyahs = [ayah];
      
      print('🎵 Çalınıyor: $surah:$ayah');
      
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
      
      // Sayfa değişikliği gerekebilir - callback çağır (ayet çalmaya başladıktan SONRA)
      if (onPageChangeNeeded != null && !_isCancelled && sessionId == _currentSessionId) {
        onPageChangeNeeded!(surah, ayah);
      }
      
      // Sesi çal ve hızı ayarla
      await _audioPlayer.play(DeviceFileSource(filePath));
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
      
      // Ses bitene kadar bekle
      await _audioPlayer.onPlayerComplete.first;
      
      // Session kontrolü (ses çalarken session değişmiş olabilir)
      if (sessionId != _currentSessionId || _isCancelled) {
        print('⏹️ Oynatma iptal edildi veya session değişti');
        return;
      }
      
      // Vurgulananları temizle, sonraki ayet için
      _highlightedAyahs.clear();
      
      // Sonraki ayete geç
      if (ayah + 1 <= totalAyahs) {
        // Aynı sure içinde devam et
        await _playAyahRecursive(surah, ayah + 1, totalAyahs, sessionId);
      } else {
        // Sure bitti, bir sonraki sureye geç
        print('✅ Sure $surah tamamlandı');
        
        // Sonraki sure var mı kontrol et
        if (surah < 114 && _chaptersMap != null && !_isCancelled && sessionId == _currentSessionId) {
          final nextSurah = surah + 1;
          final nextChapter = _chaptersMap![nextSurah];
          
          if (nextChapter != null) {
            final nextTotalAyahs = nextChapter.versesCount;
            print('▶️ Sonraki sureye geçiliyor: $nextSurah (${nextChapter.nameTurkish}) - $nextTotalAyahs ayet');
            
            // Sonraki sureyi başlat (1. ayetten)
            await playAyah(nextSurah, 1, totalAyahs: nextTotalAyahs, chapters: _chaptersMap);
          } else {
            print('ℹ️ Sonraki sure bilgisi bulunamadı');
            _stopPlaying();
          }
        } else {
          // Son sure de bitti veya chapters map yok veya session değişti
          if (surah >= 114) {
            print('🎊 Kuran-ı Kerim tamamlandı!');
          }
          _stopPlaying();
        }
      }
    }
  }
  
  /// Ses tamamlandığında
  void _onAudioComplete() {
    // Recursive fonksiyon halledecek
  }
  
  /// Sesi durdur
  Future<void> stopAudio() async {
    _isCancelled = true; // İşlemi iptal et
    await _audioPlayer.stop();
    _stopPlaying();
  }
  
  /// Sesi duraklat
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }
  
  /// Sesi devam ettir
  Future<void> resumeAudio() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }
  
  /// Oynatmayı durdur ve temizle
  void _stopPlaying() {
    _isCancelled = true; // İşlemi iptal et
    _isPlaying = false;
    _isLoading = false;
    _currentSurah = null;
    _currentAyah = null;
    _highlightedAyahs.clear();
    notifyListeners();
  }
  
  /// Belirli bir ayet çalıyor mu?
  bool isAyahPlaying(int surah, int ayah) {
    return _currentSurah == surah && 
           _currentAyah == ayah && 
           _isPlaying;
  }
  
  /// Sure çalıyor mu?
  bool isSurahPlaying(int surah) {
    return _currentSurah == surah && _isPlaying;
  }
  
  /// Playback hızını ayarla
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _audioPlayer.setPlaybackRate(speed);
    notifyListeners();
  }
  
  /// Scroll pozisyonundan görünen sureyi kaydet
  void setVisibleSurah(int surahId) {
    if (_visibleSurah != surahId) {
      _visibleSurah = surahId;
      print('📜 Görünen sure: $surahId');
      notifyListeners();
    }
  }
  
  /// Önceki ayete geç
  Future<void> previousAyah() async {
    if (_currentAyah == null || _currentSurah == null || _totalAyahs == null) return;
    
    final surah = _currentSurah!;
    final ayah = _currentAyah!;
    final total = _totalAyahs!;
    
    if (ayah > 1) {
      // Aynı sure içinde önceki ayete git (örn: 2 → 1, 3 → 2)
      await stopAudio();
      await playAyah(surah, ayah - 1, totalAyahs: total, skipSurahName: true); // ✅ skipSurahName=true
    } else if (ayah == 1) {
      // 1. ayetteyiz, önce 0. ayete (sure adı) git
      await stopAudio();
      await playAyah(surah, 1, totalAyahs: total); // 0. ayeti çal (skipSurahName=false)
    } else if (ayah == 0 && surah > 1) {
      // 0. ayetteyiz (sure adı), şimdi önceki surenin son ayetine git
      final previousSurah = surah - 1;
      // Önceki surenin toplam ayet sayısını bul
      if (_chaptersMap != null && _chaptersMap!.containsKey(previousSurah)) {
        final previousChapter = _chaptersMap![previousSurah];
        final previousTotal = previousChapter?.versesCount ?? 0;
        if (previousTotal > 0) {
          await stopAudio();
          // Önceki surenin SON ayetinden başla (0. ayeti atla)
          await playAyah(previousSurah, previousTotal, totalAyahs: previousTotal, chapters: _chaptersMap, skipSurahName: true);
        }
      }
    }
  }
  
  /// Sonraki ayete geç
  Future<void> nextAyah() async {
    if (_currentAyah == null || _currentSurah == null || _totalAyahs == null) return;
    
    final surah = _currentSurah!;
    final ayah = _currentAyah!;
    final total = _totalAyahs!;
    
    if (ayah == 0) {
      // 0. ayetteyiz (sure adı), direkt 1. ayete git
      await stopAudio();
      await playAyah(surah, 1, totalAyahs: total, skipSurahName: true); // ✅ 0. ayeti tekrar çalma
    } else if (ayah < total) {
      // Aynı sure içinde sonraki ayete git
      await stopAudio();
      await playAyah(surah, ayah + 1, totalAyahs: total, skipSurahName: true); // ✅ skipSurahName=true
    } else if (_chaptersMap != null && _chaptersMap!.containsKey(surah + 1)) {
      // Son ayetteyiz, sonraki sureye git
      final nextSurah = surah + 1;
      final nextChapter = _chaptersMap![nextSurah];
      final nextTotal = nextChapter?.versesCount ?? 0;
      if (nextTotal > 0) {
        await stopAudio();
        // Sonraki surenin İLK ayetinden başla (0. ayeti ÇALACAK - skipSurahName=false)
        await playAyah(nextSurah, 1, totalAyahs: nextTotal, chapters: _chaptersMap); // ✅ skipSurahName=false (yeni sure)
      }
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
