import hashlib
import feedparser

from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.article import Article
from app.utils.text import calculate_reading_time, detect_content_type

# Sources RSS configurées avec leur catégorie et label de biais
RSS_SOURCES = [

    # ══════════════════════════════════════════════════════
    # POLITIQUE & ACTUALITÉS
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://feeds.lemonde.fr/rss/une",
        "source_name": "Le Monde",
        "source_url": "lemonde.fr",
        "category": "politique",
        "source_bias": "center"
    },
    {
        "url": "https://www.lefigaro.fr/rss/figaro_actualites.xml",
        "source_name": "Le Figaro",
        "source_url": "lefigaro.fr",
        "category": "politique",
        "source_bias": "right"
    },
    {
        "url": "https://www.liberation.fr/arc/outboundfeeds/rss/",
        "source_name": "Libération",
        "source_url": "liberation.fr",
        "category": "politique",
        "source_bias": "left"
    },
    {
        "url": "https://www.lepoint.fr/rss.xml",
        "source_name": "Le Point",
        "source_url": "lepoint.fr",
        "category": "politique",
        "source_bias": "center-right"
    },
    {
        "url": "https://www.humanite.fr/rss.xml",
        "source_name": "L'Humanité",
        "source_url": "humanite.fr",
        "category": "politique",
        "source_bias": "left"
    },
    {
        "url": "https://www.sudouest.fr/rss.xml",
        "source_name": "Sud Ouest",
        "source_url": "sudouest.fr",
        "category": "politique",
        "source_bias": "center"
    },
    {
        "url": "https://www.lefigaro.fr/rss/figaro_politique.xml",
        "source_name": "Le Figaro Politique",
        "source_url": "lefigaro.fr",
        "category": "politique",
        "source_bias": "right"
    },

    # ── International ─────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/news/world/rss.xml",
        "source_name": "BBC World",
        "source_url": "bbc.co.uk",
        "category": "politique",
        "source_bias": "center"
    },
    {
        "url": "https://rss.nytimes.com/services/xml/rss/nyt/World.xml",
        "source_name": "New York Times",
        "source_url": "nytimes.com",
        "category": "politique",
        "source_bias": "center-left"
    },
    {
        "url": "https://feeds.skynews.com/feeds/rss/world.xml",
        "source_name": "Sky News",
        "source_url": "skynews.com",
        "category": "politique",
        "source_bias": "center-right"
    },

    # ══════════════════════════════════════════════════════
    # SPORT
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://www.lequipe.fr/rss/actu_rss.xml",
        "source_name": "L'Équipe",
        "source_url": "lequipe.fr",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://www.footmercato.net/rss",
        "source_name": "Foot Mercato",
        "source_url": "footmercato.net",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://www.rmcsport.fr/rss/",
        "source_name": "RMC Sport",
        "source_url": "rmcsport.fr",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://www.rugbyrama.fr/rss.xml",
        "source_name": "Rugbyrama",
        "source_url": "rugbyrama.fr",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://www.eurosport.fr/rss/",
        "source_name": "Eurosport",
        "source_url": "eurosport.fr",
        "category": "sport",
        "source_bias": "center"
    },

    # ── International ─────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/sport/rss.xml",
        "source_name": "BBC Sport",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.bbci.co.uk/sport/football/rss.xml",
        "source_name": "BBC Football",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.bbci.co.uk/sport/tennis/rss.xml",
        "source_name": "BBC Tennis",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.bbci.co.uk/sport/formula1/rss.xml",
        "source_name": "BBC Formula 1",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.bbci.co.uk/sport/rugby-union/rss.xml",
        "source_name": "BBC Rugby",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },

    # ══════════════════════════════════════════════════════
    # BOURSE & FINANCE
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://www.lesechos.fr/rss/rss_une.xml",
        "source_name": "Les Échos",
        "source_url": "lesechos.fr",
        "category": "bourse",
        "source_bias": "center-right"
    },

    # ── International ─────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/news/business/rss.xml",
        "source_name": "BBC Business",
        "source_url": "bbc.co.uk",
        "category": "bourse",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.reuters.com/reuters/businessNews",
        "source_name": "Reuters Business",
        "source_url": "reuters.com",
        "category": "bourse",
        "source_bias": "center"
    },

    # ══════════════════════════════════════════════════════
    # TECH
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://www.01net.com/rss/",
        "source_name": "01net",
        "source_url": "01net.com",
        "category": "tech",
        "source_bias": "center"
    },
    {
        "url": "https://www.numerama.com/feed/",
        "source_name": "Numerama",
        "source_url": "numerama.com",
        "category": "tech",
        "source_bias": "center"
    },

    # ── International ─────────────────────────────────────
    {
        "url": "https://www.theverge.com/rss/index.xml",
        "source_name": "The Verge",
        "source_url": "theverge.com",
        "category": "tech",
        "source_bias": "center"
    },
    {
        "url": "https://feeds.wired.com/wired/index",
        "source_name": "Wired",
        "source_url": "wired.com",
        "category": "tech",
        "source_bias": "center-left"
    },

    # ══════════════════════════════════════════════════════
    # ART & CULTURE
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://www.telerama.fr/rss",
        "source_name": "Télérama",
        "source_url": "telerama.fr",
        "category": "art",
        "source_bias": "center-left"
    },
    {
        "url": "https://www.lemonde.fr/culture/rss_full.xml",
        "source_name": "Le Monde Culture",
        "source_url": "lemonde.fr",
        "category": "art",
        "source_bias": "center"
    },
    {
        "url": "https://www.lefigaro.fr/rss/figaro_culture.xml",
        "source_name": "Le Figaro Culture",
        "source_url": "lefigaro.fr",
        "category": "art",
        "source_bias": "right"
    },

    # ══════════════════════════════════════════════════════
    # SCIENCE
    # ══════════════════════════════════════════════════════

    # ── France ────────────────────────────────────────────
    {
        "url": "https://www.futura-sciences.com/rss/actualites.rss",
        "source_name": "Futura Sciences",
        "source_url": "futura-sciences.com",
        "category": "science",
        "source_bias": "center"
    },

    # ── International ─────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/news/science_and_environment/rss.xml",
        "source_name": "BBC Science",
        "source_url": "bbc.co.uk",
        "category": "science",
        "source_bias": "center"
    },
]

def generate_hash(title: str, url: str) -> str:
    # Génère un hash SHA-256 unique pour chaque article — utilisé pour la déduplication
    content = f"{title}{url}".encode("utf-8")
    return hashlib.sha256(content).hexdigest()


async def scrape_source(source: dict, db: AsyncSession) -> int:
    inserted = 0
    seen_urls = set()

    try:
        feed = feedparser.parse(source["url"])

        for entry in feed.entries[:20]:
            title = entry.get("title", "").strip()
            url = entry.get("link", "").strip()

            if not title or not url or url in seen_urls:
                continue

            existing = await db.execute(
                select(Article).where(Article.url == url)
            )
            if existing.scalar_one_or_none():
                continue

            seen_urls.add(url)
            url_hash = generate_hash(title, url)

            published_at = None
            if hasattr(entry, "published_parsed") and entry.published_parsed:
                published_at = datetime(*entry.published_parsed[:6], tzinfo=timezone.utc)

            # Contenu RSS uniquement — trafilatura est utilisé à la demande dans ai_service.py
            final_content = entry.get("summary", "")

            # Calcul temps de lecture et type de contenu
            text_for_calc = f"{title} {final_content}".strip()
            word_count = len(text_for_calc.split())
            reading_time = calculate_reading_time(text_for_calc)
            content_type = detect_content_type(word_count)

            article = Article(
                title=title,
                url=url,
                url_hash=url_hash,
                content=final_content,
                image_url=None,
                source_name=source["source_name"],
                source_url=source["source_url"],
                category=source["category"],
                source_bias=source["source_bias"],
                published_at=published_at,
                reading_time=reading_time,
                content_type=content_type,
            )
            db.add(article)
            inserted += 1

        await db.commit()

    except Exception as e:
        print(f"Erreur scraping {source['source_name']}: {e}")
        await db.rollback()

    return inserted


async def run_scraper():
    # Lance le scraping de toutes les sources
    total = 0
    async with AsyncSessionLocal() as db:
        for source in RSS_SOURCES:
            count = await scrape_source(source, db)
            print(f"✅ {source['source_name']} — {count} nouveaux articles")
            total += count
    print(f"🎉 Scraping terminé — {total} articles insérés au total")
    return total