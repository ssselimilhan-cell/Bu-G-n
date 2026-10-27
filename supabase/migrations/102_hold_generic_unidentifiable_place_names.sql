-- Second catalog-quality pass: hide unidentifiable generic OSM labels until individually named and sourced.
-- No rows are deleted; a curator can reactivate them after verification.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE is_active = true
  AND external_source = 'openstreetmap'
  AND source_url IS NULL
  AND verified = false
  AND content_review_status <> 'source_backed'
  AND name ~* '^(parkı|park|plaj|tepe|dağ|dağı|höyük|anıt|heykel|türbe|mağara|seyir terası|güney|kuzey|doğu|batı|yanık|bekçilik|sunset viewpoint|bitki bahçesi|kaya resimleri|travertenler|manzara|çocuk parkı|çeşme|pınar|şelale)$';

-- Perre Antik Kent is already represented by a nearby mapped area; hold the duplicate point record.
UPDATE public.places
SET is_active = false,
    content_review_status = 'needs_review',
    updated_at = now()
WHERE is_active = true
  AND slug = 'osm-node-9854965906'
  AND city = 'Adıyaman'
  AND name = 'Perre Antik Kent';