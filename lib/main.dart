import 'package:flutter/material.dart';
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
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

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

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
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
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_lastRecordedPath!));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
                    Column(
                      children: [
                        Slider(
                          value: _position.inSeconds.toDouble(),
                          min: 0.0,
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position)),
                              Text(_formatDuration(_duration)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
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
                      ],
                    ),
                  const SizedBox(height: 20),
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
