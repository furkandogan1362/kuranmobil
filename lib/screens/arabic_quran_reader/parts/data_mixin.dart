// arabic_quran_reader_screen.dart'dan ayrıldı: veri yükleme, başlangıç ve önbellek yönetimi
part of '../../arabic_quran_reader_screen.dart';

mixin ArabicQuranDataMixin on _ArabicQuranStateContract {
  Future<void> _loadFontSettings() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    setState(() {
      this._arabicFontSize = arabicSize;
    });
  }

  Future<void> _loadViewMode() async {
    final viewMode = await ViewSettingsService.getViewMode();
    setState(() {
      this._viewMode = viewMode;
    });
  }

  void _updateFontSizes(double arabicSize, double turkishSize) {
    setState(() {
      this._arabicFontSize = arabicSize;
    });
  }

  Future<void> _loadLastPageAndInit() async {
    final lastPage = await QuranJsonService.getLastReadPage();
    setState(() {
      this._currentPage = lastPage;
      this._initialPage = lastPage - 1;
    });

    this._pageController = PageController(initialPage: this._initialPage);
    await _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      this._isLoading = true;
      this._errorMessage = null;
    });

    try {
      await _loadPageData(this._currentPage);

      setState(() {
        this._isLoading = false;
        this._currentVisibleChapterId = this._pageChapters[this._currentPage]?.id;
        this._lastSelectedChapterId = this._pageChapters[this._currentPage]?.id;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        this._scrollPaginationToPage(this._currentPage);

        final scrollController = this._pageScrollControllers[this._currentPage];
        if (scrollController != null && scrollController.hasClients) {
          final savedPosition = await QuranJsonService.getLastScrollPosition(this._currentPage);
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

      if (this._currentPage > 1) _loadPageData(this._currentPage - 1);
      if (this._currentPage < this.totalPages) _loadPageData(this._currentPage + 1);
      if (this._currentPage + 1 < this.totalPages) _loadPageData(this._currentPage + 2);
    } catch (e) {
      setState(() {
        this._isLoading = false;
        this._errorMessage = 'Veriler yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _loadPageData(int pageNumber) async {
    if (this._pageVerses.containsKey(pageNumber)) {
      return;
    }

    try {
      final verses = await this._jsonService.getVersesByPage(pageNumber);

      if (verses.isNotEmpty) {
        final mainChapterId = verses[0].chapterId;
        final mainChapter = await this._jsonService.getChapterFromCache(mainChapterId);

        final uniqueChapterIds = verses.map((v) => v.chapterId).toSet();

        for (final chapterId in uniqueChapterIds) {
          if (!this._chapterCache.containsKey(chapterId)) {
            final chapter = await this._jsonService.getChapterFromCache(chapterId);
            this._chapterCache[chapterId] = chapter;
          }
        }

        setState(() {
          this._pageVerses[pageNumber] = verses;
          this._pageChapters[pageNumber] = mainChapter;
        });
      }
    } catch (e) {
      // Yükleme hatalarını sessizce logla
      // ignore: avoid_print
      print('Sayfa $pageNumber yüklenirken hata: $e');
    }
  }
}
