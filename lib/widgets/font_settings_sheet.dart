import 'package:flutter/material.dart';
import '../services/font_settings_service.dart';
import '../services/quran_json_service.dart';
import '../models/verse.dart';
import 'settings_menu_sheet.dart';

/// Font ayarları bottom sheet
class FontSettingsSheet extends StatefulWidget {
  final Function(double arabicSize, double turkishSize) onFontSizeChanged;
  final Function(String themeMode)? onThemeChanged;
  final Function()? onViewModeChanged;

  const FontSettingsSheet({
    super.key,
    required this.onFontSizeChanged,
    this.onThemeChanged,
    this.onViewModeChanged,
  });

  @override
  State<FontSettingsSheet> createState() => _FontSettingsSheetState();
}

class _FontSettingsSheetState extends State<FontSettingsSheet> {
  double _arabicFontSize = FontSettingsService.defaultArabicFontSize;
  double _turkishFontSize = FontSettingsService.defaultTurkishFontSize;
  bool _isLoading = true;
  Verse? _previewVerse;
  final QuranJsonService _jsonService = QuranJsonService();

  @override
  void initState() {
    super.initState();
    _loadFontSizes();
    _loadPreviewVerse();
  }

  Future<void> _loadFontSizes() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    final turkishSize = await FontSettingsService.getTurkishFontSize();
    
    setState(() {
      _arabicFontSize = arabicSize;
      _turkishFontSize = turkishSize;
    });
  }
  
  Future<void> _loadPreviewVerse() async {
    try {
      // Fatiha suresi 2. ayeti getir
      final verses = await _jsonService.getVersesByChapter(1);
      if (verses.length >= 2) {
        setState(() {
          _previewVerse = verses[1]; // 2. ayet (index 1)
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Önizleme ayeti yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateArabicFontSize(double size) {
    setState(() {
      _arabicFontSize = size;
    });
    FontSettingsService.saveArabicFontSize(size);
    widget.onFontSizeChanged(_arabicFontSize, _turkishFontSize);
  }

  void _updateTurkishFontSize(double size) {
    setState(() {
      _turkishFontSize = size;
    });
    FontSettingsService.saveTurkishFontSize(size);
    widget.onFontSizeChanged(_arabicFontSize, _turkishFontSize);
  }

  Future<void> _resetToDefaults() async {
    await FontSettingsService.resetToDefaults();
    setState(() {
      _arabicFontSize = FontSettingsService.defaultArabicFontSize;
      _turkishFontSize = FontSettingsService.defaultTurkishFontSize;
    });
    widget.onFontSizeChanged(_arabicFontSize, _turkishFontSize);
  }
  
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: widget.onFontSizeChanged,
        onThemeChanged: widget.onThemeChanged,
        onViewModeChanged: widget.onViewModeChanged, // Callback'i koru!
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Container(
        height: 500,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF302F30) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuna basıldığında ayarlar menüsüne dön
        Navigator.pop(context);
        _showSettingsMenu(context);
        return false; // Varsayılan geri davranışını engelle
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
          // Başlık - Padding artırıldı
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
                Icon(Icons.settings, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Font Ayarları',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _resetToDefaults,
                  tooltip: 'Varsayılana Sıfırla',
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    // Font ayarları menüsünü kapat
                    Navigator.pop(context);
                    // Ayarlar menüsüne dön
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
                  // Arapça Font Ayarı
                  _buildFontSizeSection(
                    title: 'Arapça Metin Boyutu',
                    currentSize: _arabicFontSize,
                    minSize: FontSettingsService.minArabicFontSize,
                    maxSize: FontSettingsService.maxArabicFontSize,
                    onChanged: _updateArabicFontSize,
                    isArabic: true,
                  ),

                  SizedBox(height: 32),

                  // Türkçe Font Ayarı
                  _buildFontSizeSection(
                    title: 'Türkçe Metin Boyutu',
                    currentSize: _turkishFontSize,
                    minSize: FontSettingsService.minTurkishFontSize,
                    maxSize: FontSettingsService.maxTurkishFontSize,
                    onChanged: _updateTurkishFontSize,
                    isArabic: false,
                  ),

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

  Widget _buildFontSizeSection({
    required String title,
    required double currentSize,
    required double minSize,
    required double maxSize,
    required Function(double) onChanged,
    required bool isArabic,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white.withOpacity(0.9) : Color(0xFF1a237e),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${currentSize.toInt()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12),
        
        // Açıklayıcı metin
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? Color(0xFF2E7D32).withOpacity(0.25) 
                : Color(0xFF2E7D32).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Color(0xFF2E7D32).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lütfen yeşil düğmeyi parmağınızla tutarak sağa-sola kaydırınız',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white.withOpacity(0.85) : Color(0xFF1B5E20),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Color(0xFF2E7D32),
            inactiveTrackColor: Color(0xFF2E7D32).withOpacity(0.2),
            thumbColor: Color(0xFF2E7D32),
            overlayColor: Color(0xFF2E7D32).withOpacity(0.2),
            valueIndicatorColor: Color(0xFF2E7D32),
            valueIndicatorTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Slider(
            value: currentSize,
            min: minSize,
            max: maxSize,
            divisions: ((maxSize - minSize) / 2).round(),
            label: currentSize.toInt().toString(),
            onChanged: onChanged,
          ),
        ),

        SizedBox(height: 8),

        // Min-Max göstergesi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Küçük (${minSize.toInt()})',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600,
              ),
            ),
            Text(
              'Büyük (${maxSize.toInt()})',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600,
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        // Önizleme
        _buildPreview(currentSize, isArabic),
      ],
    );
  }

  Widget _buildPreview(double fontSize, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // JSON'dan yüklenen Fatiha 2. ayet
    final arabicText = _previewVerse?.textUthmani ?? 'اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَم۪ينَۙ';
    final turkishText = _previewVerse?.translationTurkish ?? 'Hamd, âlemlerin Rabbi olan Allah\'a mahsustur.';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  Color(0xFF2E7D32).withOpacity(0.25),
                  Color(0xFF388E3C).withOpacity(0.25),
                ]
              : [
                  Color(0xFF2E7D32).withOpacity(0.05),
                  Color(0xFF388E3C).withOpacity(0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF2E7D32).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Başlık
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(width: 8),
              Text(
                'Önizleme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white.withOpacity(0.9) : Color(0xFF2E7D32),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Arapça metin
          Directionality(
            textDirection: TextDirection.rtl,
            child: AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Elif1',
                fontSize: isArabic ? fontSize : _arabicFontSize,
                height: 2.0,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
              ),
              textAlign: TextAlign.right,
              child: Text(arabicText),
            ),
          ),

          SizedBox(height: 12),

          Container(
            height: 1,
            color: isDark 
                ? Colors.white.withOpacity(0.2) 
                : Colors.grey.shade200,
          ),

          SizedBox(height: 12),

          // Türkçe metin
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: isArabic ? _turkishFontSize : fontSize,
              height: 1.6,
              color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
            ),
            textAlign: TextAlign.justify,
            child: Text(turkishText),
          ),
        ],
      ),
    );
  }
}
