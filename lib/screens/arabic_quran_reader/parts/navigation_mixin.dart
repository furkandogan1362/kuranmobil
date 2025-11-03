// arabic_quran_reader_screen.dart'dan ayrıldı: sayfa değişimi, kaydırma ve navigasyon işlemleri
part of '../../arabic_quran_reader_screen.dart';

mixin ArabicQuranNavigationMixin on _ArabicQuranStateContract {
  void _onPageChanged(int index) {
    final pageNumber = index + 1;
    final previousPage = this._currentPage;

    setState(() {
      this._currentPage = pageNumber;
      this._currentVisibleChapterId = this._pageChapters[pageNumber]?.id;
      this._lastSelectedChapterId = this._pageChapters[pageNumber]?.id;
    });

    QuranJsonService.saveLastReadPage(pageNumber);

    if (previousPage != pageNumber) {
      QuranJsonService.clearScrollPosition(previousPage);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scrollController = this._pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        final savedPosition = await QuranJsonService.getLastScrollPosition(pageNumber);
        if (savedPosition > 0) {
          await Future.delayed(Duration(milliseconds: 300));
          if (scrollController.hasClients && this.mounted) {
            scrollController.animateTo(
              savedPosition,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      }
    });

    this._loadPageData(pageNumber);

    if (pageNumber > 1) {
      this._loadPageData(pageNumber - 1);
    }
    if (pageNumber < this.totalPages) {
      this._loadPageData(pageNumber + 1);
    }
    if (pageNumber + 1 < this.totalPages) {
      this._loadPageData(pageNumber + 2);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      this._scrollPaginationToPage(pageNumber);
    });
  }

  void _scrollPaginationToPage(int pageNumber) {
    if (this._paginationScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final availableWidth = screenWidth - 24;

      const visibleBoxCount = 9;
      const spacing = 4.0;
      const totalSpacing = spacing * (visibleBoxCount - 1);

      final boxWidth = (availableWidth - totalSpacing) / visibleBoxCount;
      final itemWidth = boxWidth + spacing;

      final rightPadding = spacing;
      final position = (pageNumber - 1) * itemWidth + rightPadding;

      this._paginationScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int pageNumber, {int? targetChapterId}) {
    QuranJsonService.saveLastReadPage(pageNumber);
    this._scrollToChapterId = targetChapterId;

    final delta = (pageNumber - this._currentPage).abs();
    if (delta >= this._farJumpThreshold) {
      setState(() {
        this._isJumpingFar = true;
      });
      () async {
        try {
          await this._loadPageData(pageNumber);
          if (pageNumber > 1) this._loadPageData(pageNumber - 1);
          if (pageNumber < this.totalPages) this._loadPageData(pageNumber + 1);
          await Future.delayed(const Duration(milliseconds: 30));
          if (!this.mounted) return;
          this._pageController.jumpToPage(pageNumber - 1);
          await Future.delayed(const Duration(milliseconds: 120));
        } finally {
          if (this.mounted) {
            setState(() {
              this._isJumpingFar = false;
            });
          }
        }
      }();
    } else {
      this._pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showSurahList() {
    final currentChapterId = this._lastSelectedChapterId ?? this._pageChapters[this._currentPage]?.id ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahListSheet(
        currentChapterId: currentChapterId,
        onSurahSelected: (pageNumber, chapterId) {
          this._lastSelectedChapterId = chapterId;

          if (pageNumber == this._currentPage) {
            setState(() {
              this._scrollToChapterId = chapterId;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              this._performScrollToChapter(chapterId);
            });
          } else {
            this._goToPage(pageNumber, targetChapterId: chapterId);
          }
        },
      ),
    );
  }

  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: this._updateFontSizes,
        onThemeChanged: widget.onThemeChanged,
        onViewModeChanged: () {
          this._loadViewMode();
        },
      ),
    );
  }

  void _performScrollToChapter(int chapterId) {
    if (this._pageKeys[this._currentPage]?.containsKey(chapterId) == true) {
      final key = this._pageKeys[this._currentPage]![chapterId];
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

  void _scheduleScrollSave(int pageNumber) {
    if (pageNumber != this._currentPage) return;

    this._scrollSaveTimer?.cancel();

    this._scrollSaveTimer = Timer(this._scrollSaveDelay, () {
      final scrollController = this._pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        QuranJsonService.saveLastScrollPosition(pageNumber, scrollController.offset);
      }
    });
  }

  void _updateVisibleChapter(int pageNumber) {
    if (pageNumber != this._currentPage) return;

    final scrollController = this._pageScrollControllers[pageNumber];
    if (scrollController == null || !scrollController.hasClients) return;

    final pageKeysMap = this._pageKeys[pageNumber];
    if (pageKeysMap == null || pageKeysMap.isEmpty) return;

    double headerBottom = 0.0;
    try {
      final headerBox = this._headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null) {
        final headerTop = headerBox.localToGlobal(Offset.zero).dy;
        headerBottom = headerTop + headerBox.size.height;
      }
    } catch (_) {
      headerBottom = headerBottom == 0.0 ? 180.0 : headerBottom;
    }
    const epsilon = 0.5;

    int? newVisibleChapterId;
    final positions = <MapEntry<int, double>>[];

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
      final underHeader = positions.where((e) => e.value <= headerBottom + epsilon).toList();
      if (underHeader.isNotEmpty) {
        newVisibleChapterId = underHeader.last.key;
      } else {
        newVisibleChapterId = this._pageChapters[pageNumber]?.id;
      }
    }

    if (newVisibleChapterId != null && newVisibleChapterId != this._currentVisibleChapterId) {
      setState(() {
        this._currentVisibleChapterId = newVisibleChapterId;
        this._lastSelectedChapterId = newVisibleChapterId;
      });
    }
  }
}
