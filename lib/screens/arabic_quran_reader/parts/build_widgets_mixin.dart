// arabic_quran_reader_screen.dart'dan ayrıldı: UI bileşenleri ve ayet/sayfa render işlemleri
part of '../../arabic_quran_reader_screen.dart';

mixin ArabicQuranBuildWidgetsMixin on _ArabicQuranStateContract {
  Widget _buildFixedHeader() {
    final displayChapterId = this._currentVisibleChapterId ?? this._pageChapters[this._currentPage]?.id;
    final chapter = displayChapterId != null ? this._chapterCache[displayChapterId] : this._pageChapters[this._currentPage];

    return QuranReaderHeader(
      headerKey: this._headerKey,
      chapter: chapter,
      displayChapterId: displayChapterId,
      currentPage: this._currentPage,
      totalPages: this.totalPages,
      paginationScrollController: this._paginationScrollController,
      onBack: () => Navigator.pop(context),
      onShowSurahList: this._showSurahList,
      onPageSelected: this._goToPage,
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Color(0xFF302F30), Color(0xFF302F30)]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavBarItem(
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                onTap: this._showFontSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color(0xFF2E7D32).withOpacity(0.8),
                    Color(0xFF43A047).withOpacity(0.8),
                  ]
                : [
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2E7D32).withOpacity(isDark ? 0.15 : 0.35),
              blurRadius: 10,
              offset: Offset(0, 3),
              spreadRadius: 0,
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(0, -1),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranPage(int pageNumber, Chapter chapter, List<Verse> verses) {
    if (!this._pageKeys.containsKey(pageNumber)) {
      this._pageKeys[pageNumber] = {};
    }

    if (!this._pageScrollControllers.containsKey(pageNumber)) {
      final scrollController = ScrollController();
      this._pageScrollControllers[pageNumber] = scrollController;

      scrollController.addListener(() {
        this._updateVisibleChapter(pageNumber);
        this._scheduleScrollSave(pageNumber);
      });
    }

    final scrollController = this._pageScrollControllers[pageNumber]!;
    final isWideView = this._viewMode == ViewSettingsService.wideView;

    List<Widget> pageContent = [];
    int? lastChapterId;
    bool isFirstVerseOfPage = true;

    // Dinamik görünümde tüm ayetleri topla
    List<Verse> dynamicVerses = [];

    for (var verse in verses) {
      // Yeni bir sure başladı mı kontrol et
      if (verse.chapterId != lastChapterId) {
        // Eğer dinamik görünümdeyse ve toplanan ayetler varsa önce onları ekle
        if (!isWideView && dynamicVerses.isNotEmpty) {
          pageContent.add(this._buildDynamicVerses(dynamicVerses));
          dynamicVerses.clear();
        }

        if (verse.verseNumber == 1) {
          final key = GlobalKey();
          this._pageKeys[pageNumber]![verse.chapterId] = key;
          final chapterInfo = this._chapterCache[verse.chapterId];
          final surahName = chapterInfo?.nameTurkish ?? 'Yükleniyor...';
          pageContent.add(
            SurahHeader(
              key: key,
              chapterId: verse.chapterId,
              surahName: surahName,
              showBesmele: true,
            ),
          );
        }
        lastChapterId = verse.chapterId;
        isFirstVerseOfPage = false;
      }

      // Geniş görünümde her ayeti ayrı ekle
      if (isWideView) {
        pageContent.add(
          this._buildArabicVerse(verse, isFirstVerseOfPage),
        );
        isFirstVerseOfPage = false;
      } else {
        // Dinamik görünümde ayetleri topla
        dynamicVerses.add(verse);
      }
    }

    // Dinamik görünümde kalan ayetleri ekle
    if (!isWideView && dynamicVerses.isNotEmpty) {
      pageContent.add(this._buildDynamicVerses(dynamicVerses));
    }

    if (this._scrollToChapterId != null && this._pageKeys[pageNumber]?.containsKey(this._scrollToChapterId) == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = this._pageKeys[pageNumber]![this._scrollToChapterId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0,
          );
          this.setState(() {
            this._scrollToChapterId = null;
          });
        }
      });
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ...pageContent,
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              '$pageNumber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArabicVerse(Verse verse, bool isFirst) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSajdah = verse.isSajdahVerse();
    final isWideView = this._viewMode == ViewSettingsService.wideView;

    return Column(
      children: [
        // Ayraç SADECE geniş görünümde göster, dinamik görünümde HİÇ GÖSTERME
        if (!isFirst && isWideView) 
          VerseSeparator(),

        // Secde Badge (geniş görünümde)
        if (isSajdah && isWideView)
          Padding(
            padding: EdgeInsets.only(bottom: 8, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8E24AA).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.motion_photos_pause_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SECDE AYETİ',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Arapça metin
        Padding(
          padding: isWideView 
              ? EdgeInsets.symmetric(vertical: 8, horizontal: 4)
              : EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: verse.textUthmani,
                        style: TextStyle(
                          fontFamily: 'Elif1',
                          fontSize: this._arabicFontSize,
                          height: isWideView ? 2.2 : 1.3,
                          fontWeight: FontWeight.w500,
                          // Secde ayetleri için renkli vurgu
                          color: isSajdah
                              ? (isDark 
                                  ? Color(0xFFFF99CC) // Karanlık mod: Açık pembe
                                  : Color(0xFFbd2d2d)) // Aydınlık mod: Açık mor (eski mordan daha açık)
                              : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
                        ),
                      ),
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            verse.getArabicVerseNumber(),
                            style: TextStyle(
                              fontFamily: 'ShaikhHamdullah',
                              fontSize: 18,
                              color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Dinamik görünüm için - Tüm ayetler yan yana, alt satıra atlamadan
  Widget _buildDynamicVerses(List<Verse> verses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tüm elemanları sırayla oluştur
    List<InlineSpan> spans = [];

    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final isSajdah = verse.isSajdahVerse();

      // Ayet metni
      spans.add(
        TextSpan(
          text: verse.textUthmani,
          style: TextStyle(
            color: isSajdah
                ? (isDark 
                    ? Color(0xFFFF99CC) // Karanlık mod: Açık pembe
                    : Color(0xFFbd2d2d)) // Aydınlık mod: Açık mor
                : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
          ),
        ),
      );

      spans.add(TextSpan(text: ' '));

      // Bir SONRAKİ ayetin secde ayeti olup olmadığını kontrol et
      // Secde badge'ini ayet numarasından ÖNCE ekle
      if (i + 1 < verses.length && verses[i + 1].isSajdahVerse()) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.only(left: 6, right: 6),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8E24AA).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.motion_photos_pause_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SECDE AYETİ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        spans.add(TextSpan(text: ' '));
      }

      // Ayet numarası
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.only(right: 2, left: 2),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                width: 2,
              ),
            ),
            child: Text(
              verse.getArabicVerseNumber(),
              style: TextStyle(
                fontFamily: 'ShaikhHamdullah',
                fontSize: 18,
                color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

      spans.add(TextSpan(text: ' '));
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Elif1',
              fontSize: this._arabicFontSize,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
            ),
            children: spans,
          ),
        ),
      ),
    );
  }
}
