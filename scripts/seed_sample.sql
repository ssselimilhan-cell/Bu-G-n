insert into sources(name, source_type, base_url, trust_score) values
('BUGÜN Demo','official','https://example.com',90);

insert into places(name, category, city, address, latitude, longitude, location, verified, trust_score)
values ('Demo Kültür Merkezi','kültür','Ankara','Çankaya, Ankara',39.9001,32.8542,ST_SetSRID(ST_MakePoint(32.8542,39.9001),4326)::geography,true,90);

insert into events(source_id, place_id, title, description, category, city, starts_at, price_min, price_max, trust_score, recommendation_score, fingerprint)
select s.id,p.id,'BUGÜN Demo Konseri','Deneme içeriği.','konser','Ankara',date_trunc('day',now()) + interval '19 hours',250,400,90,92,'demo-konser-'||to_char(now(),'YYYY-MM-DD')
from sources s, places p where s.name='BUGÜN Demo' and p.name='Demo Kültür Merkezi';
