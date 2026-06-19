import hashlib
import feedparser
import httpx
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import AsyncSessionLocal
from app.models.article import Article


# Sources RSS configurées avec leur catégorie et label de biais
RSS_SOURCES = [
    # ── POLITIQUE / ACTUALITÉS ──────────────────────────────
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
        "url": "https://www.humanite.fr/rss.xml",
        "source_name": "L'Humanité",
        "source_url": "humanite.fr",
        "category": "politique",
        "source_bias": "left"
    },
    {
        "url": "https://www.lefigaro.fr/rss/figaro_politique.xml",
        "source_name": "Le Figaro Politique",
        "source_url": "lefigaro.fr",
        "category": "politique",
        "source_bias": "right"
    },
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

    # ── SPORT ───────────────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/sport/rss.xml",
        "source_name": "BBC Sport",
        "source_url": "bbc.co.uk",
        "category": "sport",
        "source_bias": "center"
    },
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

    # ── BOURSE / FINANCE ────────────────────────────────────
    {
        "url": "https://feeds.bbci.co.uk/news/business/rss.xml",
        "source_name": "BBC Business",
        "source_url": "bbc.co.uk",
        "category": "bourse",
        "source_bias": "center"
    },
    {
        "url": "https://www.lesechos.fr/rss/rss_une.xml",
        "source_name": "Les Échos",
        "source_url": "lesechos.fr",
        "category": "bourse",
        "source_bias": "center-right"
    },
    {
        "url": "https://www.boursorama.com/rss/actualites",
        "source_name": "Boursorama",
        "source_url": "boursorama.com",
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

    # ── TECH ────────────────────────────────────────────────
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

    # ── ART / CULTURE ───────────────────────────────────────
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

    # ── SCIENCE ─────────────────────────────────────────────
    {
        "url": "https://www.futura-sciences.com/rss/actualites.rss",
        "source_name": "Futura Sciences",
        "source_url": "futura-sciences.com",
        "category": "science",
        "source_bias": "center"
    },
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
    # Scrape un flux RSS et insère les nouveaux articles en base
    inserted = 0
    seen_urls = set()  # 💡 Sécurité 1 : Évite de traiter deux fois la même URL dans la même boucle RSS

    try:
        # feedparser parse le flux RSS de façon synchrone
        # on l'exécute directement car il est rapide
        feed = feedparser.parse(source["url"])

        for entry in feed.entries[:20]:  # Max 20 articles par source
            title = entry.get("title", "").strip()
            url = entry.get("link", "").strip()

            # On vérifie aussi si l'URL est déjà dans seen_urls
            if not title or not url or url in seen_urls:
                continue

            # 💡 Sécurité 2 : LA MODIFICATION PRINCIPALE
            # On vérifie si l'URL existe déjà en base, peu importe si le titre a changé
            existing = await db.execute(
                select(Article).where(Article.url == url)
            )
            if existing.scalar_one_or_none():
                continue  # Article déjà en base → on l'ignore

            # On ajoute l'URL à notre set local pour ce batch
            seen_urls.add(url)

            # On génère le hash après la validation (ton modèle de données en a toujours besoin)
            url_hash = generate_hash(title, url)

            # Parse la date de publication si disponible
            published_at = None
            if hasattr(entry, "published_parsed") and entry.published_parsed:
                published_at = datetime(*entry.published_parsed[:6], tzinfo=timezone.utc)

            # Crée l'article
            article = Article(
                title=title,
                url=url,
                url_hash=url_hash,
                content=entry.get("summary", None),
                image_url=None,
                source_name=source["source_name"],
                source_url=source["source_url"],
                category=source["category"],
                source_bias=source["source_bias"],
                published_at=published_at,
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