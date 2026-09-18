# Informya 📰

> A personalized mobile news aggregation app with a lightweight AI layer to enhance the reading experience.

---

## Overview

Informya is an iOS and Android mobile application that aggregates news from around the world — politics, sports, finance, tech, art and science — and personalizes it based on each user's interests.

The goal is simple: stay informed daily in a smart way, without bias, without duplicates, and without getting lost in an endless chronological feed.

---

## Features

### Personalized Feed

- Never see the same article twice (read history tracking)
- Favorite sources with a dedicated tab
- Multi-criteria filtering: category, content type, reading time, source bias
- Real reading time computed from full article text
- Infinite scroll with pagination

### Anti-Bias Approach

- Sources labeled by political lean (left / center-left / center / center-right / right)
- Bias indicator visible on every article card
- Geographic and editorial diversity across 30 RSS sources (FR + international)

### AI Summaries (Gemini)

- On-demand article summaries — never generated upfront
- Three reading styles: bullet points, journalistic, simplified
- Structured output validated by a Pydantic schema — malformed responses never reach the database
- Two-level cache (Redis L1 / PostgreSQL L2) to minimize API calls
- Original articles always preserved — AI assists reading, never replaces it

### Bookmarks & Sharing

- Bookmark from the article screen
- Native share sheet (WhatsApp, Mail, SMS) from article view or long-press on a card
- Dedicated bookmarks screen

### Personalization

- Light / dark / system theme
- Customizable AI reading style
- Invite code to share with family and friends

---

## Tech Stack

| Layer          | Technology                                  |
| -------------- | ------------------------------------------- |
| Mobile         | Flutter / Dart                              |
| Backend        | FastAPI — Python 3.13                       |
| Database       | PostgreSQL 17 + Alembic migrations          |
| Cache          | Redis 8                                     |
| AI             | Gemini API (Google) with structured outputs |
| Scraping       | feedparser + trafilatura                    |
| Testing        | pytest + pytest-asyncio (33 tests)          |
| Infrastructure | Docker + docker-compose                     |
| Deployment     | Railway (planned)                           |

---

## Architecture

```
Informya/
├── backend/                     # FastAPI — Python
│   ├── app/
│   │   ├── routers/             # auth, feed, articles, users
│   │   ├── models/              # SQLAlchemy — User, Article, Bookmark, UserSource
│   │   ├── schemas/             # Pydantic — request/response + AI output validation
│   │   ├── services/            # scraper, ai_service, cache_service
│   │   ├── core/                # config, database, security, exceptions, limiter
│   │   └── utils/               # text helpers
│   ├── alembic/                 # database migrations
│   ├── benchmark/               # LLM model comparison scripts
│   ├── tests/                   # pytest suite
│   └── requirements.txt
│
├── mobile/                      # Flutter
│   └── lib/
│       ├── screens/             # feed, article, bookmarks, profile, login
│       ├── services/            # API client
│       ├── theme/               # adaptive color system
│       └── widgets/             # reusable components
│
├── docker-compose.yml
└── .env.example
```

## Database

6 PostgreSQL tables:

- `users` — profiles, invite codes, reading style preference
- `articles` — content, SHA-256 hash (deduplication), bias label, cached AI summaries per style, reading time, content type
- `read_history` — reading history, excludes already-read articles from the feed
- `bookmarks` — personal bookmarks
- `user_sources` — favorite sources per user
- `shared_articles` — internal sharing (planned)

---

## AI Integration

### Resilience Strategy

The Gemini integration distinguishes error types and adapts its retry and cache behaviour accordingly:

| Situation                         | Retry                         | Cache TTL |
| --------------------------------- | ----------------------------- | --------- |
| Quota exceeded (429)              | No                            | 5 min     |
| Content blocked by safety filters | No                            | 24 h      |
| Insufficient source content       | No                            | 1 h       |
| Schema validation failure         | Yes (3×)                      | 60 s      |
| Transient network error           | Yes (3×, exponential backoff) | 10 s      |

### Structured Outputs

Summaries are returned as validated JSON rather than free text:

```python
class ArticleSummary(BaseModel):
    key_points: list[str] = Field(min_length=2, max_length=5)
    confidence: Literal["high", "medium", "low"]
```

Any response that fails validation raises a typed exception and never reaches the database.

### Model Selection

Four Gemini variants were benchmarked on a fixed sample of 5 articles, measuring latency, schema conformity and token usage.

| Model                   | Avg latency | Conformity | Tokens (in/out) |
| ----------------------- | ----------- | ---------- | --------------- |
| `gemini-2.5-flash`      | 4.48s       | 100%       | 3431 / 691      |
| `gemini-3.5-flash`      | 10.86s      | 100%       | 3431 / 661      |
| `gemini-3.5-flash-lite` | 1.20s       | 100%       | 3431 / 543      |
| `gemini-2.5-flash-lite` | n/a         | 0% (404)   | n/a             |

`gemini-3.5-flash-lite` was 3.7× faster but failed a qualitative check — it strips French accents entirely and produces vaguer summaries with fewer concrete figures. `gemini-3.5-flash` proved too slow for an interactive, on-demand feature.

**Selected: `gemini-2.5-flash`** — best balance of latency, factual accuracy and French language handling.

Benchmark scripts live in `backend/benchmark/`.

---

## Security

- JWT authentication with bcrypt password hashing
- Password strength validation (length, digit, uppercase, lowercase, special character)
- Rate limiting via slowapi (5/min on register, 10/min on login)
- Security headers (X-Content-Type-Options, X-Frame-Options, HSTS, X-XSS-Protection)
- Request size limit (1 MB)
- Security logging on failed auth attempts
- SQL injection protection through SQLAlchemy parameterized queries

---

## Development Environment

The project runs in Docker (PostgreSQL, Redis, FastAPI) with the Flutter app
targeting the Android emulator or iOS simulator. The API base URL is detected
automatically per platform.

Database schema changes are handled through Alembic migrations. The test suite
runs with pytest against an isolated in-memory SQLite database with mocked Redis.

---

## API Routes

### Auth

| Method | Route            | Description             |
| ------ | ---------------- | ----------------------- |
| POST   | `/auth/register` | Create an account       |
| POST   | `/auth/login`    | Sign in — returns a JWT |
| GET    | `/auth/me`       | Current user profile 🔒 |

### Feed

| Method | Route   | Description                       |
| ------ | ------- | --------------------------------- |
| GET    | `/feed` | Personalized feed with filters 🔒 |

Query parameters: `page`, `limit`, `category`, `content_type`, `max_reading_time`, `source_bias`, `favorites_only`

### Articles

| Method | Route                    | Description            |
| ------ | ------------------------ | ---------------------- |
| GET    | `/articles/{id}`         | Article detail 🔒      |
| GET    | `/articles/{id}/summary` | AI summary (cached) 🔒 |
| POST   | `/articles/{id}/read`    | Mark as read 🔒        |

### Users

| Method          | Route              | Description                |
| --------------- | ------------------ | -------------------------- |
| GET/POST/DELETE | `/users/bookmarks` | Manage bookmarks 🔒        |
| GET/POST/DELETE | `/users/sources`   | Manage favorite sources 🔒 |
| PATCH           | `/users/me`        | Update reading style 🔒    |

---

## Roadmap

**Done**

- [x] Docker infrastructure (PostgreSQL, Redis, FastAPI)
- [x] JWT authentication with rate limiting and security headers
- [x] RSS scraper — 30 sources, URL-based deduplication, 30 min interval
- [x] Feed with multi-criteria filtering and pagination
- [x] Bookmarks and favorite sources
- [x] Gemini AI summaries with structured outputs and two-level cache
- [x] Typed exception hierarchy with adaptive retry strategies
- [x] pytest suite — 33 tests
- [x] LLM model benchmark
- [x] Flutter app — feed, article, bookmarks, profile, light/dark theme
- [x] Native article sharing

**Next**

- [ ] CI/CD with GitHub Actions
- [ ] Password reset (requires email service)
- [ ] Railway deployment
- [ ] Push notifications for favorite sources
- [ ] Rewrite RSS scraper in Rust
- [ ] Google / Apple Sign-In

---

## Git Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: new feature
fix: bug fix
chore: config, tooling
docs: documentation
test: tests
refactor: rewrite without behavior change
```

---

## License

All rights reserved. This code is published for portfolio purposes only.
No permission is granted to use, copy, modify or distribute it.
