#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Google Fonts kullanımlarını TextStyle ile değiştir (offline için)
"""

import re
import os

def replace_google_fonts_in_file(filepath):
    """Bir dosyadaki GoogleFonts kullanımlarını TextStyle ile değiştir."""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # GoogleFonts.notoSans(...) -> TextStyle(...) 
    # Örnek: GoogleFonts.notoSans(fontSize: 16, color: Colors.white)
    # Sonuç: TextStyle(fontSize: 16, color: Colors.white)
    
    pattern = r'GoogleFonts\.notoSans\('
    replacement = r'TextStyle('
    content = re.sub(pattern, replacement, content)
    
    # GoogleFonts.notoSansTextTheme() kullanımını kaldır
    content = content.replace('import \'package:google_fonts/google_fonts.dart\';\n', '')
    
    # Eğer değişiklik olduysa dosyayı kaydet
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ {filepath} güncellendi")
        return True
    else:
        print(f"⚪ {filepath} değişiklik yok")
        return False

def main():
    """Ana fonksiyon"""
    print("=" * 80)
    print("🔧 Google Fonts -> TextStyle Dönüştürücü")
    print("=" * 80)
    print()
    
    # İşlenecek dosyalar
    files = [
        'lib/screens/home_screen.dart',
        'lib/screens/quran_reader_screen.dart',
    ]
    
    updated_count = 0
    
    for filepath in files:
        if os.path.exists(filepath):
            if replace_google_fonts_in_file(filepath):
                updated_count += 1
        else:
            print(f"⚠️  {filepath} bulunamadı")
    
    print()
    print("=" * 80)
    print(f"✅ {updated_count} dosya güncellendi")
    print("=" * 80)

if __name__ == "__main__":
    main()
