import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/font_settings_service.dart';
import 'settings_menu_sheet.dart';

/// Tema ayarları bottom sheet
class ThemeSettingsSheet extends StatefulWidget {
  final Function(String themeMode) onThemeChanged;

  const ThemeSettingsSheet({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSettingsSheet> createState() => _ThemeSettingsSheetState();
}

class _ThemeSettingsSheetState extends State<ThemeSettingsSheet> {
  String _selectedTheme = ThemeService.themeModeSystem;
  bool _isLoading = true;
  double _arabicFontSize = FontSettingsService.defaultArabicFontSize;
  double _turkishFontSize = FontSettingsService.defaultTurkishFontSize;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
    _loadFontSizes();
  }

  Future<void> _loadCurrentTheme() async {
    final currentTheme = await ThemeService.getThemeMode();
    setState(() {
      _selectedTheme = currentTheme;
      _isLoading = false;
    });
  }

  Future<void> _loadFontSizes() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    final turkishSize = await FontSettingsService.getTurkishFontSize();
    setState(() {
      _arabicFontSize = arabicSize;
      _turkishFontSize = turkishSize;
    });
  }

  Future<void> _changeTheme(String newTheme) async {
    if (_selectedTheme == newTheme) return;

    setState(() {
      _selectedTheme = newTheme;
    });

    await ThemeService.saveThemeMode(newTheme);
    widget.onThemeChanged(newTheme);

    // Kullanıcıya geri bildirim
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tema "${_getThemeDisplayName(newTheme)}" olarak değiştirildi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case ThemeService.themeModeLight:
        return 'Açık';
      case ThemeService.themeModeDark:
        return 'Koyu';
      case ThemeService.themeModeSystem:
        return 'Sistem';
      default:
        return 'Sistem';
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: (_, __) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Geri tuşuna basıldığında ayarlar menüsüne dön
        Navigator.pop(context);
        _showSettingsMenu(context);
        return false; // Varsayılan geri davranışını engelle
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1E1E1E) : Colors.white,
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
                Icon(Icons.palette_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema Ayarları',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Uygulama temasını seçin',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
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

          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bilgilendirme mesajı
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
                            color: Color(0xFF2E7D32),
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Lütfen istediğiniz temayı seçiniz. Tema değişikliği anında uygulanacaktır.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Tema seçenekleri başlığı
                    Text(
                      'Tema Seçimi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Tema kartları
                    _buildThemeCard(
                      theme: ThemeService.themeModeLight,
                      icon: Icons.light_mode_rounded,
                      title: 'Açık Tema',
                      description: 'Parlak ve rahat görünüm',
                      gradientColors: [Color(0xFFFAF8F3), Color(0xFFF5F1E8)],
                      iconColor: Color(0xFFFFA726),
                      isDark: isDark,
                    ),

                    SizedBox(height: 12),

                    _buildThemeCard(
                      theme: ThemeService.themeModeDark,
                      icon: Icons.dark_mode_rounded,
                      title: 'Koyu Tema',
                      description: 'Göz yormayan karanlık görünüm',
                      gradientColors: [Color(0xFF1E1E1E), Color(0xFF121212)],
                      iconColor: Color(0xFF7E57C2),
                      isDark: isDark,
                    ),

                    SizedBox(height: 12),

                    _buildThemeCard(
                      theme: ThemeService.themeModeSystem,
                      icon: Icons.brightness_auto_rounded,
                      title: 'Sistem',
                      description: 'Cihaz ayarlarını takip et',
                      gradientColors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                      iconColor: Color(0xFF42A5F5),
                      isDark: isDark,
                    ),

                    SizedBox(height: 24),

                    // Önizleme
                    _buildPreviewSection(isDark),

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

  Widget _buildThemeCard({
    required String theme,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required Color iconColor,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == theme;

    return GestureDetector(
      onTap: () => _changeTheme(theme),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Color(0xFF2E7D32)
                : isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade300,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // İkon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: theme == ThemeService.themeModeDark
                    ? Colors.white
                    : iconColor,
                size: 28,
              ),
            ),

            SizedBox(width: 16),

            // Metin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Seçim ikonu
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? Color(0xFF2E7D32) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Color(0xFF2E7D32)
                      : isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    final previewIsDark = _selectedTheme == ThemeService.themeModeDark ||
        (_selectedTheme == ThemeService.themeModeSystem && isDark);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Önizleme',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white.withOpacity(0.9) : Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: previewIsDark
                      ? [Color(0xFF2A2A2A), Color(0xFF242424)]
                      : [Color(0xFFFAF8F3), Color(0xFFF5F1E8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Arapça metin (Fatiha 2. ayet)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'اَلْحَمْدُ لِلّٰهِ رَبِّ الْعَالَم۪ينَۙ',
                      style: TextStyle(
                        fontFamily: 'Elif1',
                        fontSize: _arabicFontSize,
                        fontWeight: FontWeight.w500,
                        height: 2.0,
                        color: previewIsDark
                            ? Color(0xFF4CAF50)
                            : Color(0xFF1a237e),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Türkçe meal
                  Text(
                    'Hamd, âlemlerin Rabbi olan Allah\'a mahsustur.',
                    style: TextStyle(
                      fontSize: _turkishFontSize,
                      height: 1.5,
                      color: previewIsDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
