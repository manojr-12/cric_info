# Cricinfo

Built a real-time cricket tracker that combines a Playwright + Node.js + Redis ingestion API with a SwiftUI macOS menu bar app, delivering live scores and milestone notifications right on desktop.

![Node.js](https://img.shields.io/badge/Node.js-20%2B-339933?logo=nodedotjs&logoColor=white) ![Express](https://img.shields.io/badge/Express-4.x-000000?logo=express&logoColor=white) ![Redis](https://img.shields.io/badge/Redis-DC382D?logo=redis&logoColor=white) ![Playwright](https://img.shields.io/badge/Playwright-2EAD33?logo=playwright&logoColor=white) ![SwiftUI](https://img.shields.io/badge/SwiftUI-0D96F6?logo=swift&logoColor=white) ![Xcode](https://img.shields.io/badge/Xcode-147EFB?logo=xcode&logoColor=white)

- `cricinfo-api/`: Node.js + Express + Playwright backend for live match ingestion and APIs.
- `cricinfo-widget/`: macOS menu bar app (SwiftUI) that consumes the API.

## Preview

![Cricinfo Widget Preview](cricinfo-widget/docs/images/widget-preview.png)

## Main Features

- Live score tracking in a macOS menu bar app.
- Match selection with persisted user preference.
- Automatic watcher warm-up from API when score cache is cold.
- Watchers auto-close when match is finished.

## Notifications

- Batter reaches 50.
- Batter reaches 100.
- Batter strike rate crosses above 200.
- Super over starts.
- 20+ runs scored in a completed over.
- Match over result.

## Project Structure

```text
.
├── cricinfo-api/
└── cricinfo-widget/
```

## Quick Start

### 1) Start API

```bash
cd cricinfo-api
npm install
npm start
```

### 2) Run Widget

Open the Xcode project:

- `cricinfo-widget/CricInfoWidget/CricInfoWidget.xcodeproj`

Set backend URL in widget code (if needed):

- `cricinfo-widget/CricInfoWidget/CricInfoWidget/APIService.swift`
