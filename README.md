# Plant Doctor - AI-Powered Plant Disease Detection

An offline-capable Flutter application that uses Google's Gemma 3n models to identify plant diseases and provide farming advice.

## Features

- 🌿 **Plant Disease Detection**: Take or upload photos of plants to identify diseases
- 🤖 **Offline AI**: Runs Gemma 3n models locally on device
- 💬 **Agricultural Chat**: Ask questions about farming, plant care, and treatments
- 🔬 **Disease Analysis**: Get detailed analysis including severity and remedies
- 📱 **Cross-Platform**: Works on Android and iOS
- 🚀 **Fast Inference**: GPU-accelerated model execution

## Technologies

- Flutter 3.8+
- flutter_gemma package for AI integration
- Gemma 3n E2B/E4B vision models
- Provider for state management
- Material You (Material 3) design

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd plant_doctor
   ```

2. **Configure Hugging Face Token**
   - Copy `lib/config/env_config.dart.example` to `lib/config/env_config.dart`
   - Add your Hugging Face token (get one from https://huggingface.co/settings/tokens)
   - This token will be embedded in the app so users won't need to enter it

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

5. **Download a model**
   - Launch the app
   - Tap the download icon in the app bar
   - Select Gemma 3n E2B (recommended) or E4B model
   - Wait for download to complete (~1.5GB)

## Usage

1. **Analyze Plant Photos**
   - Tap the camera icon
   - Take a photo or select from gallery
   - AI will analyze for diseases and provide recommendations

2. **Ask Questions**
   - Type farming-related questions in the chat
   - Get advice on plant care, treatments, and prevention

3. **View Analysis**
   - Disease identification with confidence scores
   - Severity assessment
   - Recommended treatments (organic and chemical)
   - Preventive measures

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/               # Data models
│   ├── chat_message.dart
│   └── plant_disease.dart
├── services/             # Business logic
│   ├── ai_service.dart
│   └── model_download_service.dart
├── providers/            # State management
│   └── app_provider.dart
├── screens/              # UI screens
│   └── home_screen.dart
└── widgets/              # Reusable widgets
    ├── chat_widget.dart
    └── model_selector_widget.dart
```

## Platform Setup

### Android
- Minimum SDK: 26 (Android 8.0)
- Permissions: Camera, Storage

### iOS
- Minimum iOS: 12.0
- Info.plist permissions:
  - NSCameraUsageDescription
  - NSPhotoLibraryUsageDescription

## Building Release APK

To build a release APK for Android, you need to set up code signing:

1. **Generate a keystore** (if you don't have one):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Place the generated `upload-keystore.jks` file in `android/app/` directory.

2. **Create key.properties file**:
   Create a file named `key.properties` in the `android/` directory with your keystore information:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

3. **Build the release APK**:
   ```bash
   flutter build apk --release
   ```
   
   The signed APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`

**Important**: Never commit your `key.properties` file or keystore files to version control. They are already included in `.gitignore`.

## Hackathon Information

This project was created for the [Google Gemma 3n Hackathon](https://www.kaggle.com/competitions/google-gemma-3n-hackathon).

## License

MIT License - See LICENSE file for details

## Acknowledgments

- Google AI Edge team for the Gallery app inspiration
- MediaPipe team for the GenAI SDK
- Flutter Gemma package maintainers