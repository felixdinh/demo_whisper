import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/speech_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WhisperDemo(),
    );
  }
}

class WhisperDemo extends StatefulWidget {
  const WhisperDemo({super.key});

  @override
  State<WhisperDemo> createState() => _WhisperDemoState();
}

class _WhisperDemoState extends State<WhisperDemo> {
  final _speechService = SpeechService();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isPlaying = false;
  String _transcribedText = '';
  String? _lastRecordedPath;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
    _setupAudioPlayer();
  }

  Future<void> _setupAudioPlayer() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  Future<void> _initializeSpeechService() async {
    await _speechService.initialize();
  }

  Future<void> _startRecording() async {
    try {
      final audioPath = await _speechService.recordAudio();
      setState(() {
        _isRecording = true;
        _lastRecordedPath = audioPath;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      await _speechService.stopRecording();
      
      if (_lastRecordedPath != null) {
        final text = await _speechService.transcribeAudio(_lastRecordedPath!);
        
        setState(() {
          _isProcessing = false;
          _transcribedText = text;
        });
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (_lastRecordedPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(DeviceFileSource(_lastRecordedPath!));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whisper Demo'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_lastRecordedPath != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 48,
                            ),
                            onPressed: _togglePlayback,
                          ),
                        ],
                      ),
                    ),
                  Text(
                    _transcribedText,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        tooltip: 'Start listening',
        child: _isProcessing
            ? const CircularProgressIndicator()
            : Icon(
                _isRecording ? Icons.mic_off : Icons.mic,
                color: _isRecording ? Colors.red : null,
              ),
      ),
    );
  }
}
