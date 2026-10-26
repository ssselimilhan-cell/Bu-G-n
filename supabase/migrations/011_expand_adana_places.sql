-- BUGÜN: Adana şehir kataloğu, ikinci genişletme.
-- Yalnızca bilinen kültür/doğa durakları; kayıtlar kaynak bağlantılıdır.
insert into public.places
  (name, category, place_type, city, address, latitude, longitude, slug,
   short_description, long_description, source_url, external_source, external_id,
   verified, trust_score, is_active, content_review_status, tags)
select v.name, v.category, v.place_type, 'Adana', v.address, v.lat, v.lon, v.slug,
       v.short_description, v.long_description, v.source_url, 'curated_seed',
       'adana-' || v.slug, false, 75, true, 'source_backed', v.tags::jsonb
from (values
 ('Adana Ulu Camii Külliyesi','Tarih','Cami ve külliye','Seyhan, Adana',36.9864::float8,35.3252::float8,'adana-ulu-camii-kulliyesi','Ramazanoğulları döneminin önemli tarihî külliyesi.','Adana tarihî merkezinde cami, türbe ve külliye mimarisini görmek için öne çıkan durak.','https://tr.wikipedia.org/wiki/Adana_Ulu_Camii','["tarih","mimari","kültür"]'),
 ('Yağ Camii','Tarih','Tarihî cami','Seyhan, Adana',36.9874::float8,35.3271::float8,'yag-camii','Adana tarihî merkezinde yer alan tarihî cami.','Kent merkezindeki tarihî yapılar rotasına eklenebilecek kültürel miras noktası.','https://tr.wikipedia.org/wiki/Ya%C4%9F_Camii','["tarih","mimari","kültür"]'),
 ('Kazancılar Çarşısı','Kültür','Tarihî çarşı','Seyhan, Adana',36.9862::float8,35.3258::float8,'kazancilar-carsisi','Geleneksel çarşı kültürünü tanımak için tarihî merkez durağı.','Büyük Saat ve tarihî merkez çevresindeki geleneksel ticaret dokusuyla öne çıkar.','https://tr.wikipedia.org/wiki/B%C3%BCy%C3%BCk_Saat','["çarşı","yerel kültür","şehir yürüyüşü"]'),
 ('Atatürk Evi Müzesi','Müze','Kent müzesi','Seyhan, Adana',36.9884::float8,35.3250::float8,'ataturk-evi-muzesi-adana','Atatürk’ün Adana ziyaretleriyle ilişkilendirilen tarihî ev müzesi.','Adana’nın yakın tarihini ve Atatürk’ün kentle ilişkisini anlatan müze durağı.','https://tr.wikipedia.org/wiki/Adana_Atat%C3%BCrk_Evi_M%C3%BCzesi','["müze","tarih","Atatürk"]'),
 ('Adana Etnografya Müzesi','Müze','Etnografya müzesi','Seyhan, Adana',36.9878::float8,35.3272::float8,'adana-etnografya-muzesi','Çukurova’nın kültürel yaşamını tanımaya yönelik müze.','Bölgenin geleneksel yaşamı ve kültürel mirasına odaklanan ziyaret noktası.','https://tr.wikipedia.org/wiki/Adana_Etnografya_M%C3%BCzesi','["müze","kültür","tarih"]'),
 ('Adana Büyük Saat Kulesi','Tarih','Saat kulesi','Seyhan, Adana',36.9860::float8,35.3254::float8,'adana-buyuk-saat-kulesi','Adana’nın en tanınan tarihî simgelerinden biri.','Tarihî merkezdeki Büyük Saat ve çevresindeki çarşılar birlikte gezilebilir.','https://tr.wikipedia.org/wiki/B%C3%BCy%C3%BCk_Saat','["tarih","mimari","şehir merkezi"]'),
 ('Seyhan Baraj Gölü','Doğa','Baraj gölü','Çukurova, Adana',37.0460::float8,35.3010::float8,'seyhan-baraj-golu','Göl manzarası ve açık hava gezileri için geniş alan.','Adana’nın kuzeyinde manzara, yürüyüş ve açık hava molası için tercih edilen bölge.','https://tr.wikipedia.org/wiki/Seyhan_Baraj%C4%B1','["göl","manzara","doğa"]'),
 ('Çatalan Köprüsü','Doğa','Köprü ve manzara','Çukurova, Adana',37.1000::float8,35.2800::float8,'catalan-koprusu','Çatalan Baraj Gölü çevresinde tanınan köprü ve manzara noktası.','Şehir dışı kısa gezi planlarında göl çevresi manzarasıyla değerlendirilebilir.','https://tr.wikipedia.org/wiki/%C3%87atalan_Baraj%C4%B1','["manzara","göl","fotoğraf"]'),
 ('Akyatan Lagünü','Doğa','Lagün ve sulak alan','Karataş, Adana',36.6200::float8,35.2700::float8,'akyatan-lagunu','Kuş gözlemi ve doğal yaşamıyla öne çıkan sulak alan.','Akdeniz kıyısındaki önemli lagün ekosistemlerinden biridir; ziyaret öncesi koruma ve erişim kuralları kontrol edilmelidir.','https://tr.wikipedia.org/wiki/Akyatan_Lag%C3%BCn%C3%BC','["kuş gözlemi","sulak alan","doğa"]'),
 ('Karataş Plajı','Deniz','Plaj','Karataş, Adana',36.5650::float8,35.3850::float8,'karatas-plaji','Adana kıyısında deniz ve sahil için bilinen durak.','Karataş ilçesinin sahil bölgesi yaz aylarında deniz ve kıyı gezisi için tercih edilir.','https://tr.wikipedia.org/wiki/Karata%C5%9F,_Adana','["deniz","plaj","sahil"]'),
 ('Magarsus Antik Kenti','Tarih','Antik kent','Karataş, Adana',36.5700::float8,35.3900::float8,'magarsus-antik-kenti','Karataş çevresinde antik yerleşim ve tiyatro kalıntıları.','Antik Kilikya geçmişini tanımak için Adana’nın önemli arkeolojik alanlarından biridir.','https://tr.wikipedia.org/wiki/Magarsus','["arkeoloji","antik kent","tarih"]'),
 ('Anavarza Antik Kenti','Tarih','Antik kent','Kozan, Adana',37.2500::float8,35.9000::float8,'anavarza-antik-kenti','Anıtsal kalıntıları ve surlarıyla bilinen antik kent.','Kozan çevresindeki Anavarza, antik dönem yerleşimi ve kalıntılarıyla önemli bir tarih rotasıdır.','https://tr.wikipedia.org/wiki/Anavarza','["arkeoloji","antik kent","tarih"]'),
 ('Yılankale','Tarih','Kale','Ceyhan, Adana',37.0300::float8,35.8200::float8,' yilankale','Çukurova ovasına hâkim kayalık üzerinde Orta Çağ kalesi.','Tarihî kale kalıntıları ve ovaya bakan manzarasıyla Adana çevresinin dikkat çeken gezi noktalarındandır.','https://tr.wikipedia.org/wiki/Y%C4%B1lankale','["kale","tarih","manzara"]'),
 ('Kozan Kalesi','Tarih','Kale','Kozan, Adana',37.4500::float8,35.8100::float8,'kozan-kalesi','Kozan kentinin üzerinde yükselen tarihî kale.','Kozan’ın tarihî dokusunu ve çevre manzarasını görmek için öne çıkan durak.','https://tr.wikipedia.org/wiki/Kozan_Kalesi','["kale","tarih","manzara"]'),
 ('Ağyatan Gölü','Doğa','Lagün ve sulak alan','Karataş, Adana',36.7000::float8,35.2500::float8,'agyatan-golu','Adana kıyılarındaki doğal sulak alanlardan biri.','Kıyı ekosistemi ve kuş yaşamı bakımından önem taşıyan doğal alan; hassas habitatlara saygılı ziyaret önerilir.','https://tr.wikipedia.org/wiki/A%C4%9Fyatan_G%C3%B6l%C3%BC','["doğa","sulak alan","kuş gözlemi"]'),
 ('Akçatekir Yaylası','Doğa','Yayla','Pozantı, Adana',37.4300::float8,34.9000::float8,'akcatekir-yaylasi','Toroslar’da yaz aylarında tercih edilen yayla bölgesi.','Adana-Pozantı güzergâhındaki yayla bölgesi, serin hava ve dağ manzarası arayanlar için bilinir.','https://tr.wikipedia.org/wiki/Pozant%C4%B1','["yayla","dağ","doğa"]')
) as v(name,category,place_type,address,lat,lon,slug,short_description,long_description,source_url,tags)
where not exists (
 select 1 from public.places p
 where lower(trim(p.city))='adana'
   and (lower(trim(p.name))=lower(trim(v.name)) or p.slug=v.slug)
);
