# Cricinfo Live Match API

Redis-backed cricket score ingestion API using Express + Playwright.

## Architecture

The backend is split into three responsibilities:

- `api-service`: request handlers and route wiring (`src/api/`)
- `ingestion-orchestrator`: match refresh, watcher lifecycle, recovery, concurrency (`src/ingestion/ingestion.orchestrator.js`)
- `ingestion-worker`: Playwright browser lifecycle and per-match watcher contexts (`src/ingestion/ingestion.worker.js`)

State is persisted in Redis via repositories:

- `src/repositories/matches.repo.js`
- `src/repositories/scores.repo.js`
- `src/repositories/mapping.repo.js`

## Simple Project Layout

```text
.
├── src/
│   ├── api/
│   ├── config/
│   ├── ingestion/
│   ├── lib/
│   ├── repositories/
│   └── utils/
├── tests/
├── main.js
├── app.js
└── README.md
```

## Requirements

- Node.js 20+
- Redis
- Chrome available for Playwright `channel: 'chrome'`

## Setup

```bash
npm install
```

## Environment Variables

- `PORT` (default: `3000`)
- `REDIS_URL` (default: `redis://127.0.0.1:6379`)
- `WATCHER_MAX_CONCURRENCY` (default: `6`)
- `WATCHER_IDLE_TTL_SEC` (default: `900`)
- `MATCH_REFRESH_INTERVAL_SEC` (default: `3600`)
- `SCORE_TTL_SEC` (default: `1200`)

## Run

```bash
npm start
```

## Endpoints

- `GET /matches`
- `GET /matches/live`
- `GET /matches/score?matchId=<id>`
- `POST /matches/preference` body: `{ "matchId": "<id>" }`
- `GET /matches/watchers`
- `GET /health`

## Response Contracts

Error shape:

```json
{
  "error": {
    "code": "BAD_REQUEST",
    "message": "matchId required",
    "details": {}
  }
}
```

Score shape:

```json
{
  "matchId": "1527677",
  "source": "details",
  "updatedAt": "2026-04-11T10:00:00.000Z",
  "payload": {}
}
```

## Test

```bash
npm test
```
