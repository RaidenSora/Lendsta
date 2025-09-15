<div align="center">

# Lendsta

Smart, simple loan tracking for individuals and small teams.

<br />

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-Android-6E40C9)
![State](https://img.shields.io/badge/Status-WIP-informational)

</div>

---

## Overview

Lendsta is a Flutter app that helps you record loans, track repayment status, and keep a tidy overview for each person. It stores data locally using SQLite via `sqflite` and aims to be fast, offline-first, and easy to use.

### Highlights
- Add loans with borrower, item, amount, interest, date, and optional photo attachment.
- Dashboard summary: total loans, total amount, average interest, paid count, and unpaid amount.
- Per-person summary with the same key metrics.
- Clean list and detail views with overflow-safe UI and ellipsized text.
- Export loans as CSV: copy, save to Downloads, or share.

## Screens

> Add screenshots to `docs/screens/` and update paths below.

| Dashboard | Add Loan | Person Details |
| --- | --- | --- |
| ![Dashboard](docs/screens/dashboard.png) | ![Add Loan](docs/screens/add-loan.png) | ![Person](docs/screens/person.png) |

## Getting Started

### Prerequisites
- Flutter 3.x
- Dart 3.x

### Setup
```bash
flutter pub get
flutter run
```

### Platforms
- Android only: run on a device or emulator.

## CSV Export & Share

- Where: On the Dashboard, tap the download icon in the top-right AppBar.
- Scope: Exports the currently selected range. If "All time" is enabled, exports all loans.
- Options in dialog:
  - Copy: Copies the CSV to the clipboard.
  - Save to Downloads: Writes `loans_export_YYYYMMDD_HHMMSS.csv` to the system Downloads folder.
  - Share: Opens the system share sheet and attaches the CSV file.

Android specifics
- Android 10+ (API 29+): Uses MediaStore to save into Downloads — no extra permissions.
- Android 6–9 (API 23–28): Saves to public Downloads and requires storage permission; the manifest entries are included.

CSV format
- Columns: `id, borrower, item, amount, interest, dueDate, status, imagePath`.
- Encoding: UTF-8. `dueDate` is ISO 8601.
- Escaping: Values with commas/quotes/newlines are quoted; quotes are doubled inside quoted fields.

## Project Structure

```
lib/
  app.dart                 # MaterialApp + theming
  main.dart                # Entry point
  data/loans_db.dart       # SQLite (sqflite) database + queries
  models/                  # Data models
  screens/                 # Pages (dashboard, people, person detail)
  sheets/                  # Bottom sheets (add loan, borrower picker)
  theme/                   # Light/dark theme
  utils/                   # Formatting helpers
  widgets/                 # Reusable UI components
```

## Data & Migrations

- Storage: `sqflite` (local SQLite database).
- Current schema version: 4.
- Migration v4 collapses statuses to two values: `paid` and `unpaid`. All legacy non-`paid` statuses are updated to `unpaid` automatically.
- Summaries compute unpaid amount dynamically (sum of amounts where status != `paid`).

## Development Notes

- UI is tuned to avoid overflow: long names and labels use `TextOverflow.ellipsis` and wrapping where appropriate.
- Attachments are stored as local file paths and shown inline in details.

## Acknowledgements

Built with Flutter and a lot of love for tidy UIs.
