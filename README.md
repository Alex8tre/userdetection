# User Activity Detection

Una app Flutter che integra il modello Google TensorFlow Lite pre-addestrato per il riconoscimento delle attività dell'utente.

## Caratteristiche

- **Classificazione attività in tempo reale** utilizzando sensori di movimento
- **5 tipi di attività supportate**:
  - Fermo
  - Camminando
  - Correndo
  - In Veicolo
  - In Bicicletta
- **Interfaccia utente intuitiva** con visualizzazione delle attività
- **Supporto multi-piattaforma** (Android e iOS)

## Modello TensorFlow Lite

Il progetto utilizza il modello Google pre-addestrato per Activity Recognition:
- **File**: `activity_classification.tflite`
- **Fonte**: Google TensorFlow Lite Task Library
- **Input**: finestra di 50 campioni con 6 feature (accelerometro XYZ + giroscopio XYZ)
- **Output**: classificazione tra 5 attività con confidenza

## Setup e Installazione

### Prerequisiti
- Flutter 3.0+
- Android Studio per sviluppo Android
- Xcode per sviluppo iOS (solo su macOS)

### Download del Modello
```bash
./download_model.sh
```

### Installazione Dipendenze
```bash
flutter pub get
```

### Build e Run
```bash
# Android
flutter run

# iOS
flutter run --device ios
```

## Architettura

### Flutter Layer
- `lib/main.dart`: UI principale e logica dell'app
- `lib/models/motion_state.dart`: modello dati per lo stato del movimento
- `lib/services/motion_detection_service.dart`: servizio bridge per le piattaforme native

### Android Layer
- `android/.../MainActivity.kt`: gestione method channel e permessi
- `android/.../MotionDetectionService.kt`: servizio di rilevamento movimento con TensorFlow Lite

### iOS Layer
- `ios/Runner/AppDelegate.swift`: gestione method channel
- `ios/Runner/MotionDetectionService.swift`: servizio Core Motion con TensorFlow Lite

## Specifiche Tecniche

### Input del Modello
- **Shape**: [1, 50, 6]
- **Frequenza campionamento**: 50Hz
- **Preprocessing**: normalizzazione [-1, 1]

### Output del Modello
- **Shape**: [1, 5]
- **Mapping classi**:
  - 0: Fermo
  - 1: Camminando
  - 2: Correndo
  - 3: In Veicolo
  - 4: In Bicicletta

## Permessi

### Android
- `android.permission.BODY_SENSORS`: richiesto per accesso ai sensori di movimento

### iOS
- `NSMotionUsageDescription`: spiegazione nell'Info.plist per l'uso dei sensori

## Note di Sviluppo

- Il modello richiede almeno 50 campioni (2 secondi a 50Hz) prima della prima classificazione
- I dati dei sensori vengono normalizzati per compatibilità con il modello Google
- L'app gestisce automaticamente i permessi e mostra lo stato di rilevamento