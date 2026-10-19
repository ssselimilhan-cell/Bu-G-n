import json
import os
import time
import requests

SUPABASE_URL = os.environ["SUPABASE_URL"].rstrip("/")
SUPABASE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
NOMINATIM = "https://nominatim.openstreetmap.org/search"
OVERPASS_ENDPOINTS = [
    "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
    "https://overpass.private.coffee/api/interpreter",
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
HEADERS = {
    "User-Agent": "BUGUN-city-discovery/1.0 (+https://github.com/ssselimilhan-cell/Bu-G-n)",
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "resolution=merge-duplicates,return=minimal",
}
CITIES = [
    "Ankara",
    "İstanbul",
    "İzmir",
    "Antalya",
    "Bursa",
    "Muğla",
    "Eskişehir",
    "Konya",
    "Adana",
    "Gaziantep",
    "Mersin",
    "Trabzon",
    "Samsun",
    "Siirt",
    "Kocaeli",
    "Balıkesir",
    "Aydın",
    "Denizli",
    "Kayseri",
    "Hatay",
    "Diyarbakır",
    "Şanlıurfa",
    "Nevşehir",
    "Çanakkale",
    "Edirne",
    "Rize",
    "Ordu",
    "Sakarya",
    "Tekirdağ",
    "Kahramanmaraş",
    "Mardin",
    "Erzurum",
    "Sivas",
    "Malatya",
    "Van",
    "Aksaray",
    "Afyonkarahisar",
    "Bolu",
    "Kastamonu",
    "Kars",
    "Zonguldak",
    "Yalova",
    "Adıyaman",
    "Ağrı",
    "Amasya",
    "Artvin",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Burdur",
    "Çankırı",
    "Çorum",
    "Elazığ",
    "Erzincan",
    "Giresun",
    "Gümüşhane",
    "Hakkâri",
    "Isparta",
    "Kırklareli",
    "Kırşehir",
    "Kütahya",
    "Manisa",
    "Muş",
    "Niğde",
    "Sinop",
    "Tokat",
    "Tunceli",
    "Uşak",
    "Yozgat",
    "Bayburt",
    "Karaman",
    "Kırıkkale",
    "Batman",
    "Şırnak",
    "Bartın",
    "Ardahan",
    "Iğdır",
    "Karabük",
    "Kilis",
    "Osmaniye",
    "Düzce"
]

def category_for(tags):
    if tags.get("tourism") == "museum": return ("Müze", "Müze")
    if tags.get("tourism") == "zoo": return ("Hayvanat Bahçesi", "Hayvanat bahçesi")
    if tags.get("tourism") == "gallery": return ("Sanat", "Sanat galerisi")
    if tags.get("tourism") == "theme_park": return ("Eğlence", "Eğlence parkı")
    if tags.get("tourism") == "aquarium": return ("Hayvanat Bahçesi", "Akvaryum")
    if tags.get("tourism") == "viewpoint": return ("Doğa", "Seyir noktası")
    if tags.get("tourism") in ("attraction", "artwork"): return ("Gezi", "Turistik nokta")
    if tags.get("tourism") in ("camp_site", "caravan_site", "picnic_site"): return ("Doğa", "Kamp ve piknik alanı")
    if tags.get("leisure") in ("park", "garden"): return ("Park", "Park ve bahçe")
    if tags.get("leisure") in ("nature_reserve", "water_park", "beach_resort"): return ("Doğa", "Doğa ve rekreasyon alanı")
    if tags.get("natural") in ("waterfall", "beach", "peak", "cave_entrance", "hot_spring"): return ("Doğa", "Doğal güzellik")
    if tags.get("historic") in ("castle", "monument", "memorial", "archaeological_site", "ruins", "fort", "city_gate", "manor", "battlefield", "monastery"): return ("Tarih", "Tarihi yer")
    if tags.get("man_made") in ("lighthouse", "tower"): return ("Tarih", "Yapı ve anıt")
    if tags.get("amenity") in ("arts_centre", "planetarium"): return ("Kültür", "Kültür merkezi")
    return ("Gezi", "Gezilecek yer")

def element_point(el):
    if el.get("type") == "node":
        return el.get("lat"), el.get("lon")
    center = el.get("center") or {}
    return center.get("lat"), center.get("lon")

def short_description(name, tags, label):
    description = tags.get("description") or tags.get("tourism:description")
    if description:
        return description[:450]
    if label == "Müze": return f"{name}, {tags.get('museum', 'kültür ve tarih') } hakkında koleksiyonlar ve sergiler keşfedebileceğiniz bir müzedir."
    if label == "Hayvanat bahçesi": return f"{name}, farklı hayvan türlerini tanıyabileceğiniz bir ziyaret noktasıdır."
    if label == "Park ve bahçe": return f"{name}, açık havada yürüyüş yapmak, dinlenmek ve şehirde vakit geçirmek için bir seçenektir."
    if label == "Tarihi yer": return f"{name}, şehrin tarihini ve kültürel mirasını keşfetmek isteyenler için bir duraktır."
    if label == "Kültür merkezi": return f"{name}, kültür ve sanat etkinlikleri için ziyaret edilebilecek bir mekândır."
    return f"{name}, {label.lower()} keşfetmek isteyenler için şehirde ziyaret edilebilecek bir noktadır."

def main():
    session = requests.Session()
    session.headers.update({"User-Agent": "BUGUN-city-discovery/1.0 (+https://github.com/ssselimilhan-cell/Bu-G-n)"})
    all_rows = {}
    errors = []
    existing_cities = set()
    try:
        existing_response = session.get(
            f"{SUPABASE_URL}/rest/v1/places",
            headers=HEADERS,
            params={"select": "city", "is_active": "eq.true", "limit": "10000"},
            timeout=20,
        )
        existing_response.raise_for_status()
        existing_cities = {
            row.get("city")
            for row in existing_response.json()
            if row.get("city")
        }
        print(f"Mevcut aktif yer verisi olan şehir: {len(existing_cities)}/81", flush=True)
    except requests.RequestException as exc:
        print(f"Mevcut şehirler okunamadı; tüm şehirler kontrol edilecek: {exc}", flush=True)

    for index, city in enumerate(CITIES, 1):
        if city in existing_cities:
            print(f"[{index}/{len(CITIES)}] {city}: aktif yer verisi zaten var; atlanıyor", flush=True)
            continue
        city_rows = []
        print(f"[{index}/{len(CITIES)}] {city}: sınır ve ziyaret yerleri aranıyor", flush=True)
        try:
            geo = None
            geo_errors = []
            for geo_attempt in range(1, 4):
                try:
                    geo = session.get(NOMINATIM, params={
                        "city": city, "country": "Türkiye", "format": "jsonv2",
                        "limit": 1, "addressdetails": 1,
                    }, timeout=30)
                    geo.raise_for_status()
                    break
                except requests.RequestException as exc:
                    geo_errors.append(f"deneme {geo_attempt}: {type(exc).__name__}: {exc}")
                    if geo_attempt < 3:
                        time.sleep(2 * geo_attempt)
            if geo is None:
                raise RuntimeError("Nominatim başarısız: " + " | ".join(geo_errors))
            results = geo.json()
            if not results:
                errors.append(f"{city}: geocoding sonucu yok")
                continue
            result = results[0]
            osm_type = result.get("osm_type")
            osm_id = int(result.get("osm_id", 0))
            if osm_type == "relation":
                area_id = 3600000000 + osm_id
                scope = "nwr(area.city)"
                area_statement = f"area({area_id})->.city;"
            elif osm_type == "way":
                area_id = 2400000000 + osm_id
                scope = "nwr(area.city)"
                area_statement = f"area({area_id})->.city;"
            else:
                # Some city searches resolve to a point instead of a boundary.
                # Use a bounded 20 km radius as a practical fallback.
                latitude = result.get("lat")
                longitude = result.get("lon")
                if latitude is None or longitude is None:
                    errors.append(f"{city}: sınır veya merkez koordinatı bulunamadı")
                    continue
                scope = f"nwr(around:20000,{latitude},{longitude})"
                area_statement = ""
            query = f"""
            [out:json][timeout:45];
            {area_statement}
            (
              {scope}["tourism"~"^(museum|zoo|gallery|theme_park|attraction|aquarium|viewpoint|artwork|camp_site|caravan_site|picnic_site)$"];
              {scope}["leisure"~"^(park|garden|nature_reserve|water_park|beach_resort)$"];
              {scope}["natural"~"^(waterfall|beach|peak|cave_entrance|hot_spring)$"];
              {scope}["historic"~"^(castle|monument|memorial|archaeological_site|ruins|fort|city_gate|manor|battlefield|monastery)$"];
              {scope}["man_made"~"^(lighthouse|tower)$"];
              {scope}["amenity"~"^(arts_centre|planetarium)$"];
            );
            out center tags 120;
            """
            response = None
            endpoint_errors = []
            for endpoint in OVERPASS_ENDPOINTS:
                try:
                    candidate = session.post(
                        endpoint,
                        data={"data": query},
                        timeout=(8, 25),
                    )
                    candidate.raise_for_status()
                    response = candidate
                    print(f"  Overpass kaynağı: {endpoint}", flush=True)
                    break
                except requests.RequestException as exc:
                    endpoint_errors.append(f"{endpoint}: {type(exc).__name__}: {exc}")
                    print(f"  Overpass yedek kaynağa geçiliyor: {endpoint}", flush=True)
            if response is None:
                raise RuntimeError("Tüm Overpass uçları başarısız: " + " | ".join(endpoint_errors))
            elements = response.json().get("elements", [])

            # Some geocoded city results have incomplete or unusable admin
            # boundaries. If a boundary query returns nothing, retry around
            # the geocoded city center so the province is not silently skipped.
            if not elements:
                center_lat = result.get("lat")
                center_lon = result.get("lon")
                if center_lat is not None and center_lon is not None:
                    fallback_query = f"""
                    [out:json][timeout:45];
                    (
                      nwr(around:35000,{center_lat},{center_lon})["tourism"~"^(museum|zoo|gallery|theme_park|attraction|aquarium|viewpoint|artwork|camp_site|caravan_site|picnic_site)$"];
                      nwr(around:35000,{center_lat},{center_lon})["leisure"~"^(park|garden|nature_reserve|water_park|beach_resort)$"];
                      nwr(around:35000,{center_lat},{center_lon})["natural"~"^(waterfall|beach|peak|cave_entrance|hot_spring)$"];
                      nwr(around:35000,{center_lat},{center_lon})["historic"~"^(castle|monument|memorial|archaeological_site|ruins|fort|city_gate|manor|battlefield|monastery)$"];
                      nwr(around:35000,{center_lat},{center_lon})["man_made"~"^(lighthouse|tower)$"];
                      nwr(around:35000,{center_lat},{center_lon})["amenity"~"^(arts_centre|planetarium)$"];
                    );
                    out center tags 120;
                    """
                    print("  İl sınırı sorgusu boş; 35 km merkez araması deneniyor.", flush=True)
                    for endpoint in OVERPASS_ENDPOINTS:
                        try:
                            candidate = session.post(
                                endpoint,
                                data={"data": fallback_query},
                                timeout=(15, 55),
                            )
                            candidate.raise_for_status()
                            fallback_elements = candidate.json().get("elements", [])
                            if fallback_elements:
                                elements = fallback_elements
                                print(f"  Merkez yedeği kaynağı: {endpoint}", flush=True)
                                break
                        except requests.RequestException as exc:
                            print(f"  Merkez yedeği başarısız ({endpoint}): {exc}", flush=True)
                            time.sleep(1)

            for el in elements:
                tags = el.get("tags") or {}
                name = tags.get("name") or tags.get("name:tr")
                lat, lon = element_point(el)
                if not name or lat is None or lon is None:
                    continue
                category, label = category_for(tags)
                external_id = f'{el.get("type")}/{el.get("id")}'
                address_parts = [
                    tags.get("addr:street"),
                    tags.get("addr:housenumber"),
                    tags.get("addr:suburb") or tags.get("addr:district"),
                    city,
                ]
                address = ", ".join(part for part in address_parts if part)
                website = tags.get("website") or tags.get("contact:website")
                row = {
                    "external_source": "openstreetmap",
                    "external_id": external_id,
                    "name": name[:180],
                    "slug": f"osm-{el.get('type')}-{el.get('id')}",
                    "category": category,
                    "place_type": tags.get("tourism") or tags.get("leisure") or tags.get("historic") or tags.get("amenity") or label,
                    "city": city,
                    "address": address[:350] or city,
                    "latitude": float(lat),
                    "longitude": float(lon),
                    "website": website,
                    "short_description": short_description(name, tags, label),
                    "is_free": True if tags.get("fee") == "no" else (False if tags.get("fee") == "yes" else None),
                    "visit_duration_min": 90 if category in ("Müze","Tarih","Kültür") else 60,
                    "indoor": category in ("Müze","Sanat","Kültür"),
                    "outdoor": category in ("Park","Gezi","Tarih","Hayvanat Bahçesi","Eğlence"),
                    "tags": list(dict.fromkeys([label, city, tags.get("tourism",""), tags.get("leisure",""), tags.get("historic","")])) ,
                    "verified": False,
                    "trust_score": 60,
                    "is_active": True,
                }
                row["tags"] = [tag for tag in row["tags"] if tag]
                all_rows[external_id] = row
                city_rows.append(row)
            print(f"  OSM sonuçları: {len(elements)}; isim ve koordinat kontrolünden sonra kaydedilecek: {len(city_rows)}", flush=True)
            for offset in range(0, len(city_rows), 100):
                chunk = city_rows[offset:offset+100]
                saved = session.post(
                    f"{SUPABASE_URL}/rest/v1/places?on_conflict=external_source,external_id",
                    headers=HEADERS,
                    json=chunk,
                    timeout=25,
                )
                saved.raise_for_status()
            print(f"  Supabase'e yazılan yer: {len(city_rows)}", flush=True)
            time.sleep(1.1)
        except Exception as exc:
            errors.append(f"{city}: {type(exc).__name__}: {exc}")
            print(f"  UYARI: {errors[-1]}", flush=True)
            time.sleep(2)
    rows = list(all_rows.values())
    print(f"Toplam tekil yer: {len(rows)}; sorunlu şehir sayısı: {len(errors)}", flush=True)
    print('Şehir bazlı aktarımlar tamamlandı.', flush=True)
    if errors:
        print("Bazı şehirler işlenemedi:")
        for error in errors:
            print(f" - {error}")
    if not rows:
        raise RuntimeError("Hiç yer bulunamadı; veri kaynağı yanıtlarını kontrol edin.")

if __name__ == "__main__":
    main()
