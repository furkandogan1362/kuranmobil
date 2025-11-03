// Sayfa navigasyonu ve pagination scroll yönetimi
import 'package:flutter/material.dart';
import '../../../services/quran_json_service.dart';

class NavigationHelper {
  static const int _farJumpThreshold = 1;

  /// Belirli bir sayfaya git
  Future<void> goToPage({
    required int targetPage,
    required int currentPage,
    required PageController pageController,
    required int? targetChapterId,
    required Function(int? chapterId) onScrollToChapterIdChanged,
    required Function(bool isJumping) onJumpingStateChanged,
    required Function(int pageNumber) loadPageData,
    required int totalPages,
  }) async {
    // Sayfayı kaydet
    QuranJsonService.saveLastReadPage(targetPage);

    // Hedef sure ID'sini kaydet
    onScrollToChapterIdChanged(targetChapterId);

    final delta = (targetPage - currentPage).abs();
    if (delta >= _farJumpThreshold) {
      // Çok uzak sayfaya geçiş: Önceden veri yükle, anlık jump yap
      onJumpingStateChanged(true);
      
      try {
        // Hedef ve komşu sayfaları önceden yükle
        await loadPageData(targetPage);
        if (targetPage > 1) loadPageData(targetPage - 1);
        if (targetPage < totalPages) loadPageData(targetPage + 1);
        
        // Overlay'in görünmesi için mini bir frame beklet
        await Future.delayed(const Duration(milliseconds: 30));
        
        pageController.jumpToPage(targetPage - 1);
        
        // İçerik yerleşsin, sonra overlay'i yumuşakça kaldır
        await Future.delayed(const Duration(milliseconds: 120));
      } finally {
        onJumpingStateChanged(false);
      }
    } else {
      // Yakın sayfalara yumuşak animasyon
      pageController.animateToPage(
        targetPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// Pagination scroll pozisyonunu güncelle
  void scrollPaginationToPage({
    required int pageNumber,
    required ScrollController paginationScrollController,
    required BuildContext context,
  }) {
    if (paginationScrollController.hasClients) {
      // Ekran genişliğinden hesapla
      final screenWidth = MediaQuery.of(context).size.width;
      final availableWidth = screenWidth - 24; // 12px padding her tarafta
      
      const visibleBoxCount = 9;
      const spacing = 4.0;
      const totalSpacing = spacing * (visibleBoxCount - 1);
      
      final boxWidth = (availableWidth - totalSpacing) / visibleBoxCount;
      final itemWidth = boxWidth + spacing;
      
      final rightPadding = spacing;
      final position = (pageNumber - 1) * itemWidth + rightPadding;
      
      paginationScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Sure başlangıcına scroll yap
  void performScrollToChapter({
    required int chapterId,
    required int currentPage,
    required Map<int, Map<int, GlobalKey>> pageKeys,
  }) {
    if (pageKeys[currentPage]?.containsKey(chapterId) == true) {
      final key = pageKeys[currentPage]![chapterId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      }
    }
  }
}
