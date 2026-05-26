# Informya 📰

> A personalized mobile news aggregation app with a lightweight AI layer to enhance the reading experience.

---

## Overview

Informya is an iOS and Android mobile application that aggregates news from around the world — politics, sports, finance, art and culture — and personalizes it based on each user's interests.

The goal is simple: stay informed daily in a smart way, without bias, without duplicates, and without getting lost in an endless chronological feed.

---

## Features

### Personalized Feed
- Relevance scoring per user profile
- Smart sorting based on reading history
- Never see the same article twice
- Categories: politics, sports, finance, art, culture, tech

### Anti-Bias Algorithm
- Sources labeled by political lean (left / center / right)
- Forced balanced mix per topic
- Subtle bias indicator on each source
- Geographic diversity (FR, UK, US, etc.)

### Lightweight AI (Claude API)
- 2-line teaser per article to help you decide whether to read it
- "Explain" button for complex terms inside articles
- "Compare sources" button on the same topic
- Original articles are always preserved — AI is a reading assistant, never a writer

### Bookmarks & Sharing
- Bookmark directly from the article card
- Optional personal note on each bookmark
- Internal sharing between Informya users
- External sharing via native iOS/Android share sheet (WhatsApp, Mail, SMS, etc.)

### Multi-User
- Invite system via link (family, friends)
- Independent profile per user
- Customizable reading style (bullet points, journalistic, simplified)
- Shared articles visible in a dedicated screen

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | React Native + TypeScript (Expo) |
| Backend | FastAPI — Python |
| Scraper | Rust (phase 2) |
| Database | PostgreSQL |
| Cache | Redis |
| AI | Claude API (Anthropic) |
| Infrastructure | Docker + docker-compose |
| Admin Dashboard | Vue.js (phase 3) |
| Deployment | Railway (backend) + Vercel (dashboard) |

---

## Architecture

```
Informya/
├── backend/                  # FastAPI — Python
│   ├── app/
│   │   ├── routers/          # auth, feed, articles, users
│   │   ├── models/           # SQLAlchemy — User, Article, Bookmark, SharedArticle
│   │   ├── schemas/          # Pydantic — data validation
│   │   ├── services/         # scraper, scoring, AI
│   │   └── core/             # config, database, security, dependencies
│   ├── Dockerfile
│   └── requirements.txt
│
├── mobile/                   # React Native + TypeScript
│   └── src/
│       ├── screens/          # Feed, Article, Profile, Bookmarks
│       ├── components/       # Cards, AI overlay, Share sheet
│       ├── store/            # State management
│       └── api/              # FastAPI calls
│
├── scraper/                  # Rust — phase 2
├── dashboard/                # Vue.js — phase 3
├── docker-compose.yml
└── .env.example
```

---

## Database

5 PostgreSQL tables:

- `users` — profiles, interest scores, invite codes, reading style
- `articles` — original content, SHA-256 hash (deduplication), bias label, AI teaser
- `read_history` — reading history + duration → feeds the personalization scoring
- `bookmarks` — personal bookmarks with optional note
- `shared_articles` — internal sharing between users with optional message

---

## Getting Started

### Prerequisites
- Docker Desktop
- Node.js 20+ (nvm recommended)
- Expo Go on iPhone/Android (for mobile testing)

### Installation

```bash
# 1. Clone the repo
git clone https://github.com/Vince-lgd/Informya.git
cd Informya

# 2. Create the environment file
cp .env.example .env
# Fill SECRET_KEY with: openssl rand -hex 32

# 3. Start everything
docker compose up --build
```

### Available URLs

| Service | URL |
|---|---|
| FastAPI | http://localhost:8000 |
| Swagger Docs | http://localhost:8000/docs |
| PgAdmin | http://localhost:5050 |

### PgAdmin Credentials

```
Email    : admin@informya.com
Password : admin

PostgreSQL Server:
  Host     : db
  Port     : 5432
  Database : informya
  Username : informya
  Password : password
```

### Environment Variables

```env
DATABASE_URL=postgresql+asyncpg://informya:password@db:5432/informya
REDIS_URL=redis://redis:6379
SECRET_KEY=                  # openssl rand -hex 32
ANTHROPIC_API_KEY=           # Claude API
NEWS_API_KEY=                # NewsAPI
ALPHA_VANTAGE_KEY=           # Stock market
```

---

## API Routes

### Auth
| Method | Route | Description |
|---|---|---|
| POST | `/auth/register` | Create an account |
| POST | `/auth/login` | Sign in — returns a JWT token |
| GET | `/auth/me` | Current user profile 🔒 |

### Health
| Method | Route | Description |
|---|---|---|
| GET | `/health` | Check server status |

---

## Roadmap

**Phase 1 — MVP** *(in progress)*
- [x] Docker infrastructure + PostgreSQL + Redis
- [x] JWT Auth (register, login)
- [ ] Feed + articles routes
- [ ] Python RSS scraper
- [ ] React Native — first screens

**Phase 2 — Personalization**
- [ ] Relevance scoring per user profile
- [ ] Claude API integration (teaser, explanation)
- [ ] Rewrite scraper in Rust
- [ ] Invite system
- [ ] Push notifications

**Phase 3 — Dashboard**
- [ ] Vue.js admin dashboard
- [ ] Source management
- [ ] Reading stats
- [ ] Railway + Vercel deployment

---

## Git Conventions

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: new feature
fix: bug fix
chore: config, tooling
docs: documentation
refactor: rewrite without behavior change
```

---

## License

Personal project — all rights reserved.