import 'package:flutter/material.dart';
import '../services/view_settings_service.dart';
import '../services/quran_json_service.dart';
import '../services/font_settings_service.dart';
import '../models/verse.dart';
import 'settings_menu_sheet.dart';
import 'verse_separator.dart';

/// Görünüm ayarları bottom sheet
class ViewSettingsSheet extends StatefulWidget {
  final Function()? onViewModeChanged;
  final Function(double arabicSize, double turkishSize)? onFontSizeChanged;
  final Function(String themeMode)? onThemeChanged;

  const ViewSettingsSheet({
    super.key,
    this.onViewModeChanged,
    this.onFontSizeChanged,
    this.onThemeChanged,
  });

  @override
  State<ViewSettingsSheet> createState() => _ViewSettingsSheetState();
}

class _ViewSettingsSheetState extends State<ViewSettingsSheet> {
  String _selectedViewMode = ViewSettingsService.defaultViewMode;
  bool _isLoading = true;
  List<Verse> _kevserVerses = [];
  final QuranJsonService _jsonService = QuranJsonService();
  
  // Kullanıcının font ayarları
  double _arabicFontSize = FontSettingsService.defaultArabicFontSize;
  double _turkishFontSize = FontSettingsService.defaultTurkishFontSize;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadKevserVerses();
    _loadFontSettings();
  }
  
  Future<void> _loadFontSettings() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    final turkishSize = await FontSettingsService.getTurkishFontSize();
    setState(() {
      _arabicFontSize = arabicSize;
      _turkishFontSize = turkishSize;
    });
  }

  Future<void> _loadViewMode() async {
    final viewMode = await ViewSettingsService.getViewMode();
    setState(() {
      _selectedViewMode = viewMode;
    });
  }

  Future<void> _loadKevserVerses() async {
    try {
      // Sure 108 - Kevser suresi (3 ayet)
      final verses = await _jsonService.getVersesByChapter(108);
      setState(() {
        _kevserVerses = verses;
        _isLoading = false;
      });
    } catch (e) {
      print('Kevser suresi yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectViewMode(String mode) {
    setState(() {
      _selectedViewMode = mode;
    });
    ViewSettingsService.saveViewMode(mode);
    
    // Callback'i çağır
    if (widget.onViewModeChanged != null) {
      widget.onViewModeChanged!();
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: widget.onFontSizeChanged ?? (a, t) {},
        onThemeChanged: widget.onThemeChanged,
        onViewModeChanged: widget.onViewModeChanged, // Callback'i koru!
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        _showSettingsMenu(context);
        return false;
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF302F30) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Color(0xFF2E7D32),
                          Color(0xFF388E3C),
                        ]
                      : [
                          Color(0xFF1a237e),
                          Color(0xFF283593),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.view_compact_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Görünüm Ayarları',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSettingsMenu(context);
                    },
                  ),
                ],
              ),
            ),

            // İçerik
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bilgi kutusu
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color(0xFF2E7D32).withOpacity(0.25)
                            : Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF2E7D32).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 24,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kur\'an okuma deneyiminizi kişiselleştirin. Tercih ettiğiniz görünüm modunu seçin.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withOpacity(0.85)
                                    : Color(0xFF1B5E20),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Geniş Görünüm
                    _buildViewModeCard(
                      title: 'Geniş Görünüm',
                      description:
                          'Yayvan düzen ve geniş satır aralıkları ile rahat okuma. Ayetler arasında ayraç kullanılır ve her ayet geniş bir alana yayılır.',
                      icon: Icons.expand,
                      mode: ViewSettingsService.wideView,
                      isDark: isDark,
                    ),

                    SizedBox(height: 16),

                    // Dinamik Görünüm
                    _buildViewModeCard(
                      title: 'Dinamik Görünüm',
                      description:
                          'Kompakt ve verimli düzen. Satır araları yakın, ayetler akıcı şekilde gösterilir.',
                      icon: Icons.view_compact_alt,
                      mode: ViewSettingsService.dynamicView,
                      isDark: isDark,
                    ),

                    SizedBox(height: 24),

                    // Önizleme başlığı
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 20,
                          color: isDark ? Colors.white.withOpacity(0.9) : Color(0xFF1a237e),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Önizleme - Kevser Sûresi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white.withOpacity(0.9) : Color(0xFF1a237e),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Önizleme
                    _buildPreview(isDark),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeCard({
    required String title,
    required String description,
    required IconData icon,
    required String mode,
    required bool isDark,
    bool isComingSoon = false,
  }) {
    final isSelected = _selectedViewMode == mode && !isComingSoon;

    return InkWell(
      onTap: isComingSoon ? null : () => _selectViewMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Color(0xFF2E7D32).withOpacity(0.3) : Color(0xFF2E7D32).withOpacity(0.15))
              : (isDark ? Color(0xFF3A393A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Color(0xFF2E7D32)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isComingSoon
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      )
                    : LinearGradient(
                        colors: isSelected
                            ? [Color(0xFF2E7D32), Color(0xFF388E3C)]
                            : [Color(0xFF757575), Color(0xFF9E9E9E)],
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),

            SizedBox(width: 16),

            // Metin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isComingSoon
                                ? Colors.grey.shade500
                                : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                          ),
                        ),
                      ),
                      if (isComingSoon)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Yakında',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isComingSoon
                          ? Colors.grey.shade400
                          : (isDark ? Colors.white.withOpacity(0.7) : Colors.black54),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Seçim işareti
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Color(0xFF2E7D32).withOpacity(0.15),
                    Color(0xFF388E3C).withOpacity(0.15),
                  ]
                : [
                    Color(0xFFFAF8F3),
                    Color(0xFFF5F1E8),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    // Geniş görünüm önizlemesi
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Color(0xFF2E7D32).withOpacity(0.15),
                  Color(0xFF388E3C).withOpacity(0.15),
                ]
              : [
                  Color(0xFFFAF8F3),
                  Color(0xFFF5F1E8),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sure başlığı
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Color(0xFF2E7D32).withOpacity(0.2),
                        Color(0xFF4CAF50).withOpacity(0.2),
                      ]
                    : [
                        Color(0xFF1a237e).withOpacity(0.08),
                        Color(0xFF2E7D32).withOpacity(0.08),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'الْكَوْثَر - Kevser Sûresi',
              style: TextStyle(
                fontFamily: 'Elif1',
                fontSize: _turkishFontSize, // Türkçe başlık için kullanıcının Türkçe font boyutu
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFF4CAF50) : Color(0xFF1a237e),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 16),

          // Ayetler (Geniş görünüm)
          if (_selectedViewMode == ViewSettingsService.wideView) ...[
            ..._kevserVerses.asMap().entries.map((entry) {
              final index = entry.key;
              final verse = entry.value;
              return Column(
                children: [
                  if (index > 0) VerseSeparator(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: verse.textUthmani,
                              style: TextStyle(
                                fontFamily: 'Elif1',
                                fontSize: _arabicFontSize * 0.70, // Kullanıcının font boyutunun %70'i (daha büyük)
                                height: 2.2,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withOpacity(0.95)
                                    : Colors.black87,
                              ),
                            ),
                            TextSpan(text: ' '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Container(
                                margin: EdgeInsets.only(right: 4),
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Color(0xFFB8976A)
                                        : Color(0xFFB8976A),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  verse.getArabicVerseNumber(),
                                  style: TextStyle(
                                    fontFamily: 'ShaikhHamdullah',
                                    fontSize: _arabicFontSize * 0.30, // Ayet numarası için %30 (daha büyük)
                                    color: isDark
                                        ? Color(0xFFB8976A)
                                        : Color(0xFFB8976A),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ] else ...[
            // Dinamik görünüm önizlemesi - Ayetler yan yana, alt satıra atlamadan
            Directionality(
              textDirection: TextDirection.rtl,
              child: RichText(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Elif1',
                    fontSize: _arabicFontSize * 0.70,
                    height: 1.2, // Daha da kompakt satır aralığı
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withOpacity(0.95)
                        : Colors.black87,
                  ),
                  children: _kevserVerses.expand((verse) {
                    return [
                      TextSpan(text: verse.textUthmani),
                      TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: EdgeInsets.only(right: 2, left: 2), // Boşluklar azaltıldı
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? Color(0xFFB8976A)
                                  : Color(0xFFB8976A),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            verse.getArabicVerseNumber(),
                            style: TextStyle(
                              fontFamily: 'ShaikhHamdullah',
                              fontSize: _arabicFontSize * 0.30,
                              color: isDark
                                  ? Color(0xFFB8976A)
                                  : Color(0xFFB8976A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: ' '), // Ayet numarasından sonra boşluk
                    ];
                  }).toList(),
                ),
              ),
            ),
          ],

          SizedBox(height: 12),

          // Açıklama
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Color(0xFF2E7D32).withOpacity(0.2)
                  : Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedViewMode == ViewSettingsService.wideView
                        ? 'Geniş görünüm: Ayetler rahat okuma için geniş aralıklarla ve ayraçlarla gösterilir'
                        : 'Dinamik görünüm: Kompakt düzen, satır araları yakın, daha fazla içerik bir arada',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white.withOpacity(0.7) : Color(0xFF1B5E20),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
