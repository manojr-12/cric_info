# Cricinfo Workspace

- `cricinfo-api/`: Node.js + Express + Playwright backend for live match ingestion and APIs.
- `cricinfo-widget/`: macOS menu bar app (SwiftUI) that consumes the API.

## Recommended Layout

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

