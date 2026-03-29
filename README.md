# Marketplace Frontend (Flutter-only)

Flutter client for the marketplace backend.

## Platforms
- Android
- iOS
- Web (Flutter Web)

## Requirements
- Flutter 3.x / Dart 3.x
- Running backend API (FastAPI)

## Configure API URL
Use `API_BASE_URL` define (preferred). **Android emulator** (default in `Env` is the same host):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Backward-compatible define is also supported:

```bash
flutter run --dart-define=VITE_API_URL=http://10.0.2.2:8000
```

iOS simulator / desktop / browser on the same PC, if needed:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Run

```bash
flutter pub get
flutter run
```

## Build Web

```bash
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Project Structure
- `lib/core` - config, network, routing
- `lib/features` - app features (home, posting, profile, chats, auth, etc.)
- `lib/shared` - shared widgets, theme, localization, category catalog

## Notes
- Category mapping for Home/Profile/Posting is centralized in `lib/shared/data/category_catalog.dart`.
- Legacy React/Vite frontend was removed from this repository.
