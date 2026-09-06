# BUGÜN v1.0

Ankara'da bugün ne var?

## Hedef
Günlük şehir keşfi: etkinlik, fırsat, mekan, ücretsiz aktiviteler, popüler içerik ve kişisel öneriler.

## Stack
- Flutter
- Supabase Auth + PostgreSQL
- PostGIS
- Supabase Storage
- Edge Functions / backend worker
- LLM tabanlı içerik çıkarma ve sınıflandırma

## İlk MVP
1. Ana sayfa / günlük feed
2. Kategori keşfi
3. Etkinlik detay
4. Mekan detay
5. Harita için veri modeli
6. Kaydetme
7. Basit kişiselleştirme
8. Admin/moderasyon altyapısı

## Çalıştırma
```bash
flutter pub get
flutter run
```

Supabase bağlantısı için `lib/core/config.dart` içindeki değerleri veya `--dart-define` kullanın.
