-- Kırşehir catalogue quality pass: remove clear non-destination map noise and a duplicate.
-- Deliberately leaves ambiguous rural landmarks and archaeological points untouched.
update public.places
set is_active = false,
    content_review_status = 'rejected'
where city = 'Kırşehir'
  and slug in (
    'osm-node-13942791116', -- English-labelled Silver Side Park 1
    'osm-node-13942921977', -- English-labelled Silver Side Park 2
    'osm-node-13942962007', -- English-labelled Silver Side Park 3
    'osm-node-2496546739',  -- broadcast transmitter, not a visitor destination
    'osm-way-448737988'     -- duplicate OSM label for curated Ahi Evran Külliyesi ve Türbesi
  )
  and is_active = true;
