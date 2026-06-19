# OrchardEye — iOS app (SwiftUI)

The v1 OrchardEye app: a dual-sensor crop **disease + quality** scanner that runs the full
pipeline from [`docs/design/ai-pipeline.md`](../docs/design/ai-pipeline.md) on-device —
capture → quality gate → disease & crop-health → NIR ripeness/Brix → **fused verdict** →
voice + trends + community confirm/correct.

## Requirements
- **Xcode 16 or newer** (the project uses file-system–synchronized groups, `objectVersion 77`).
- iOS **17+** Simulator or device.
- No packages, pods, or other tooling — it builds with only Apple frameworks
  (SwiftUI, Swift Charts, AVFoundation, PhotosUI, Vision/UIKit).

## Build & run
```bash
open OrchardEye/OrchardEye.xcodeproj
```
1. Select the **OrchardEye** scheme and an iPhone Simulator (e.g. iPhone 15).
2. Press **⌘R**.
3. On a device, set your Team under *Signing & Capabilities* first (Simulator needs no signing).

### Try the full flow in the Simulator (no hardware needed)
The Simulator has no camera and you have no clip-on sensor yet, so:
- On the **Scan** tab tap **“Sample: healthy”** or **“Sample: diseased”** (a leaf image is
  generated and really analyzed), **or** **“Choose photo”** to pick from the library.
- Tap **Scan fruit** on the NIR step — the spectrum is **simulated**.
- You’ll get a fused verdict you can **hear** (on-device TTS), **save**, and **confirm/correct**.
- Scan the same **plant/block label** more than once to populate the **Trends** charts.

## What's real vs. stubbed (by design)
| Part | Status |
|---|---|
| Full UI/UX, navigation, onboarding, history, CSV export | ✅ real |
| Image **quality gate** (blur/exposure/subject) | ✅ real, on-device |
| **Crop-health** signals (greenness/lesion/chlorosis) | ✅ real image analysis |
| **Disease classification** | 🟡 placeholder driven by real image stats — drop a Core ML model into `DiseaseClassifier` |
| **NIR spectrum / ripeness / Brix** | 🟡 simulated — `SpectralSensor` is the CoreBluetooth seam for a real AS7265x |
| **Fusion, trends, risk/urgency** | ✅ real logic |
| **Voice guidance** (weather-adaptive) | ✅ real `AVSpeechSynthesizer` |
| **Weather** | ✅ real Open-Meteo fetch, offline fallback + cache |

> Honesty note: spectral claims stay within **410–940 nm** (what the AS7265x can really do).
> The disease model here is a stand-in so the app is fully demoable — it is **not** a trained
> classifier yet.

## Project layout
```
OrchardEye/
├─ OrchardEye.xcodeproj/         # hand-authored, Xcode-16 synchronized-group project
└─ OrchardEye/
   ├─ OrchardEyeApp.swift        # @main
   ├─ Models/CoreModels.swift    # Crop, Variety, DiseaseInfo, CropHealth, SpectralReading, Verdict, ScanRecord …
   ├─ Services/                  # ImageAnalysis, QualityGate, DiseaseClassifier, SpectralSensor,
   │                             #   FusionEngine, TrendAnalyzer, WeatherProvider, VoiceGuide, AppModel/ScanStore
   ├─ Views/                     # RootView, Onboarding, ScanFlow, Verdict, History, Trends, Settings, Components
   └─ Assets.xcassets/
```

## Where to plug in the real models (the two seams)
- **Disease CV:** implement `DiseaseClassifier` with a `VNCoreMLModel` (export your INT8
  MobileNet/EfficientNet-Lite to Core ML) and inject it in `AppModel` instead of
  `MockDiseaseClassifier`.
- **Spectral sensor:** implement `SpectralSensor` over **CoreBluetooth** to read the AS7265x’s
  18 channels, and inject it instead of `SimulatedSpectralSensor`. `QualityModel` already maps
  channels → ripeness/Brix and is ready for your per-variety calibration.
