import hashlib
import json
import os
import re
from datetime import datetime
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from supabase import create_client


CITY = "Ankara"
SOURCE_NAME = "Biletinial"

# Ankara'nın doğrudan etkinlik sayfasını kullanıyoruz.
SOURCE_URL = "https://biletinial.com/tr-tr/etkinlik/ankara"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 "
        "(KHTML, like Gecko) "
        "Chrome/140.0 Safari/537.36"
    ),
    "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
}


MONTHS = {
    "ocak": 1,
    "şubat": 2,
    "mart": 3,
    "nisan": 4,
    "mayıs": 5,
    "haziran": 6,
    "temmuz": 7,
    "ağustos": 8,
    "eylül": 9,
    "ekim": 10,
    "kasım": 11,
    "aralık": 12,
}


def normalize(value):
    return re.sub(r"\s+", " ", value or "").strip()


def get_client():
    url = os.environ["SUPABASE_URL"]
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    return create_client(url, key)


def fetch(url):
    response = requests.get(
        url,
        headers=HEADERS,
        timeout=30,
    )

    response.raise_for_status()

    return response.text


def get_source_id(client):
    result = (
        client.table("sources")
        .select("id")
        .eq("name", SOURCE_NAME)
        .limit(1)
        .execute()
    )

    if result.data:
        return result.data[0]["id"]

    result = (
        client.table("sources")
        .insert(
            {
                "name": SOURCE_NAME,
                "source_type": "ticketing",
                "base_url": SOURCE_URL,
                "trust_score": 95,
                "is_active": True,
            }
        )
        .execute()
    )

    return result.data[0]["id"]


def make_fingerprint(title, starts_at, venue):
    text = "|".join(
        [
            normalize(title).lower(),
            normalize(starts_at),
            normalize(venue).lower(),
        ]
    )

    return hashlib.sha256(
        text.encode("utf-8")
    ).hexdigest()


def find_event_links(html):
    soup = BeautifulSoup(html, "html.parser")

    results = []
    seen = set()

    for anchor in soup.find_all("a", href=True):
        href = normalize(anchor.get("href"))

        if not href:
            continue

        full_url = urljoin(
            SOURCE_URL,
            href,
        )

        # Yalnızca etkinlik detay sayfaları.
        if "/tr-tr/etkinlik/" not in full_url:
            continue

        if full_url.rstrip("/") == SOURCE_URL.rstrip("/"):
            continue

        title = normalize(
            anchor.get_text(" ", strip=True)
        )

        # Bazı kartlarda başlık anchor'ın içinde
        # olmayabilir. Bu durumda çevresindeki yapıyı deniyoruz.
        if not title or len(title) < 3:
            parent = anchor.find_parent(
                ["article", "li", "div"]
            )

            if parent:
                title = normalize(
                    parent.get_text(
                        " ",
                        strip=True,
                    )
                )

        # Çok uzun blokları etkinlik başlığı olarak alma.
        if len(title) > 300:
            continue

        if full_url in seen:
            continue

        seen.add(full_url)

        results.append(
            {
                "title": title,
                "url": full_url,
            }
        )

    return results


def extract_json_ld(soup):
    result = []

    for script in soup.find_all(
        "script",
        attrs={
            "type": "application/ld+json"
        },
    ):
        raw = script.string or script.get_text()

        if not raw:
            continue

        try:
            data = json.loads(raw)
        except Exception:
            continue

        if isinstance(data, list):
            result.extend(data)
        else:
            result.append(data)

    return result


def category_from_text(text):
    text = normalize(text).lower()

    if "konser" in text or "müzik" in text:
        return "Konser"

    if "tiyatro" in text:
        return "Tiyatro"

    if (
        "stand up" in text
        or "stand-up" in text
        or "komedi" in text
    ):
        return "Stand-up"

    if "sergi" in text:
        return "Sergi"

    if (
        "atölye" in text
        or "workshop" in text
    ):
        return "Atölye"

    if (
        "maç" in text
        or "spor" in text
    ):
        return "Spor"

    if (
        "film" in text
        or "sinema" in text
    ):
        return "Sinema"

    if "festival" in text:
        return "Festival"

    if "çocuk" in text:
        return "Çocuk"

    return "Etkinlik"


def parse_json_ld_event(
    data,
    page_url,
):
    if not isinstance(data, dict):
        return None

    event_type = data.get("@type")

    valid_types = {
        "Event",
        "SocialEvent",
        "MusicEvent",
    }

    if event_type not in valid_types:
        return None

    title = normalize(
        data.get("name")
        or data.get("headline")
    )

    starts_at = data.get("startDate")

    if not title or not starts_at:
        return None

    try:
        parsed_start = datetime.fromisoformat(
            starts_at.replace("Z", "+00:00")
        )

        starts_at = parsed_start.isoformat()

    except ValueError:
        return None

    venue = None
    address = None
    latitude = None
    longitude = None

    location = data.get("location")

    if isinstance(location, dict):
        venue = normalize(
            location.get("name")
        )

        address_data = location.get(
            "address"
        )

        if isinstance(
            address_data,
            dict,
        ):
            address = normalize(
                address_data.get(
                    "streetAddress"
                )
            )
        else:
            address = normalize(
                address_data
            )

        latitude = (
            location.get("latitude")
        )

        longitude = (
            location.get("longitude")
        )

    image_url = None

    image = data.get("image")

    if isinstance(image, list) and image:
        image_url = image[0]

    elif isinstance(image, str):
        image_url = image

    price = None

    offers = data.get("offers")

    if isinstance(offers, dict):
        price = offers.get("price")

    elif isinstance(offers, list) and offers:
        price = offers[0].get("price")

    try:
        price = (
            float(price)
            if price is not None
            else None
        )
    except (
        TypeError,
        ValueError,
    ):
        price = None

    description = normalize(
        data.get("description")
    )

    return {
        "title": title,
        "description": description,
        "category": category_from_text(
            data.get("eventType")
            or title
        ),
        "starts_at": starts_at,
        "venue": venue,
        "address": address,
        "latitude": latitude,
        "longitude": longitude,
        "price_min": price,
        "price_max": price,
        "image_url": (
            urljoin(
                page_url,
                image_url,
            )
            if image_url
            else None
        ),
        "source_url": page_url,
    }


def parse_event_page(
    url,
    fallback_title,
):
    html = fetch(url)
    soup = BeautifulSoup(
        html,
        "html.parser",
    )

    # Önce yapılandırılmış JSON-LD verisini dene.
    for item in extract_json_ld(soup):
        event = parse_json_ld_event(
            item,
            url,
        )

        if event:
            return event

    # JSON-LD yoksa sayfa metninden
    # temel bilgileri çıkarmaya çalış.
    title = fallback_title

    h1 = soup.find("h1")

    if h1:
        title = normalize(
            h1.get_text(
                " ",
                strip=True,
            )
        )

    text = normalize(
        soup.get_text(
            " ",
            strip=True,
        )
    )

    if not title:
        return None

    starts_at = parse_date_time(text)

    if not starts_at:
        return None

    price = parse_price(text)

    venue = find_venue(soup)

    image_url = None

    og_image = soup.find(
        "meta",
        attrs={
            "property": "og:image"
        },
    )

    if og_image:
        image_url = urljoin(
            url,
            og_image.get(
                "content",
                "",
            ),
        )

    description = ""

    meta_description = soup.find(
        "meta",
        attrs={
            "name": "description"
        },
    )

    if meta_description:
        description = normalize(
            meta_description.get(
                "content",
                "",
            )
        )

    return {
        "title": title,
        "description": description,
        "category": category_from_text(text),
        "starts_at": starts_at,
        "venue": venue,
        "address": None,
        "latitude": None,
        "longitude": None,
        "price_min": price,
        "price_max": price,
        "image_url": image_url,
        "source_url": url,
    }


def parse_date_time(text):
    pattern = re.compile(
        r"(\d{1,2})\s+"
        r"(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|"
        r"Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)"
        r"(?:\s+(\d{4}))?"
        r".{0,40}?"
        r"(\d{1,2})[:.](\d{2})",
        re.IGNORECASE,
    )

    match = pattern.search(text)

    if not match:
        return None

    day = int(match.group(1))
    month = MONTHS[
        match.group(2).lower()
    ]

    year = (
        int(match.group(3))
        if match.group(3)
        else datetime.now().year
    )

    hour = int(match.group(4))
    minute = int(match.group(5))

    try:
        return datetime(
            year,
            month,
            day,
            hour,
            minute,
        ).astimezone().isoformat()

    except ValueError:
        return None


def parse_price(text):
    match = re.search(
        r"(\d[\d.]*(?:,\d{1,2})?)\s*(?:₺|TL)",
        text,
        re.IGNORECASE,
    )

    if not match:
        return None

    value = (
        match.group(1)
        .replace(".", "")
        .replace(",", ".")
    )

    try:
        return float(value)

    except ValueError:
        return None


def find_venue(soup):
    # Önce JSON-LD zaten denendiği için
    # burada görsel sayfadaki olası mekan bilgisini
    # sınırlı şekilde arıyoruz.

    keywords = [
        "Ankara",
        "Sahne",
        "Salon",
        "Teras",
        "Hall",
        "Business Club",
        "Coffee",
        "Bar",
    ]

    for tag in soup.find_all(
        ["h2", "h3", "strong"]
    ):
        text = normalize(
            tag.get_text(
                " ",
                strip=True,
            )
        )

        if not text:
            continue

        if any(
            keyword.lower() in text.lower()
            for keyword in keywords
        ):
            return text

    return None


def get_place_id(
    client,
    event,
):
    venue = event.get("venue")

    if not venue:
        return None

    existing = (
        client.table("places")
        .select("id")
        .eq("name", venue)
        .eq("city", CITY)
        .limit(1)
        .execute()
    )

    if existing.data:
        return existing.data[0]["id"]

    result = (
        client.table("places")
        .insert(
            {
                "name": venue,
                "city": CITY,
                "address": event.get(
                    "address"
                ),
                "latitude": event.get(
                    "latitude"
                ),
                "longitude": event.get(
                    "longitude"
                ),
                "trust_score": 90,
                "verified": False,
            }
        )
        .execute()
    )

    if result.data:
        return result.data[0]["id"]

    return None


def upsert_event(
    client,
    source_id,
    event,
):
    place_id = get_place_id(
        client,
        event,
    )

    fingerprint = make_fingerprint(
        event["title"],
        event["starts_at"],
        event.get("venue"),
    )

    payload = {
        "source_id": source_id,
        "place_id": place_id,
        "title": event["title"],
        "description": event.get(
            "description"
        ),
        "category": event["category"],
        "city": CITY,
        "starts_at": event["starts_at"],
        "price_min": event.get(
            "price_min"
        ),
        "price_max": event.get(
            "price_max"
        ),
        "source_url": event["source_url"],
        "image_url": event.get(
            "image_url"
        ),
        "trust_score": 95,
        "popularity_score": 0,
        "recommendation_score": 60,
        "is_active": True,
        "fingerprint": fingerprint,
    }

    (
        client.table("events")
        .upsert(
            payload,
            on_conflict="fingerprint",
        )
        .execute()
    )


def main():
    print(
        "=== BUGÜN Biletinial Collector ==="
    )
    print(
        f"Kaynak: {SOURCE_URL}"
    )

    client = get_client()
    source_id = get_source_id(client)

    listing_html = fetch(
        SOURCE_URL
    )

    print(
        f"Liste sayfası indirildi: "
        f"{len(listing_html)} karakter"
    )

    links = find_event_links(
        listing_html
    )

    print(
        f"Etkinlik bağlantısı bulundu: "
        f"{len(links)}"
    )

    if not links:
        raise RuntimeError(
            "Biletinial sayfasında hiç etkinlik "
            "bağlantısı bulunamadı."
        )

    imported = 0
    skipped = 0

    max_events = min(
        len(links),
        100,
    )

    for index, item in enumerate(
        links[:100],
        start=1,
    ):
        try:
            print(
                f"[{index}/{max_events}] "
                f"{item['title'][:100]}"
            )

            event = parse_event_page(
                item["url"],
                item["title"],
            )

            if not event:
                print(
                    "    -> tarih bulunamadı"
                )
                skipped += 1
                continue

            upsert_event(
                client,
                source_id,
                event,
            )

            imported += 1

            print(
                f"    -> AKTARILDI | "
                f"{event['category']} | "
                f"{event['starts_at']}"
            )

        except Exception as exc:
            print(
                f"    -> HATA | "
                f"{type(exc).__name__}: {exc}"
            )
            skipped += 1

    print()
    print(
        "=== SONUÇ ==="
    )
    print(
        f"Aktarılan: {imported}"
    )
    print(
        f"Atlanan: {skipped}"
    )

    if imported == 0:
        raise RuntimeError(
            "Hiçbir etkinlik içe aktarılamadı."
        )


if __name__ == "__main__":
    main()