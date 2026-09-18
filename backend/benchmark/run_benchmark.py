"""
Benchmark comparatif de modèles LLM pour la génération de résumés.

Mesure sur un échantillon fixe d'articles :
- latence par appel
- taux de conformité au schéma Pydantic
- tokens consommés (estimation du coût)

Usage : docker exec -it informya_backend python -m benchmark.run_benchmark
"""

import asyncio
import time
import statistics
from dataclasses import dataclass, field

from sqlalchemy import select
from google import genai
from google.genai import types
from pydantic import ValidationError

from app.core.database import AsyncSessionLocal
from app.core.config import settings
from app.models.article import Article
from app.schemas.ai import ArticleSummary
from app.services.ai_service import clean_html, fetch_full_text

client = genai.Client(api_key=settings.GEMINI_API_KEY)

# Modèles à comparer — tous accessibles avec la même clé Gemini
MODELS = [
    "gemini-2.5-flash",       # celui utilisé en production
    "gemini-2.5-flash-lite",  # variante plus légère
    "gemini-3.5-flash",       # génération plus récente
    "gemini-3.5-flash-lite",  # version légère de la 3.5
]

SAMPLE_SIZE = 5


@dataclass
class ModelResult:
    """Résultats agrégés pour un modèle."""
    model: str
    latencies: list[float] = field(default_factory=list)
    valid_count: int = 0
    schema_errors: int = 0
    api_errors: int = 0
    input_tokens: int = 0
    output_tokens: int = 0

    @property
    def total_runs(self) -> int:
        return self.valid_count + self.schema_errors + self.api_errors

    @property
    def conformity_rate(self) -> float:
        if self.total_runs == 0:
            return 0.0
        return (self.valid_count / self.total_runs) * 100

    @property
    def avg_latency(self) -> float:
        return statistics.mean(self.latencies) if self.latencies else 0.0

    @property
    def median_latency(self) -> float:
        return statistics.median(self.latencies) if self.latencies else 0.0


def build_prompt(title: str, content: str) -> str:
    """Prompt identique à celui utilisé en production."""
    return f"""Voici un article de presse.

Titre: {title}
Contenu: {content}

Rédige 3 à 4 points clés factuels et concis.

Contraintes:
- Base-toi UNIQUEMENT sur le contenu fourni ci-dessus.
- Reformule entièrement avec tes propres mots, ne copie jamais de phrases du texte.
- Chaque point doit être une phrase complète.
- Indique "high" si le contenu source est riche, "medium" s'il est partiel, "low" s'il est très pauvre."""


def run_model(model: str, prompt: str, result: ModelResult) -> None:
    """Un appel au modèle, mesuré et catégorisé."""
    start = time.perf_counter()

    try:
        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=3000,
                response_mime_type="application/json",
                response_schema=ArticleSummary,
            ),
        )
        elapsed = time.perf_counter() - start
        result.latencies.append(elapsed)

        # Comptage des tokens si l'API le remonte
        if response.usage_metadata:
            result.input_tokens += response.usage_metadata.prompt_token_count or 0
            result.output_tokens += response.usage_metadata.candidates_token_count or 0

        if not response.text:
            result.schema_errors += 1
            print(f"    ⚠️  réponse vide")
            return

        try:
            ArticleSummary.model_validate_json(response.text)
            result.valid_count += 1
            print(f"    ✅ {elapsed:.2f}s")
        except ValidationError as e:
            result.schema_errors += 1
            print(f"    ⚠️  schéma invalide ({elapsed:.2f}s)")

    except Exception as e:
        result.api_errors += 1
        msg = str(e)[:80]
        print(f"    ❌ erreur API: {msg}")


async def fetch_sample() -> list[tuple[str, str]]:
    """Récupère un échantillon fixe d'articles avec leur contenu."""
    async with AsyncSessionLocal() as db:
        query = (
            select(Article)
            .where(Article.content.isnot(None))
            .order_by(Article.published_at.desc())
            .limit(SAMPLE_SIZE)
        )
        result = await db.execute(query)
        articles = list(result.scalars().all())

    sample = []
    for a in articles:
        # Même logique qu'en production : texte complet si dispo, sinon RSS
        full_text = fetch_full_text(a.url)
        if full_text and len(full_text.strip()) > 300:
            content = full_text
        else:
            content = clean_html(a.content or "")

        if content.strip():
            sample.append((a.title, content[:4000]))

    return sample


def print_report(results: list[ModelResult], sample_size: int) -> None:
    """Affiche le tableau markdown prêt à coller dans le README."""
    print("\n" + "=" * 70)
    print(f"RÉSULTATS — {sample_size} articles par modèle")
    print("=" * 70 + "\n")

    print("| Modèle | Latence moy. | Latence méd. | Conformité | Erreurs API | Tokens in/out |")
    print("|---|---|---|---|---|---|")

    for r in results:
        print(
            f"| `{r.model}` "
            f"| {r.avg_latency:.2f}s "
            f"| {r.median_latency:.2f}s "
            f"| {r.conformity_rate:.0f}% "
            f"| {r.api_errors} "
            f"| {r.input_tokens} / {r.output_tokens} |"
        )

    print()

    # Recommandation automatique sur les modèles exploitables
    usable = [r for r in results if r.conformity_rate >= 80 and r.api_errors == 0]
    if usable:
        fastest = min(usable, key=lambda r: r.avg_latency)
        print(f"→ Plus rapide parmi les modèles fiables : {fastest.model}")
    else:
        print("→ Aucun modèle n'atteint 80% de conformité sans erreur API")


async def main():
    print(f"Récupération de {SAMPLE_SIZE} articles...")
    sample = await fetch_sample()

    if not sample:
        print("❌ Aucun article exploitable en base")
        return

    print(f"✅ {len(sample)} articles récupérés\n")

    results = []

    for model in MODELS:
        print(f"── {model} " + "─" * (50 - len(model)))
        result = ModelResult(model=model)

        for i, (title, content) in enumerate(sample, 1):
            print(f"  [{i}/{len(sample)}] {title[:50]}...")
            prompt = build_prompt(title, content)
            run_model(model, prompt, result)
            time.sleep(1)  # Espace les appels pour ménager le quota

        results.append(result)
        print()

    print_report(results, len(sample))


if __name__ == "__main__":
    asyncio.run(main())