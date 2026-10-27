-- Correct an English, generic label for the documented Plutonium sanctuary at Hierapolis.
UPDATE public.places
SET name = 'Plutonium (Cehennem Kapısı)',
    category = 'Arkeoloji',
    place_type = 'Antik kutsal alan',
    short_description = 'Hierapolis’te Apollon Kutsal Alanı’nın yanında bulunan, antik çağda yeraltı dünyasıyla ilişkilendirilen Ploutonion kutsal alanı.',
    long_description = 'Hierapolis Antik Kenti içindeki Ploutonion, antik kaynaklarda yer alan ve yerden karbondioksit çıkışıyla bilinen kutsal mağara ile çevresindeki kült alanından oluşur. Ziyaret, Hierapolis ören yeri kuralları ve açık alan sınırları içinde yapılmalıdır.',
    source_url = 'https://denizli.ktb.gov.tr/TR-211745/pamukkale-hierapolis.html',
    external_source = 'curated_seed',
    verified = true,
    trust_score = 90,
    content_review_status = 'source_backed',
    is_active = true,
    updated_at = now()
WHERE slug = 'osm-node-3930850889'
  AND city = 'Denizli';

-- Hide a second English alias for the same Plutonium site to avoid duplicate listings.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE slug = 'osm-node-6217002361'
  AND city = 'Denizli';

-- Keep the obscure, unsourced underground-city label out of discovery until its identity and access are verified.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE slug = 'osm-node-4086983926'
  AND city = 'Kayseri'
  AND name = 'Sarnıçlı Yeraltı Şehri'
  AND source_url IS NULL;
