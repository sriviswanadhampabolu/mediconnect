import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool _isListening = false;
  bool get isListening => _isListening;

  int _listenSeconds = 0;
  int get listenSeconds => _listenSeconds;

  List<double> _waveAmplitudes = [0.2, 0.4, 0.6, 0.8, 0.5, 0.3, 0.7];
  List<double> get waveAmplitudes => _waveAmplitudes;

  Timer? _timer;
  Timer? _transcriptionTimer;

  // Real-time transcribed text
  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  // Voice Language
  String _voiceLanguageCode = 'hi-IN';
  String get voiceLanguageCode => _voiceLanguageCode;

  void setVoiceLanguage(String code) {
    _voiceLanguageCode = code;
    notifyListeners();
  }

  // Pre-configured multi-lingual medical voice streams for realistic clinical demo
  static final Map<String, List<String>> _sampleVoiceDictations = {
    'hi-IN': [
      'मुझे', 'सुबह', 'से', 'सिरदर्द', 'और', 'हल्का', 'बुखार', 'है,', 'कृपया', 'सुरक्षित', 'दवा', 'बताएं।'
    ],
    'te-IN': [
      'నాకు', 'ఉదయం', 'నుండి', 'తీవ్రమైన', 'తలనొప్పి', 'మరియు', 'జ్వరం', 'ఉంది,', 'సురక్షితమైన', 'మందులు', 'చెప్పండి.'
    ],
    'ta-IN': [
      'எனக்கு', 'காலையிலிருந்து', 'கடுமையான', 'தலைவலி', 'மற்றும்', 'காய்ச்சல்', 'உள்ளது,', 'மருந்து', 'பரிந்துரைக்கவும்.'
    ],
    'en-IN': [
      'I', 'have', 'had', 'a', 'bad', 'headache', 'and', 'mild', 'fever', 'since', 'morning,', 'suggest', 'safe', 'relief.'
    ]
  };

  /// Start real-time microphone listening
  void startListening({
    required Function(String currentText) onTranscriptUpdate,
    required Function(String finalText) onComplete,
    String? preferredLanguage,
  }) {
    if (_isListening) return;

    _isListening = true;
    _listenSeconds = 0;
    _liveTranscript = '';
    notifyListeners();

    final langKey = preferredLanguage ?? _voiceLanguageCode;
    final words = _sampleVoiceDictations[langKey] ?? _sampleVoiceDictations['en-IN']!;

    // Waveform & Seconds pulse
    final random = Random();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _waveAmplitudes = List.generate(7, (_) => 0.15 + random.nextDouble() * 0.85);
      if (t.tick % 10 == 0) {
        _listenSeconds++;
      }
      notifyListeners();
    });

    // Real-time word-by-word transcription streaming
    int wordIdx = 0;
    _transcriptionTimer = Timer.periodic(const Duration(milliseconds: 320), (t) {
      if (!_isListening) {
        t.cancel();
        return;
      }

      if (wordIdx < words.length) {
        if (_liveTranscript.isEmpty) {
          _liveTranscript = words[wordIdx];
        } else {
          _liveTranscript += ' ${words[wordIdx]}';
        }
        onTranscriptUpdate(_liveTranscript);
        wordIdx++;
        notifyListeners();
      } else {
        // Automatically stop after full sentence spoken
        stopListening();
        onComplete(_liveTranscript);
      }
    });
  }

  /// Stop microphone listening
  void stopListening() {
    _isListening = false;
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    _waveAmplitudes = [0.2, 0.3, 0.4, 0.3, 0.2];
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transcriptionTimer?.cancel();
    super.dispose();
  }
}
