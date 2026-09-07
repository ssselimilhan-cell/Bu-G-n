import hashlib
import os
import re
from datetime import datetime, timezone
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from dateutil import parser as date_parser
from supabase import create_client

BASE_URL = "https://www.devtiyatro.gov.tr"
PROGRAM_URL = f"{BASE_URL}/genel-program"
SOURCE_NAME = "Devlet Tiyatroları"
CITY = "Ankara"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux x86_64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/131.0.0.0 Safari/537.36"
    )
}

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
    raise RuntimeError(
        "SUPABASE_URL ve SUPABASE_SERVICE_ROLE_KEY ortam değişkenleri gerekli."
    )

supabase = create_client(
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
)

session = requests.Session()
session.headers.update(HEADERS)


def clean_text(value: str | None) -> str | None:
    if not value:
        return None

    value = re.sub(r"\s+", " ", value)
    value = value.strip()

    return value or None


def fingerprint(title: str, starts_at: datetime, venue: str | None) -> str:
    raw = "|".join(
        [
            CITY.lower(),
            SOURCE_NAME.lower(),
            title.lower(),
            starts_at.strftime("%Y-%m-%d %H:%M"),
            (venue or "").lower(),
        ]
    )

    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def get_source_id() -> str:
    response = (
        supabase
        .table("sources")
        .select("id")
        .eq("name", SOURCE_NAME)
        .limit(1)
        .execute()
    )

    if not response.data:
        raise RuntimeError(
            f"'{SOURCE_NAME}' kaynağı Supabase'de bulunamadı."
        )

    return response.data[0]["id"]


def fetch(url: str) -> BeautifulSoup:
    response = session.get(url, timeout=30)
    response.raise_for_status()
    return BeautifulSoup(response.text, "html.parser")


def find_event_links(soup: BeautifulSoup) -> list[str]:
    links: set[str] = set()

    for anchor in soup.find_all("a", href=True):
        href = anchor.get("href", "").strip()

        if not href:
            continue

        absolute_url = urljoin(BASE_URL, href)

        if "/oyunlar/" in absolute_url:
            links.add(absolute_url.split("#")[0])

        if "/festivaller/" in absolute_url:
            links.add(absolute_url.split("#")[0])

    return sorted(links)


def parse_date_ranges(soup: BeautifulSoup) -> list[tuple[datetime, datetime]]:
    text = clean_text(soup.get_text(" ", strip=True)) or ""

    patterns = [
        r"(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s*-\s*(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})",
        r"(\d{1,2})\s*-\s*(\d{1,2})\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+(\d{4})",
    ]

    month_map = {
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

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE)

        if not match:
            continue

        try:
            if len(match.groups()) == 5:
                day1, month1, day2, month2, year = match.groups()

                start = datetime(
                    int(year),
                    month_map[month1.lower()],
                    int(day1),
                    tzinfo=timezone.utc,
                )

                end = datetime(
                    int(year),
                    month_map[month2.lower()],
                    int(day2),
                    23,
                    59,
                    tzinfo=timezone.utc,
                )

                return [(start, end)]

            day1, day2, month_name, year = match.groups()

            month = month_map[month_name.lower()]

            start = datetime(
                int(year),
                month,
                int(day1),
                tzinfo=timezone.utc,
            )

            end = datetime(
                int(year),
                month,
                int(day2),
                23,
                59,
                tzinfo=timezone.utc,
            )

            return [(start, end)]

        except (KeyError, ValueError):
            continue

    return []


def extract_title(soup: BeautifulSoup) -> str | None:
    h1 = soup.find("h1")

    if h1:
        title = clean_text(h1.get_text(" ", strip=True))
        if title:
            return title

    if soup.title:
        title = clean_text(soup.title.get_text(" ", strip=True))

        if title:
            title = re.sub(
                r"\s*-\s*Devlet Tiyatroları.*$",
                "",
                title,
                flags=re.IGNORECASE,
            )

            return clean_text(title)

    return None


def extract_venue(soup: BeautifulSoup) -> str | None:
    text = clean_text(soup.get_text(" ", strip=True)) or ""

    patterns = [
        r"(?:Sahne|Salon|Mekan)\s*[:\-]\s*([^|]+?)(?=\s{2,}|Adres|Bilet|Tarih|$)",
        r"(Akün Sahnesi|Cüneyt Gökçer Sahnesi|Şinasi Sahnesi|Oda Tiyatrosu)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text, flags=re.IGNORECASE)

        if match:
            value = clean_text(match.group(1))

            if value:
                return value

    return None


def extract_start_time(soup: BeautifulSoup) -> str | None:
    text = clean_text(soup.get_text(" ", strip=True)) or ""

    match = re.search(
        r"\b([01]?\d|2[0-3])[:.]([0-5]\d)\b",
        text,
    )

    if not match:
        return None

    hour = int(match.group(1))
    minute = int(match.group(2))

    return f"{hour:02d}:{minute:02d}"


def choose_category(title: str) -> str:
    normalized = title.lower()

    if "festival" in normalized:
        return "Festival"

    return "Tiyatro"


def build_event_rows(
    event_url: str,
    soup: BeautifulSoup,
    source_id: str,
) -> list[dict]:
    title = extract_title(soup)

    if not title:
        return []

    date_ranges = parse_date_ranges(soup)

    if not date_ranges:
        return []

    venue = extract_venue(soup)
    start_time = extract_start_time(soup)
    category = choose_category(title)

    rows = []

    now = datetime.now(timezone.utc)

    for start_date, end_date in date_ranges:
        if end_date < now:
            continue

        effective_start = start_date

        if start_time:
            hour, minute = start_time.split(":")
            effective_start = effective_start.replace(
                hour=int(hour),
                minute=int(minute),
            )

        fp = fingerprint(
            title=title,
            starts_at=effective_start,
            venue=venue,
        )

        rows.append(
            {
                "title": title,
                "city": CITY,
                "category": category,
                "starts_at": effective_start.isoformat(),
                "ends_at": end_date.isoformat(),
                "venue_name": venue,
                "place_id": None,
                "price_min": None,
                "price_max": None,
                "image_url": None,
                "description": None,
                "trust_score": 95,
                "recommendation_score": 0,
                "source_id": source_id,
                "fingerprint": fp,
                "is_active": True,
                "source_url": event_url,
            }
        )

    return rows


def upsert_events(rows: list[dict]) -> None:
    if not rows:
        return

    response = (
        supabase
        .table("events")
        .upsert(
            rows,
            on_conflict="fingerprint",
        )
        .execute()
    )

    count = len(response.data or [])

    print(f"Supabase: {count} kayıt işlendi.")


def main() -> None:
    print("Devlet Tiyatroları collector başladı.")
    print(f"Kaynak: {PROGRAM_URL}")

    source_id = get_source_id()

    program_soup = fetch(PROGRAM_URL)

    event_links = find_event_links(program_soup)

    print(f"Bulunan etkinlik bağlantısı: {len(event_links)}")

    all_rows: list[dict] = []

    for index, event_url in enumerate(event_links, start=1):
        try:
            print(
                f"[{index}/{len(event_links)}] "
                f"{event_url}"
            )

            event_soup = fetch(event_url)

            rows = build_event_rows(
                event_url=event_url,
                soup=event_soup,
                source_id=source_id,
            )

            all_rows.extend(rows)

        except Exception as exc:
            print(
                f"HATA: {event_url} -> {exc}"
            )

    print(f"Toplam hazırlanmış kayıt: {len(all_rows)}")

    upsert_events(all_rows)

    print("Devlet Tiyatroları collector tamamlandı.")


if __name__ == "__main__":
    main()


