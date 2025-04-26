import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart';

class SpeechService {
  final model = WhisperModel.base;
  final AudioRecorder audioRecorder = AudioRecorder();
  final WhisperController whisperController = WhisperController();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First try to load the model from assets
      debugPrint("Trying to load model from assets...");
      final bytesBase = await rootBundle.load('assets/ggml-base.bin');
      final modelPathBase = await whisperController.getPath(model);
      final fileBase = File(modelPathBase);
      await fileBase.writeAsBytes(bytesBase.buffer.asUint8List(bytesBase.offsetInBytes, bytesBase.lengthInBytes));
      debugPrint("Model loaded successfully from assets");
    } catch (e) {
      // If loading from assets fails, try downloading the model
      debugPrint("Error loading from assets: $e");
      debugPrint("Falling back to downloading the model...");
      try {
        await whisperController.downloadModel(model);
        debugPrint("Model downloaded successfully");
      } catch (downloadError) {
        debugPrint("Error downloading model: $downloadError");
        rethrow;
      }
    }
    
    _isInitialized = true;
  }

  Future<String> transcribeAudio(String audioPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final result = await whisperController.transcribe(
        model: model,
        audioPath: audioPath,
        lang: 'en',
      );

      debugPrint("Transcription: $result");

      return result?.transcription.text ?? '';
    } catch (e) {
      debugPrint("Error transcribing audio: $e");
      rethrow;
    }
  }

  Future<String> recordAudio() async {
    if (await audioRecorder.hasPermission()) {
      final Directory appDirectory = await getTemporaryDirectory();
      final String audioPath = '${appDirectory.path}/test.m4a';
      
      await audioRecorder.start(
        const RecordConfig(),
        path: audioPath,
      );
      
      return audioPath;
    }
    throw Exception('No recording permission');
  }

  Future<void> stopRecording() async {
    await audioRecorder.stop();
  }
} 