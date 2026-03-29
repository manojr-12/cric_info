# Cricinfo Live Match API

A Node.js service that tracks live cricket matches from ESPN Cricinfo by intercepting network responses using Playwright. It provides real-time score updates and structured match data through REST APIs.

## Features

* Fetches live matches from Cricinfo
* Tracks selected matches based on user preference
* Captures real-time updates via:

  * `/fastscore/message/base` (ball-by-ball updates)
  * `/v1/pages/match/details` (structured match data)
* Exposes APIs to:

  * list matches
  * set match preference
  * fetch live scores
* Uses Playwright to simulate browser behavior and capture API responses

## Tech Stack

* Node.js
* Express
* Playwright

## Project Structure

```
.
├── controllers/
│   └── matches.controller.js
├── routes/
│   └── matches.routes.js
├── services/
│   └── browser.service.js
├── app.js
├── package.json
└── README.md
```

## Setup

### 1. Clone the repository

```
git clone https://github.com/manojr-12/cric_info.git
cd cric_info
```

### 2. Install dependencies

```
npm install
```

### 3. Install Playwright browsers

```
npx playwright install
```

### 4. Run the server

```
node app.js
```

Server will start at:

```
http://localhost:3000
```

## API Endpoints

### 1. Get all matches

```
GET /matches
```

Returns list of current matches.

---

### 2. Get live matches

```
GET /matches/live
```

Returns only live matches.

---

### 3. Set preferred match

```
POST /matches/preference
Content-Type: application/json

{
  "matchId": "123456"
}
```

* Stores the preferred match
* Opens match page in Playwright
* Starts listening to live APIs

---

### 4. Get score for a match

```
GET /score?matchId=123456
```

Returns:

```
{
  "fastscore": { ... },
  "details": { ... }
}
```

## How It Works

1. Playwright launches a Chromium browser.
2. The app navigates to Cricinfo live match pages.
3. Network responses are intercepted:

   * Fastscore API provides real-time ball updates
   * Match details API provides structured match data
4. Data is stored in memory and served via REST endpoints.

## Notes

* The Cricinfo API uses short-lived authentication tokens.
* Playwright handles these automatically through browser session.
* Only selected matches are tracked to reduce resource usage.

## Limitations

* Uses in-memory storage (data resets on restart)
* Single instance may not scale for many matches
* Dependent on Cricinfo frontend API structure

## Future Improvements

* WebSocket support for real-time push updates
* Persistent storage (Redis or database)
* Multi-match tracking with isolated browser contexts
* Direct API integration without Playwright

## License

MIT
