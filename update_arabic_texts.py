#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tüm ayetlerin Arapça metinlerini API'den çekip all_verses.json dosyasına günceller.
Hatasız çalışması için detaylı loglama ve doğrulama içerir.
"""

import json
import requests
import time
from typing import Dict, List, Any

# API Base URL
API_BASE_URL = "https://api.acikkuran.com"

def fetch_surah(surah_id: int, max_retries: int = 3) -> Dict[str, Any]:
    """
    Belirli bir sureyi API'den çeker.
    
    Args:
        surah_id: Sure ID (1-114)
        max_retries: Maksimum deneme sayısı
    
    Returns:
        Sure verisi (dict)
    """
    url = f"{API_BASE_URL}/surah/{surah_id}?author=11"
    
    for attempt in range(max_retries):
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if 'data' in data and 'verses' in data['data']:
                return data['data']
            else:
                print(f"⚠️  Sure {surah_id}: Beklenmeyen veri yapısı")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"⚠️  Sure {surah_id} çekilirken hata (Deneme {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                time.sleep(2)  # 2 saniye bekle
            else:
                return None
    
    return None

def load_json_file(filepath: str) -> List[Dict[str, Any]]:
    """JSON dosyasını yükler."""
    print(f"📖 JSON dosyası okunuyor: {filepath}")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"✅ {len(data)} ayet yüklendi")
        return data
    except Exception as e:
        print(f"❌ JSON dosyası okunamadı: {e}")
        raise

def save_json_file(filepath: str, data: List[Dict[str, Any]]):
    """JSON dosyasını kaydeder."""
    print(f"💾 JSON dosyası kaydediliyor: {filepath}")
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ {len(data)} ayet kaydedildi")
    except Exception as e:
        print(f"❌ JSON dosyası kaydedilemedi: {e}")
        raise

def create_verse_index(verses_data: List[Dict[str, Any]]) -> Dict[tuple, int]:
    """
    Ayetleri hızlı erişim için indeksler.
    Key: (surah_id, verse_id_in_surah) -> index
    """
    index = {}
    for i, verse in enumerate(verses_data):
        key = (verse['surah_id'], verse['verse_id_in_surah'])
        index[key] = i
    return index

def update_arabic_texts():
    """Ana fonksiyon: Tüm ayetleri günceller."""
    
    print("=" * 80)
    print("🕌 Kur'an-ı Kerim Arapça Metin Güncelleme")
    print("=" * 80)
    print()
    
    # JSON dosyasını yükle
    json_filepath = "all_verses.json"
    verses_data = load_json_file(json_filepath)
    
    # Hızlı erişim için indeks oluştur
    print("🔍 İndeks oluşturuluyor...")
    verse_index = create_verse_index(verses_data)
    print(f"✅ {len(verse_index)} ayet indekslendi")
    print()
    
    # İstatistikler
    total_verses = 0
    updated_verses = 0
    not_found_verses = 0
    error_verses = 0
    
    # Her sureyi API'den çek
    print("📡 API'den veriler çekiliyor...")
    print("-" * 80)
    
    for surah_id in range(1, 115):  # 1-114 arası
        print(f"📖 Sure {surah_id}/114 işleniyor...", end=" ")
        
        # API'den sureyi çek
        surah_data = fetch_surah(surah_id)
        
        if not surah_data or 'verses' not in surah_data:
            print(f"❌ Sure {surah_id} alınamadı!")
            error_verses += 1
            continue
        
        verses = surah_data['verses']
        print(f"✓ {len(verses)} ayet bulundu")
        
        # Her ayeti güncelle
        for verse in verses:
            total_verses += 1
            
            # API'den veriyi al
            surah_id_api = verse.get('surah_id')
            verse_number = verse.get('verse_number')
            arabic_text = verse.get('verse', '')
            
            # Validasyon
            if not surah_id_api or not verse_number:
                print(f"  ⚠️  Sure {surah_id}, Ayet ?: Eksik veri")
                error_verses += 1
                continue
            
            if not arabic_text:
                print(f"  ⚠️  Sure {surah_id}, Ayet {verse_number}: Boş Arapça metin")
                error_verses += 1
                continue
            
            # JSON'da bu ayeti bul
            key = (surah_id_api, verse_number)
            
            if key not in verse_index:
                print(f"  ⚠️  Sure {surah_id}, Ayet {verse_number}: JSON'da bulunamadı")
                not_found_verses += 1
                continue
            
            # JSON'daki ayeti güncelle
            verse_idx = verse_index[key]
            verses_data[verse_idx]['arabic_script']['text'] = arabic_text
            updated_verses += 1
        
        # Rate limiting (API'yi yormamak için)
        time.sleep(0.1)
    
    print("-" * 80)
    print()
    
    # İstatistikleri göster
    print("=" * 80)
    print("📊 İSTATİSTİKLER")
    print("=" * 80)
    print(f"📖 Toplam ayet (API):        {total_verses}")
    print(f"✅ Güncellenen ayet:         {updated_verses}")
    print(f"⚠️  JSON'da bulunamayan:      {not_found_verses}")
    print(f"❌ Hatalı ayet:              {error_verses}")
    print()
    
    # Başarı oranı kontrolü
    success_rate = (updated_verses / total_verses * 100) if total_verses > 0 else 0
    print(f"🎯 Başarı oranı: {success_rate:.2f}%")
    print()
    
    if success_rate < 99.0:
        print("⚠️  UYARI: Bazı ayetler güncellenemedi!")
        response = input("Devam etmek istiyor musunuz? (E/H): ")
        if response.upper() != 'E':
            print("❌ İşlem iptal edildi.")
            return
    
    # Dosyayı kaydet
    print()
    print("=" * 80)
    save_json_file(json_filepath, verses_data)
    print()
    print("🎉 İşlem başarıyla tamamlandı!")
    print("=" * 80)

if __name__ == "__main__":
    try:
        update_arabic_texts()
    except KeyboardInterrupt:
        print("\n\n⚠️  İşlem kullanıcı tarafından iptal edildi.")
    except Exception as e:
        print(f"\n\n❌ Beklenmeyen hata: {e}")
        import traceback
        traceback.print_exc()
