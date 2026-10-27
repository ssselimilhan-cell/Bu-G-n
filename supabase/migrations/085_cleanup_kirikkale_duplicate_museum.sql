-- 085: Kırıkkale'de kaynaklı MKE müzesi kaydı varken yinelenen OSM noktasını pasifleştir.
update public.places
set is_active=false, content_review_status='rejected'
where city='Kırıkkale'
  and slug='osm-node-3658121554'
  and is_active=true
  and exists (
    select 1 from public.places p
    where p.city='Kırıkkale'
      and p.slug='mke-silah-sanayi-muzesi'
      and p.is_active=true
  );
