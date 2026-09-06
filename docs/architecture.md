# BUGÜN v1 Mimari

## Veri akışı
Kaynaklar → ingestion → normalize → AI extraction → duplicate/fingerprint → trust score → admin review → PostgreSQL/PostGIS → recommendation → Flutter.

## Günlük pipeline
03:00 kaynak tarama; 03:30 normalization; 04:00 AI extraction; 04:30 duplicate kontrolü; 05:00 score; 05:30 günlük feed cache; 06:00 bildirim adayları.

## Recommendation v1
`score = 0.35*interest + 0.20*distance + 0.15*popularity + 0.10*time_fit + 0.10*price_fit + 0.05*novelty + 0.05*trust`.

## Trust
Resmi kaynak 95+, doğrulanmış işletme 85+, ticketing platformu 90+, topluluk 60 başlangıç, yeni kullanıcı içeriği 25 başlangıç. Gerçek score davranıştan güncellenir.

## AI görevleri
- tarih/saat/mekan/ücret çıkarma
- kategori ve etiketleme
- aynı etkinliği farklı kaynaklardan eşleme
- kısa özet üretme
- kullanıcı için neden önerildiğini açıklama
- doğal dil plan isteğini filtre JSON'una dönüştürme
