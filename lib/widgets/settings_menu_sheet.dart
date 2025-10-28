import 'package:flutter/material.dart';
import 'font_settings_sheet.dart';
import 'theme_settings_sheet.dart';

/// Ana ayarlar menüsü
class SettingsMenuSheet extends StatelessWidget {
  final Function(double arabicSize, double turkishSize) onFontSizeChanged;
  final Function(String themeMode)? onThemeChanged;

  const SettingsMenuSheet({
    super.key,
    required this.onFontSizeChanged,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
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
            padding: EdgeInsets.all(20),
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
                    'Ayarlar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Ayar seçenekleri listesi
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSettingItem(
                  context: context,
                  icon: Icons.text_fields_rounded,
                  title: 'Font Boyutu',
                  subtitle: 'Arapça ve Türkçe metin boyutlarını ayarlayın',
                  onTap: () {
                    // Mevcut menüyü kapat
                    Navigator.pop(context);
                    // Font ayarlarını aç
                    _showFontSettings(context);
                  },
                ),
                
                Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.1) : null),
                
                _buildSettingItem(
                  context: context,
                  icon: Icons.color_lens_rounded,
                  title: 'Tema',
                  subtitle: 'Açık/Koyu tema seçenekleri',
                  onTap: () {
                    // Mevcut menüyü kapat
                    Navigator.pop(context);
                    // Tema ayarlarını aç
                    _showThemeSettings(context);
                  },
                ),
                
                Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.1) : null),
                
                _buildSettingItem(
                  context: context,
                  icon: Icons.bookmark_rounded,
                  title: 'İşaretler (Yakında)',
                  subtitle: 'Yer işaretlerinizi yönetin',
                  onTap: null, // Henüz aktif değil
                  isDisabled: true,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDisabled
                ? [Colors.grey.shade300, Colors.grey.shade400]
                : [
                    Color(0xFF2E7D32),
                    Color(0xFF388E3C),
                  ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDisabled 
              ? Colors.grey.shade500 
              : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: isDisabled 
              ? Colors.grey.shade400 
              : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDisabled 
            ? Colors.grey.shade400 
            : (isDark ? Colors.white.withOpacity(0.3) : Colors.black26),
      ),
      enabled: !isDisabled,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  void _showFontSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FontSettingsSheet(
        onFontSizeChanged: onFontSizeChanged,
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ThemeSettingsSheet(
        onThemeChanged: (themeMode) {
          if (onThemeChanged != null) {
            onThemeChanged!(themeMode);
          }
        },
      ),
    );
  }
}
