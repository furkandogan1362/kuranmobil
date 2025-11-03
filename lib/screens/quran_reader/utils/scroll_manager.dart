// Kur'an okuyucu ekranı için scroll pozisyon yönetimi ve görünür sure takibi
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/quran_json_service.dart';
import '../../../models/chapter.dart';

class ScrollManager {
  static const Duration _scrollSaveDelay = Duration(milliseconds: 500);
  Timer? _scrollSaveTimer;

  /// Scroll pozisyonunu kaydetmeyi zamanla (debouncing)
  void scheduleScrollSave({
    required int pageNumber,
    required int currentPage,
    required Map<int, ScrollController> pageScrollControllers,
  }) {
    // Sadece mevcut sayfa için kaydet
    if (pageNumber != currentPage) return;

    // Önceki timer'ı iptal et
    _scrollSaveTimer?.cancel();

    // Yeni timer başlat - 500ms sonra kaydet
    _scrollSaveTimer = Timer(_scrollSaveDelay, () {
      final scrollController = pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        QuranJsonService.saveLastScrollPosition(
          pageNumber,
          scrollController.offset,
        );
      }
    });
  }

  /// Scroll pozisyonuna göre görünür surenin ID'sini güncelle
  int? updateVisibleChapter({
    required int pageNumber,
    required int currentPage,
    required Map<int, ScrollController> pageScrollControllers,
    required Map<int, Map<int, GlobalKey>> pageKeys,
    required Map<int, Chapter> pageChapters,
    required GlobalKey headerKey,
  }) {
    if (pageNumber != currentPage) return null; // Sadece aktif sayfa için çalış

    final scrollController = pageScrollControllers[pageNumber];
    if (scrollController == null || !scrollController.hasClients) return null;

    final pageKeysMap = pageKeys[pageNumber];
    if (pageKeysMap == null || pageKeysMap.isEmpty) return null;

    // Header'ın ekrandaki alt sınırını dinamik olarak ölç
    double headerBottom = 0.0;
    try {
      final headerBox =
          headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null) {
        final headerTop = headerBox.localToGlobal(Offset.zero).dy;
        headerBottom = headerTop + headerBox.size.height;
      }
    } catch (_) {
      headerBottom = headerBottom == 0.0 ? 180.0 : headerBottom;
    }
    
    const epsilon = 0.5;

    // Her sure başlangıcının ekrandaki pozisyonunu kontrol et
    int? newVisibleChapterId;
    final positions = <MapEntry<int, double>>[];

    // Mevcut sayfada render edilmiş tüm sure başlıklarının tepe (top) konumlarını topla
    pageKeysMap.forEach((chapterId, key) {
      final context = key.currentContext;
      if (context != null) {
        try {
          final box = context.findRenderObject() as RenderBox;
          final top = box.localToGlobal(Offset.zero).dy;
          positions.add(MapEntry(chapterId, top));
        } catch (_) {}
      }
    });

    if (positions.isNotEmpty) {
      positions.sort((a, b) => a.value.compareTo(b.value));
      final underHeader = positions
          .where((e) => e.value <= headerBottom + epsilon)
          .toList();
      if (underHeader.isNotEmpty) {
        newVisibleChapterId = underHeader.last.key;
      } else {
        newVisibleChapterId = pageChapters[pageNumber]?.id;
      }
    }

    return newVisibleChapterId;
  }

  /// Çalan ayete otomatik scroll
  void scrollToPlayingVerse({
    required int pageNumber,
    required int surahId,
    required int verseNumber,
    required Map<int, Map<int, GlobalKey>> pageKeys,
    required Map<int, Map<String, GlobalKey>> verseKeys,
  }) {
    // 0. ayet (sure adı) için özel kontrol
    if (verseNumber == 0) {
      final surahHeaderKey = pageKeys[pageNumber]?[surahId];
      
      if (surahHeaderKey?.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            surahHeaderKey!.currentContext!,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.15,
          );
        } catch (e) {
          print('⚠️ SurahHeader scroll hatası: $e');
        }
      }
      return;
    }
    
    // Normal ayetler için
    final verseKeyId = '${surahId}_$verseNumber';
    final verseKey = verseKeys[pageNumber]?[verseKeyId];
    
    if (verseKey?.currentContext != null) {
      try {
        Scrollable.ensureVisible(
          verseKey!.currentContext!,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
      } catch (e) {
        print('⚠️ Scroll hatası: $e');
      }
    }
  }

  /// Timer'ı temizle
  void dispose() {
    _scrollSaveTimer?.cancel();
  }
}
