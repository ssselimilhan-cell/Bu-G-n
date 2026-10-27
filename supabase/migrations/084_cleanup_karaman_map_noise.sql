-- 084: Karaman'da turistik yer olmayan altyapı kayıtlarını ve açık yinelenen mağara kaydını pasifleştir.
update public.places
set is_active=false, content_review_status='rejected'
where city='Karaman'
  and slug in ('osm-node-2116401067','osm-node-1863432352')
  and is_active=true;

-- İncesu Mağarası için resmî kaynaklı Taşkale kaydı bulunduğundan,
-- kaynak/konum bilgisi olmayan OSM noktasını yinelenen kayıt olarak pasifleştir.
update public.places
set is_active=false, content_review_status='rejected'
where city='Karaman'
  and slug='osm-node-5555860821'
  and is_active=true
  and exists (
    select 1 from public.places p
    where p.city='Karaman'
      and p.slug='taskale-incesu-magarasi'
      and p.is_active=true
  );

-- Mevcut resmî kaynaklı İncesu kaydının kısa açıklamasını netleştir.
update public.places
set name='Taşkale İncesu Mağarası',
    short_description='Sarkıt, dikit ve damlataş havuzlarıyla bilinen, Taşkale yakınındaki yatay mağara sistemi.',
    long_description='İncesu Mağarası, Taşkale çevresinde İncesu Deresi yamacında yer alan ve damlataş oluşumlarıyla öne çıkan doğal mağaradır. Ziyaret öncesinde güncel erişim ve açık olma durumunu kontrol edin.',
    source_url='https://kulturportali.gov.tr/turkiye/karaman/gezilecekyer/ncesu-magarasi',
    verified=true,
    trust_score=greatest(coalesce(trust_score,0),90),
    content_review_status='source_backed'
where city='Karaman' and slug='taskale-incesu-magarasi' and is_active=true;
