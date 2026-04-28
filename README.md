# EcoXP
> Sustainability learning game with GPS campus exploration, plant recognition, SDG mini games, and XP-based ranking.

[![Flutter](https://img.shields.io/badge/Flutter-3.2%2B-02569B.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28.svg)](https://firebase.google.com/)
[![Flame](https://img.shields.io/badge/Flame-Game%20Engine-orange.svg)](https://flame-engine.org/)
[![Python](https://img.shields.io/badge/Python-Plant%20Recognition-3776AB.svg)](https://www.python.org/)

EcoXP combines GPS-based campus gameplay, plant scanning, and sustainability challenges into a single Flutter app.

## 6 Core Modules

| Module | Purpose |
|--------|---------|
| **Campus Exploration** | GPS-driven map and location-based gameplay |
| **Plant Recognition** | Camera scan flow powered by PlantNet-based recognition |
| **Mini Games** | `Light Saver`, `Crush the Plastic`, and `Guardian of the Forest` |
| **3D Campus Simulation** | MapLibre GL and Three.js web simulation in `web_assets/send2/` |
| **SDG Progress** | Daily SDG quiz, SDG badges, and sustainability tasks |
| **Campus Ranking** | XP-based leaderboard with player ranks |

## Project Structure

```
frontend/
├── lib/
│   ├── screens/          # Map, scanner, leaderboard, mini games, SDG views
│   ├── mini_games/       # Light Saver, Crush the Plastic, Guardian of the Forest
│   ├── services/        # Firebase, geolocation, connectivity, API services
│   └── my_game.dart     # App providers and bootstrap
├── assets/              # Images, audio, translations, game art
└── android/ios/web/...  # Platform targets

backend/
├── plant_recognition/   # PlantNet recognition service and helpers
└── campus_sustainability/ # Supporting campus backend resources

web_assets/
└── send2/               # 3D campus simulation frontend

run_geocampus.bat        # Starts the local backend services
```

## Quick Start

**Prerequisites**: Flutter SDK `>=3.2.5 <4.0.0`

```bash
cd frontend
flutter pub get
flutter run
```

To start the local backend services:

```bash
run_geocampus.bat
```

## Technical Notes

- Uses `geolocator` for live GPS location tracking.
- Uses Firebase for Auth, Firestore, and Messaging.
- Push notifications subscribe to the `motherEarth` topic.
- The app runs in portrait mode and hides the system UI.
- Plant recognition runs through the Python service in `backend/plant_recognition/` on port `8888`.
- The 3D campus simulation runs from `web_assets/send2/` on port `8080`.

# EcoXP

EcoXP is a Flutter-based educational game about sustainability, built with a Firebase backend and a small Python service for plant recognition.

## What It Does

- Uses GPS to place gameplay and plant-related events around the player.
- Tracks player location with `geolocator` and updates map-based features in real time.
- Lets players scan plants with the camera and sends the image to PlantNet-based recognition.
- Stores scan results with the detected plant name, confidence score, and GPS position.
- Uses the scan result to drive rewards, discovery progress, and map interactions.
- Includes three mini games: `Light Saver`, `Crush the Plastic`, and `Guardian of the Forest`.
- The mini games run as separate game modes, and the main action game switches to landscape for gameplay.
- Includes a 3D campus simulation in `web_assets/send2/` built with MapLibre GL and Three.js.
- The simulation shows a live GPS-driven avatar, plant cards, a camera scanner, a herbarium, and quest/progress panels.
- Includes SDG-themed gameplay, including a daily SDG quiz and SDG level badges.
- Campus ranking is based on XP, with a leaderboard that shows the top players and their rank.

## Tech Stack

- Flutter app in `frontend/`
- Firebase: Auth, Firestore, and Messaging
- Localization with `easy_localization` (`en_US` and `ja_JP`)
- 2D game framework: `flame` / `flame_tiled`
- Python plant-recognition server in `backend/plant_recognition/`
- XP and rankings are tracked through Firebase-backed leaderboard data

## Key Runtime Details

- Flutter SDK: `>=3.2.5 <4.0.0`
- App starts in portrait only and hides the system UI
- Push notifications subscribe to the `motherEarth` topic
- If internet is unavailable, the app shows an offline screen
- Plant recognition API runs on port `8888`
- Web assets map/simulation server runs on port `8080`
- Plant recognition is handled by the Python service in `backend/plant_recognition/`
- `web_assets/send2/` contains the 3D map/simulation frontend and its assets

## Run

1. Start the backend services:

   `run_geocampus.bat`

2. Start the Flutter app:

   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```

## Project Layout

- `frontend/` - main Flutter app
- `backend/` - Python services and supporting code
- `web_assets/` - hosted web assets used by the project
- `run_geocampus.bat` - launches the local backend services
