# Demo Whisper

A Flutter application that demonstrates voice recording and transcription using Whisper AI.

## Setup Instructions

### 1. Project Structure
- The project requires an `assets/models` directory to store the Whisper model files
- Directory structure:
  ```
  assets/
  └── models/
      └── [whisper model files]
  ```

### 2. Download Whisper Model
1. Visit [Hugging Face Whisper.cpp repository](https://huggingface.co/ggerganov/whisper.cpp/tree/main)
2. Choose a model based on your needs:
   - For best accuracy: `ggml-large-v3.bin` (3.1GB)
   - For balanced performance: `ggml-medium.bin` (1.53GB)
   - For faster processing: `ggml-small.bin` (488MB)
   - For quick testing: `ggml-tiny.bin` (77.7MB)
3. Download the selected model file
4. Place the downloaded model file in the `assets/models` directory

### 3. Update pubspec.yaml
Make sure to include the model file in your assets section in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/your_model_file.bin
```

### 4. Run the Application
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Run the app:
   ```bash
   flutter run
   ```

## Features
- Voice recording
- Audio transcription using Whisper AI
- Real-time processing
- Support for multiple languages

## Requirements
- Flutter SDK ^3.7.2
- iOS 13.0+ / Android 5.0+
- Microphone permission
- Storage permission

## Dependencies
- record: ^5.0.4
- path_provider: ^2.1.5
- permission_handler: ^11.3.0
- whisper_ggml: ^1.3.0
- audioplayers: ^5.2.1
