-- Curate high-value attractions in Bursa, Çanakkale and Denizli.
-- Idempotent: update known canonical slugs and deactivate only clear duplicates.
UPDATE public.places
SET short_description = 'Yirmi kubbeli, 1400 yılında tamamlanan anıtsal erken Osmanlı camisi.',
    long_description = 'Bursa Ulu Cami, Yıldırım Bayezid döneminde yaptırılan ve yirmi kubbesiyle öne çıkan erken Osmanlı dönemi eseridir. Kent merkezindeki tarihî çarşı bölgesini gezerken mimarisi ve hat eserleriyle birlikte ziyaret edilebilir.',
    source_url = 'https://bursa.ktb.gov.tr/TR-70236/camiler.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı',
    verified = true, trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Bursa' AND slug = 'bursa-ulu-cami';
UPDATE public.places
SET short_description = 'Geleneksel Osmanlı köy dokusunu koruyan, UNESCO Dünya Mirası alanındaki tarihî yerleşim.',
    long_description = 'Cumalıkızık, geleneksel Osmanlı kırsal yerleşim dokusu, sokakları ve tarihî evleriyle tanınır. Köy içinde yürüyüş yaparken tarihî yapıların dış cephelerini ve yerleşim düzenini gözlemlemek mümkündür.',
    source_url = 'https://www.kulturportali.gov.tr/turkiye/bursa/gezilecekyer/cumalikizik-koyu',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı Kültür Portalı',
    verified = true, trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Bursa' AND slug = 'cumalikizik-koyu';
UPDATE public.places
SET short_description = 'Yeşil çinileri ve erken Osmanlı mimarisiyle tanınan cami ve türbe topluluğu.',
    long_description = 'Yeşil Cami ve Yeşil Türbe, Bursa’nın erken Osmanlı döneminden kalan önemli mimari eserlerindendir. Özellikle çini süslemeleri ve külliye çevresindeki tarihî doku nedeniyle kent kültür rotasının öne çıkan durakları arasındadır.',
    source_url = 'https://bursa.ktb.gov.tr/TR-70236/camiler.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı',
    verified = true, trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Bursa' AND slug = 'yesil-cami-yesil-turbe';
UPDATE public.places
SET name = 'Anadolu Hamidiye Tabyası', category = 'Tarihî Yapı', place_type = 'Tabya ve tarihî alan',
    short_description = 'Çanakkale savunma tarihini anlatan tabya ve açık hava ziyaret alanı.',
    long_description = 'Anadolu Hamidiye Tabyası, Çanakkale Boğazı savunma tarihini anlamak için ziyaret edilebilecek tarihî askerî yapılardandır. Alanı gezerken tabya düzeni ve savunma mimarisi incelenebilir.',
    source_url = 'https://canakkale.ktb.gov.tr/TR-70509/muze-ve-oren-yerleri.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'cimenlik-kalesi-deniz-muzesi';
UPDATE public.places
SET short_description = 'Boğaz kıyısında Osmanlı dönemi kalesi ve denizcilik koleksiyonları.',
    long_description = 'Çimenlik Kalesi ve Deniz Müzesi, Çanakkale Boğazı’nın savunma tarihiyle denizcilik geçmişini bir arada tanıtan önemli bir ziyaret noktasıdır.',
    source_url = 'https://goturkiye.com/tr/canakkale/canakkale-rotalari', external_source = 'GoTürkiye',
    verified = true, trust_score = greatest(coalesce(trust_score, 0), 90),
    content_review_status = 'source_backed', is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'cimenlik-kalesi-deniz-muzesi';
UPDATE public.places
SET short_description = 'Troya ve Troas bölgesinin arkeolojik buluntularını sergileyen müze.',
    long_description = 'Troya Müzesi, Troya antik kenti ve çevresindeki Troas bölgesinin arkeolojik mirasını, buluntuların bağlamını anlatan sergilerle ziyaretçilere sunar.',
    source_url = 'https://www.muze.gov.tr/muze-detay?DistId=TRO&SectionId=TRO01',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'troya-muzesi';
UPDATE public.places
SET short_description = 'UNESCO Dünya Mirası Listesi’ndeki antik Troya yerleşiminin kalıntıları.',
    long_description = 'Troya Ören Yeri, farklı dönemlere ait yerleşim katmanlarıyla Anadolu ve Akdeniz tarihinin önemli arkeolojik alanlarından biridir. Ziyarette antik kent kalıntıları ve yerleşimin uzun tarihsel gelişimi görülebilir.',
    source_url = 'https://canakkale.ktb.gov.tr/TR-70509/muze-ve-oren-yerleri.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Çanakkale' AND slug = 'troya-oren-yeri';
UPDATE public.places
SET short_description = 'UNESCO Dünya Mirası alanındaki antik kent; anıtsal tiyatrosu ve nekropolüyle öne çıkar.',
    long_description = 'Hierapolis, Pamukkale travertenlerinin yanında gelişmiş antik kenttir. Roma tiyatrosu, anıtsal caddeleri, hamam-bazilika yapısı ve geniş nekropol alanıyla tarihî ve arkeolojik açıdan önemli bir ziyaret noktasıdır.',
    source_url = 'https://denizli.ktb.gov.tr/TR-211745/pamukkale-hierapolis.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Denizli' AND slug = 'hierapolis-antik-kenti';
UPDATE public.places
SET short_description = 'Lykos Vadisi’nde yer alan, anıtsal yapıları ve geniş kazı alanıyla tanınan antik kent.',
    long_description = 'Laodikeia, Lykos Vadisi’ndeki önemli antik kentlerden biridir. Kentin anıtsal yapıları ve arkeolojik kalıntıları, bölgenin Roma dönemi yerleşim tarihini anlamak için ziyaret edilebilir.',
    source_url = 'https://denizli.ktb.gov.tr/TR-353343/denizli-muze-ve-orenyeri-ziyaret-saatleri.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Denizli' AND slug = 'laodikeia-antik-kenti';
UPDATE public.places
SET short_description = 'Beyaz traverten terasları ve termal sularıyla tanınan doğal miras alanı.',
    long_description = 'Pamukkale, termal suların oluşturduğu beyaz traverten teraslarıyla tanınır. Yakınındaki Hierapolis antik kentiyle birlikte doğal ve kültürel mirası bir arada sunan başlıca ziyaret alanıdır.',
    source_url = 'https://denizli.ktb.gov.tr/TR-211745/pamukkale-hierapolis.html',
    external_source = 'T.C. Kültür ve Turizm Bakanlığı', verified = true,
    trust_score = greatest(coalesce(trust_score, 0), 90), content_review_status = 'source_backed',
    is_active = true, updated_at = now()
WHERE city = 'Denizli' AND slug = 'pamukkale-travertenleri';
UPDATE public.places
SET is_active = false, content_review_status = 'rejected', updated_at = now()
WHERE (city = 'Çanakkale' AND slug IN ('osm-way-303002619','osm-node-10216826112')
       AND EXISTS (SELECT 1 FROM public.places c WHERE c.city='Çanakkale' AND c.slug='cimenlik-kalesi-deniz-muzesi' AND c.is_active=true))
   OR (city = 'Denizli' AND slug = 'osm-node-4889959123'
       AND EXISTS (SELECT 1 FROM public.places c WHERE c.city='Denizli' AND c.slug='pamukkale-travertenleri' AND c.is_active=true));
