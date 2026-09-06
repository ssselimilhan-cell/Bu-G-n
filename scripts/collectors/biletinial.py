import hashlib
import json
import os
import re
from datetime import datetime
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from supabase import create_client


SOURCE_URL = "https://biletinial.com/tr-tr/etkinlik"
SOURCE_NAME = "Biletinial"
CITY = "Ankara"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/140.0 Safari/537.36"
    )
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


def normalize_text(value):
    return re.sub(r"\s+", " ", value or "").strip()


def make_fingerprint(title, starts_at, venue):
    raw = "|".join(
        [
            normalize_text(title).lower(),
            normalize_text(starts_at),
            normalize_text(venue).lower(),
        ]
    )
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


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


def extract_json_ld(soup):
    items = []

    for script in soup.find_all(
        "script",
        attrs={"type": "application/ld+json"},
    ):
        raw = script.string or script.get_text()

        if not raw:
            continue

        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            continue

        if isinstance(data, list):
            items.extend(data)
        else:
            items.append(data)

    return items


def parse_event_from_json_ld(data, page_url):
    if not isinstance(data, dict):
        return None

    event_type = data.get("@type")

    if event_type not in ("Event", "SocialEvent", "MusicEvent"):
        return None

    title = normalize_text(
        data.get("name")
        or data.get("headline")
    )

    if not title:
        return None

    starts_at = data.get("startDate")

    if not starts_at:
        return None

    try:
        parsed = datetime.fromisoformat(
            starts_at.replace("Z", "+00:00")
        )
    except ValueError:
        return None

    location = data.get("location")
    venue = None
    address = None

    if isinstance(location, dict):
        venue = normalize_text(location.get("name"))

        location_address = location.get("address")

        if isinstance(location_address, dict):
            address = normalize_text(
                location_address.get("streetAddress")
            )
        else:
            address = normalize_text(location_address)

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

    if isinstance(offers, list) and offers:
        price = offers[0].get("price")

    try:
        price = float(price) if price is not None else None
    except (TypeError, ValueError):
        price = None

    description = normalize_text(
        data.get("description")
    )

    return {
        "title": title,
        "description": description,
        "category": map_category(
            data.get("eventType") or "Etkinlik"
        ),
        "starts_at": parsed.isoformat(),
        "venue": venue,
        "address": address,
        "price_min": price,
        "price_max": price,
        "image_url": (
            urljoin(page_url, image_url)
            if image_url
            else None
        ),
        "source_url": page_url,
    }


def map_category(value):
    text = normalize_text(value).lower()

    if any(
        word in text
        for word in [
            "konser",
            "müzik",
            "music",
        ]
    ):
        return "Konser"

    if "tiyatro" in text:
        return "Tiyatro"

    if any(
        word in text
        for word in [
            "stand up",
            "stand-up",
            "comedy",
        ]
    ):
        return "Stand-up"

    if "sergi" in text:
        return "Sergi"

    if any(
        word in text
        for word in [
            "atölye",
            "workshop",
        ]
    ):
        return "Atölye"

    if any(
        word in text
        for word in [
            "spor",
            "maç",
        ]
    ):
        return "Spor"

    if "film" in text:
        return "Sinema"

    if "festival" in text:
        return "Festival"

    return "Etkinlik"


def find_event_links(soup):
    links = []

    for anchor in soup.find_all("a", href=True):
        href = anchor["href"]

        if "/tr-tr/etkinlik/" not in href:
            continue

        title = normalize_text(
            anchor.get_text(" ", strip=True)
        )

        if len(title) < 3:
            continue

        url = urljoin(
            SOURCE_URL,
            href,
        )

        if url not in {
            item["url"]
            for item in links
        }:
            links.append(
                {
                    "title": title,
                    "url": url,
                }
            )

    return links


def parse_event_page(url):
    html = fetch(url)
    soup = BeautifulSoup(
        html,
        "html.parser",
    )

    json_ld_items = extract_json_ld(soup)

    for item in json_ld_items:
        event = parse_event_from_json_ld(
            item,
            url,
        )

        if event:
            return event

    return parse_event_from_text(
        soup,
        url,
    )


def parse_event_from_text(soup, url):
    title = None

    h1 = soup.find("h1")

    if h1:
        title = normalize_text(
            h1.get_text(" ", strip=True)
        )

    if not title:
        meta_title = soup.find(
            "meta",
            attrs={"property": "og:title"},
        )

        if meta_title:
            title = normalize_text(
                meta_title.get("content")
            )

    if not title:
        return None

    text = normalize_text(
        soup.get_text(" ", strip=True)
    )

    date_match = re.search(
        r"(\d{1,2})\s+"
        r"(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|"
        r"Ağustos|Eylül|Ekim|Kasım|Aralık)"
        r"(?:\s+\d{4})?"
        r"(?:\s*[-|]\s*)?"
        r"(\d{1,2})[:.](\d{2})",
        text,
        flags=re.IGNORECASE,
    )

    starts_at = None

    if date_match:
        try:
            day = int(date_match.group(1))
            month = MONTHS[
                date_match.group(2).lower()
            ]
            hour = int(date_match.group(3))
            minute = int(date_match.group(4))

            now = datetime.now()

            year_match = re.search(
                rf"{day}\s+"
                rf"{re.escape(date_match.group(2))}"
                r"\s+(\d{4})",
                text,
                flags=re.IGNORECASE,
            )

            year = (
                int(year_match.group(1))
                if year_match
                else now.year
            )

            dt = datetime(
                year,
                month,
                day,
                hour,
                minute,
            )

            starts_at = dt.astimezone().isoformat()

        except (ValueError, KeyError):
            starts_at = None

    if starts_at is None:
        return None

    price = None

    price_match = re.search(
        r"(\d[\d.]*(?:,\d{1,2})?)\s*(?:₺|TL)",
        text,
        flags=re.IGNORECASE,
    )

    if price_match:
        raw = (
            price_match.group(1)
            .replace(".", "")
            .replace(",", ".")
        )

        try:
            price = float(raw)
        except ValueError:
            price = None

    venue = None

    venue_candidates = [
        tag.get_text(" ", strip=True)
        for tag in soup.find_all(
            ["h2", "h3", "strong"]
        )
    ]

    for candidate in venue_candidates:
        candidate = normalize_text(candidate)

        if 3 <= len(candidate) <= 150:
            venue = candidate
            break

    description = normalize_text(
        soup.find(
            "meta",
            attrs={"name": "description"},
        ).get("content")
        if soup.find(
            "meta",
            attrs={"name": "description"},
        )
        else ""
    )

    image_url = None

    image_meta = soup.find(
        "meta",
        attrs={"property": "og:image"},
    )

    if image_meta:
        image_url = urljoin(
            url,
            image_meta.get("content", ""),
        )

    return {
        "title": title,
        "description": description,
        "category": map_category(text),
        "starts_at": starts_at,
        "venue": venue,
        "address": None,
        "price_min": price,
        "price_max": price,
        "image_url": image_url,
        "source_url": url,
    }


def get_place_id(client, venue, address):
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
                "address": address,
                "trust_score": 90,
                "verified": False,
            }
        )
        .execute()
    )

    return (
        result.data[0]["id"]
        if result.data
        else None
    )


def upsert_event(client, source_id, event):
    place_id = get_place_id(
        client,
        event["venue"],
        event["address"],
    )

    fp = make_fingerprint(
        event["title"],
        event["starts_at"],
        event["venue"],
    )

    payload = {
        "source_id": source_id,
        "place_id": place_id,
        "title": event["title"],
        "description": event["description"],
        "category": event["category"],
        "city": CITY,
        "starts_at": event["starts_at"],
        "price_min": event["price_min"],
        "price_max": event["price_max"],
        "source_url": event["source_url"],
        "image_url": event["image_url"],
        "trust_score": 95,
        "popularity_score": 0,
        "recommendation_score": 60,
        "is_active": True,
        "fingerprint": fp,
    }

    client.table("events").upsert(
        payload,
        on_conflict="fingerprint",
    ).execute()


def main():
    print("BUGÜN Biletinial collector başladı.")

    client = get_client()
    source_id = get_source_id(client)

    html = fetch(SOURCE_URL)
    soup = BeautifulSoup(
        html,
        "html.parser",
    )

    links = find_event_links(soup)

    print(
        f"Liste sayfasında {len(links)} etkinlik bağlantısı bulundu."
    )

    imported = 0
    skipped = 0

    for index, item in enumerate(
        links[:100],
        start=1,
    ):
        try:
            print(
                f"[{index}/{min(len(links), 100)}] "
                f"{item['title']}"
            )

            event = parse_event_page(
                item["url"]
            )

            if not event:
                print("  -> tarih bulunamadı, atlandı.")
                skipped += 1
                continue

            starts_at = event["starts_at"]

            # Sadece Ankara etkinliklerini kabul ediyoruz.
            # Biletinial liste sayfasında şehir bilgisi bulunabileceği
            # için başlık/metin içinde Ankara kontrolü yapıyoruz.
            page_text = normalize_text(
                fetch(item["url"])
            ).lower()

            if "ankara" not in page_text:
                print("  -> Ankara olmadığı düşünüldü, atlandı.")
                skipped += 1
                continue

            upsert_event(
                client,
                source_id,
                event,
            )

            imported += 1

            print(
                f"  -> AKTARILDI | "
                f"{event['category']} | "
                f"{starts_at}"
            )

        except requests.RequestException as exc:
            print(
                f"  -> HTTP hatası: {exc}"
            )
            skipped += 1

        except Exception as exc:
            print(
                f"  -> Hata: {type(exc).__name__}: {exc}"
            )
            skipped += 1

    print()
    print("Collector tamamlandı.")
    print(f"Aktarılan: {imported}")
    print(f"Atlanan: {skipped}")


if __name__ == "__main__":
    main()