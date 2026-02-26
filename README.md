# Face Recognition with Flutter

A mobile face recognition application built with Flutter. Detects faces in real-time using Google ML Kit, generates face embeddings with a MobileFaceNet TFLite model, and matches them against locally stored faces using Euclidean distance.

## Features

- **Live Camera Recognition** — Real-time face detection and recognition via device camera
- **Photo Recognition** — Recognize faces from gallery or camera photos
- **Face Registration** — Register new faces with a name and ID number
- **Local Storage** — All face data stored on-device with SQLite (no cloud, no Firebase)
- **No Internet Required** — Fully offline after installation

## Demo

> [YouTube Demo](https://youtu.be/nXBaHoPbRE4?si=ZekyMhHYScC7drsb)

## How It Works

```
Camera Frame
    ↓
Google ML Kit Face Detection  →  Bounding Box
    ↓
Image Crop + Normalize (112×112 RGB)
    ↓
MobileFaceNet TFLite Model  →  192-dim Embedding
    ↓
Euclidean Distance vs Registered Faces
    ↓
Match (threshold < 1.25)  →  Name / "Unknown"
```

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `google_mlkit_face_detection` | ^0.13.1 | Face detection & bounding boxes |
| `tflite_flutter` | ^0.12.1 | On-device ML inference (MobileFaceNet) |
| `camera` | ^0.11.3 | Live camera stream |
| `image_picker` | ^1.2.1 | Gallery / camera photo selection |
| `image` | ^4.6.0 | Image processing & cropping |
| `sqflite` | ^2.3.0 | Local SQLite face storage |
| `path_provider` | ^2.1.1 | App documents directory |
| `lottie` | ^3.3.2 | Animations |

**Model:** `mobilefacenet.tflite` — Input: `[1, 112, 112, 3]` float32 normalized to `[-1, 1]` — Output: `[1, 192]` embedding vector

## Getting Started

### Prerequisites

- Flutter SDK `>=3.1.0`
- Android device/emulator (API 21+)
- Camera permission

### Setup

```bash
git clone https://github.com/kuru0777/face-recognition-with-flutter.git
cd face-recognition-with-flutter
flutter pub get
flutter run
```

### Usage

1. **Register a face** — Tap "Register Face" → pick a photo → fill in name & ID → save
2. **Recognize from photo** — Tap "Recognize Face" → pick a photo → bounding box with name appears
3. **Live recognition** — Tap the live camera button on the recognition screen → point camera at a registered face

## Project Structure

```
lib/
├── main.dart
├── Model/
│   ├── db.dart               # SQLite singleton (DatabaseHelper)
│   └── student_model.dart    # Face data model
├── ViewModel/
│   ├── face_match.dart       # Recognizer: TFLite inference + matching
│   └── face_register.dart    # Recognition result model
└── View/
    ├── home_view.dart
    ├── face_register_view.dart
    ├── face_match_view.dart
    ├── facedetector.dart          # Live camera recognition
    ├── live_camera.dart           # Camera stream controller
    ├── detector_view.dart
    ├── facedetectorpainter.dart
    ├── coordinates.dart
    └── constants/
        └── painter.dart
```

## Notes

- Face embeddings stored as comma-separated values in SQLite
- Recognition threshold: `1.25` Euclidean distance (lower = stricter matching)
- Live camera uses `IsolateInterpreter` to keep TFLite inference off the UI thread
- NV21 camera frames converted to RGB before inference on Android

## License

MIT
