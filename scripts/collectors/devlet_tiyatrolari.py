import hashlib
import os
import re
from datetime import datetime, timezone
from urllib.parse import urljoin

from bs4 import BeautifulSoup
from dateutil import parser as date_parser
from supabase import create_client

BASE_URL = "https://www.devtiyatro.gov.tr"
PROGRAM_URL = f"{BASE_URL}/genel-program"

SOURCE_NAME = "Devlet Tiyatroları"
CITY = "Ankara"

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


ANKARA_SAHNELERI = {
    "Akün Sahnesi",
    "Büyük Tiyatro",
    "Cüneyt Gökçer Sahnesi",
    "İrfan Şahinbaş",
    "Küçük Tiyatro",
    "Oda Tiyatrosu",
    "Pursaklar Devlet Tiyatrosu Sahnesi",
    "Stüdyo Sahne",
    "Şinasi Sahnesi",
    "Ziraat Sahnesi",
    "Altındağ Tiyatrosu",
    "Etimesgut 100. Yıl Cumhuriyet Kültür Merkezi Sahnesi",
}


AYLAR = {
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


def clean_text(value):
    if not value:
        return None

    value = re.sub(r"\s+", " ", value)
    value = value.strip()

    return value or None


def fingerprint(title, starts_at, venue):
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


def get_source_id():
    result = (
        supabase
        .table("sources")
        .select("id")
        .eq("name", SOURCE_NAME)
        .limit(1)
        .execute()
    )

    if not result.data:
        raise RuntimeError(
            f"'{SOURCE_NAME}' kaynağı Supabase'de bulunamadı."
        )

    return result.data[0]["id"]


def http_get(url):
    import requests

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (X11; Linux x86_64) "
            "AppleWebKit/537.36 "
            "(KHTML, like Gecko) "
            "Chrome/131.0.0.0 Safari/537.36"
        )
    }

    response = requests.get(
        url,
        headers=headers,
        timeout=30,
    )

    response.raise_for_status()

    return response.text


def extract_play_links_from_html(html):
    """
    Devlet Tiyatroları genel programı JavaScript ile üretildiği için
    bağlantıları hem normal href'lerden hem de HTML/JS içerisindeki
    /oyunlar/... yollarından arıyoruz.
    """

    links = set()

    soup = BeautifulSoup(html, "html.parser")

    for anchor in soup.find_all("a", href=True):
        href = anchor.get("href")

        if not href:
            continue

        absolute = urljoin(BASE_URL, href)

        if "/oyunlar/" in absolute:
            links.add(absolute.split("#")[0])

    # JS/RSC payload içindeki bağlantılar
    patterns = [
        r'["\'](/oyunlar/[a-z0-9\-]+)["\']',
        r'["\'](https://(?:www\.)?devtiyatro\.gov\.tr/oyunlar/[a-z0-9\-]+)["\']',
    ]

    for pattern in patterns:
        for match in re.findall(
            pattern,
            html,
            flags=re.IGNORECASE,
        ):
            links.add(
                urljoin(BASE_URL, match).split("#")[0]
            )

    return sorted(links)


def extract_title(soup):
    h1 = soup.find("h1")

    if h1:
        title = clean_text(
            h1.get_text(" ", strip=True)
        )

        if title:
            return title

    if soup.title:
        title = clean_text(
            soup.title.get_text(" ", strip=True)
        )

        if title:
            title = re.sub(
                r"\s*-\s*Devlet Tiyatroları.*$",
                "",
                title,
                flags=re.IGNORECASE,
            )

            return clean_text(title)

    return None


def extract_date_range(soup):
    text = clean_text(
        soup.get_text(" ", strip=True)
    ) or ""

    pattern = re.compile(
        r"(\d{1,2})\s+"
        r"(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|"
        r"Ağustos|Eylül|Ekim|Kasım|Aralık)"
        r"\s*-\s*"
        r"(\d{1,2})\s+"
        r"(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|"
        r"Ağustos|Eylül|Ekim|Kasım|Aralık)"
        r"\s+(\d{4})",
        flags=re.IGNORECASE,
    )

    match = pattern.search(text)

    if match:
        day1 = int(match.group(1))
        month1 = AYLAR[match.group(2).lower()]
        day2 = int(match.group(3))
        month2 = AYLAR[match.group(4).lower()]
        year = int(match.group(5))

        start = datetime(
            year,
            month1,
            day1,
            tzinfo=timezone.utc,
        )

        end = datetime(
            year,
            month2,
            day2,
            23,
            59,
            tzinfo=timezone.utc,
        )

        return start, end

    # Aynı ay:
    pattern_same_month = re.compile(
        r"(\d{1,2})\s*-\s*(\d{1,2})\s+"
        r"(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|"
        r"Ağustos|Eylül|Ekim|Kasım|Aralık)"
        r"\s+(\d{4})",
        flags=re.IGNORECASE,
    )

    match = pattern_same_month.search(text)

    if match:
        day1 = int(match.group(1))
        day2 = int(match.group(2))
        month = AYLAR[match.group(3).lower()]
        year = int(match.group(4))

        start = datetime(
            year,
            month,
            day1,
            tzinfo=timezone.utc,
        )

        end = datetime(
            year,
            month,
            day2,
            23,
            59,
            tzinfo=timezone.utc,
        )

        return start, end

    return None


def extract_venue(soup):
    text = clean_text(
        soup.get_text(" ", strip=True)
    ) or ""

    # Öncelikle bilinen Ankara sahnelerini ara.
    for venue in sorted(
        ANKARA_SAHNELERI,
        key=len,
        reverse=True,
    ):
        if venue.lower() in text.lower():
            return venue

    return None


def extract_schedule_dates(soup, range_start, range_end):
    """
    Tarih kutularındaki sayıları bulmaya çalışır.

    Yeni sitede bazı bilgiler JS ile üretildiğinden,
    kesin seans verisi bulunamazsa oyun tarih aralığından
    tek bir temsil üretmek yerine güvenli biçimde boş döner.
    """

    dates = []

    # HTML'de datetime / data-date / date benzeri alanlar varsa kullan.
    for tag in soup.find_all(True):
        for attribute in (
            "datetime",
            "data-date",
            "data-start",
            "data-event-date",
        ):
            value = tag.get(attribute)

            if not value:
                continue

            value = str(value).strip()

            try:
                parsed = date_parser.parse(value)

                if parsed.tzinfo is None:
                    parsed = parsed.replace(
                        tzinfo=timezone.utc
                    )
                else:
                    parsed = parsed.astimezone(timezone.utc)

                if range_start <= parsed <= range_end:
                    dates.append(parsed)

            except (ValueError, TypeError, OverflowError):
                pass

    unique = {}

    for item in dates:
        key = item.strftime("%Y-%m-%d")

        if key not in unique:
            unique[key] = item

    return list(unique.values())


def choose_category(title):
    normalized = title.lower()

    if any(
        word in normalized
        for word in (
            "müzikal",
            "müzikali",
        )
    ):
        return "Tiyatro"

    if any(
        word in normalized
        for word in (
            "çocuk",
            "karga",
            "toti",
            "poti",
        )
    ):
        return "Çocuk"

    return "Tiyatro"


def build_rows(event_url, soup, source_id):
    title = extract_title(soup)

    if not title:
        return []

    date_range = extract_date_range(soup)

    if not date_range:
        return []

    range_start, range_end = date_range

    now = datetime.now(timezone.utc)

    if range_end < now:
        return []

    venue = extract_venue(soup)
    category = choose_category(title)

    schedule_dates = extract_schedule_dates(
        soup,
        range_start,
        range_end,
    )

    rows = []

    # Gerçek temsil tarihleri yakalanırsa onları kullan.
    for event_date in schedule_dates:
        event_date = event_date.replace(
            hour=19,
            minute=0,
            second=0,
            microsecond=0,
        )

        if event_date < now:
            continue

        rows.append(
            {
                "title": title,
                "city": CITY,
                "category": category,
                "description": None,
                "starts_at": event_date.isoformat(),
                "ends_at": None,
                "venue_name": venue,
                "place_id": None,
                "price_min": None,
                "price_max": None,
                "image_url": None,
                "trust_score": 95,
                "recommendation_score": 0,
                "source_id": source_id,
                "fingerprint": fingerprint(
                    title,
                    event_date,
                    venue,
                ),
                "is_active": True,
                "source_url": event_url,
            }
        )

    # Takvim tarihleri DOM'dan okunamazsa henüz
    # temsil saati uydurmuyoruz.
    if not rows:
        print(
            f"UYARI: {title} için oyun tarih aralığı bulundu "
            f"ama kesin temsil tarihi/saat bilgisi okunamadı."
        )

    return rows


def upsert_rows(rows):
    if not rows:
        return 0

    result = (
        supabase
        .table("events")
        .upsert(
            rows,
            on_conflict="fingerprint",
        )
        .execute()
    )

    return len(result.data or [])


def main():
    print(
        "Devlet Tiyatroları collector başladı."
    )

    print(
        f"Kaynak: {PROGRAM_URL}"
    )

    source_id = get_source_id()

    html = http_get(PROGRAM_URL)

    links = extract_play_links_from_html(html)

    print(
        f"Bulunan etkinlik bağlantısı: {len(links)}"
    )

    if not links:
        print(
            "UYARI: Genel program HTML/RSC içinde oyun bağlantısı bulunamadı."
        )
        return

    all_rows = []

    for index, event_url in enumerate(
        links,
        start=1,
    ):
        try:
            print(
                f"[{index}/{len(links)}] {event_url}"
            )

            event_html = http_get(event_url)

            soup = BeautifulSoup(
                event_html,
                "html.parser",
            )

            rows = build_rows(
                event_url=event_url,
                soup=soup,
                source_id=source_id,
            )

            all_rows.extend(rows)

        except Exception as exc:
            print(
                f"HATA: {event_url} -> {exc}"
            )

    print(
        f"Toplam hazırlanmış kayıt: {len(all_rows)}"
    )

    inserted = upsert_rows(all_rows)

    print(
        f"Supabase'e işlenen kayıt: {inserted}"
    )

    print(
        "Devlet Tiyatroları collector tamamlandı."
    )


if __name__ == "__main__":
    main()