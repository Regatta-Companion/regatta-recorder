# Regatta Recorder

Minimalistische regatta track recorder app — een uitgeklede versie van [Regatta Screen](https://github.com/FutureCow/regatta-screen).

**Platforms:** Android + iOS

## Features

- ⏱️ **Afteltimer** — 5/10/15 minuten (of uit te zetten) — telt af naar de start, daarna oplopend
- 📍 **GPS Recorder** — neemt GPX track op met één druk op de knop
- ☁️ **Auto-upload** — track wordt direct geüpload naar regatta.fhettinga.nl en gekoppeld aan de juiste wedstrijd/klasse via deelnamecode
- ⛵ **Boot profiel** — boottype, bootnaam, teamnaam (optioneel, lokaal + server)

## Setup

```bash
flutter pub get
flutter run
```

## Structuur

```
lib/
├── main.dart                 # App entry + wakelock
├── models/
│   ├── app_settings.dart     # Instellingen model
│   ├── recorder_state.dart   # Recorder state
│   └── timer_state.dart      # Timer state
├── services/
│   ├── api_service.dart      # REST API (auth, upload, join)
│   ├── gps_service.dart      # GPS stream via geolocator
│   ├── track_recorder.dart   # GPX opname + schrijven
│   └── settings_service.dart # SharedPreferences persistence
├── providers/
│   ├── settings_provider.dart # Settings + auth state
│   ├── timer_provider.dart    # Timer logic
│   └── recorder_provider.dart # Recorder + upload flow
├── screens/
│   ├── home_screen.dart      # Timer + recorder UI
│   ├── settings_screen.dart  # Instellingen
│   └── login_screen.dart     # Inloggen / registreren
└── theme/
    └── app_theme.dart        # Nautisch donker thema
```

## Server

Gebruikt dezelfde [regatta-server](https://github.com/FutureCow/regatta-server) API als regatta-screen.
