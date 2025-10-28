import 'package:flutter/material.dart';
import 'package:kuranmobil/models/chapter.dart';

class QuranReaderHeader extends StatelessWidget {
  const QuranReaderHeader({
    super.key,
    required this.headerKey,
    required this.chapter,
    required this.displayChapterId,
    required this.currentPage,
    required this.totalPages,
    required this.paginationScrollController,
    required this.onBack,
    required this.onShowSurahList,
    required this.onPageSelected,
  });

  final GlobalKey headerKey;
  final Chapter? chapter;
  final int? displayChapterId;
  final int currentPage;
  final int totalPages;
  final ScrollController paginationScrollController;
  final VoidCallback onBack;
  final VoidCallback onShowSurahList;
  final void Function(int pageNumber) onPageSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      key: headerKey,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Color(0xFF4CAF50) : Color(0xFF1a237e),
                  ),
                  onPressed: onBack,
                  iconSize: 22,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                Expanded(
                  child: Column(
                    key: ValueKey('header_chapter_$displayChapterId'),
                    children: [
                      Text(
                        chapter?.nameArabic ?? '...',
                        style: TextStyle(
                          fontFamily: 'ShaikhHamdullah',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Color(0xFF4CAF50) : Color(0xFF1a237e),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapter?.nameTurkish ?? 'Yükleniyor...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Sayfa $currentPage',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.menu_book_rounded,
                        color: isDark ? Color(0xFF4CAF50) : Color(0xFF2E7D32),
                        size: 24,
                      ),
                      onPressed: onShowSurahList,
                      tooltip: 'Sureler',
                      padding: EdgeInsets.all(6),
                      constraints: BoxConstraints(),
                    ),
                    Text(
                      'Sureler',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Color(0xFF4CAF50) : Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              controller: paginationScrollController,
              scrollDirection: Axis.horizontal,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final isSelected = pageNum == currentPage;
                return GestureDetector(
                  onTap: () => onPageSelected(pageNum),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Color(0xFF4CAF50) : const Color(0xFF2E7D32))
                          : (isDark ? Color(0xFF2A2A2A) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (isDark ? Color(0xFF4CAF50) : const Color(0xFF2E7D32)).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
