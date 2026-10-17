import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceState {
  idle,
  requestingPermission,
  listening,
  processing,
  recognized,
  error,
  unsupported,
}

enum VoiceErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  noSpeech,
  networkError,
  serviceNotAvailable,
  busy,
  unknown,
}

class VoiceError {
  final VoiceErrorType type;
  final String message;
  final String? technicalMessage;

  const VoiceError({
    required this.type,
    required this.message,
    this.technicalMessage,
  });

  @override
  String toString() => 'VoiceError($type: $message, tech: $technicalMessage)';
}

abstract class SpeechService extends ChangeNotifier {
  VoiceState get state;
  String get recognizedWords;
  double get soundLevel;
  VoiceError? get lastError;
  bool get isListening;
  bool get isAvailable;

  Future<bool> initialize();
  Future<bool> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<double>? onSoundLevel,
    String localeId = 'vi_VN',
  });
  Future<void> stopListening();
  Future<void> cancelListening();
  void reset();
  @override
  void dispose();
}

class FlutterSpeechService extends SpeechService {
  final SpeechToText _speech;
  bool _initialized = false;
  VoiceState _state = VoiceState.idle;
  String _recognizedWords = '';
  double _soundLevel = 0.0;
  VoiceError? _lastError;
  ValueChanged<String>? _resultCallback;
  ValueChanged<double>? _soundLevelCallback;
  bool _isDisposed = false;

  FlutterSpeechService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  @override
  VoiceState get state => _state;

  @override
  String get recognizedWords => _recognizedWords;

  @override
  double get soundLevel => _soundLevel;

  @override
  VoiceError? get lastError => _lastError;

  @override
  bool get isListening => _state == VoiceState.listening;

  @override
  bool get isAvailable => _speech.isAvailable;

  void _setState(VoiceState newState) {
    if (_isDisposed) return;
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  Future<bool> initialize() async {
    if (_isDisposed) return false;
    if (_initialized) return _speech.isAvailable;

    _setState(VoiceState.requestingPermission);
    try {
      final available = await _speech.initialize(
        onError: _handleSpeechError,
        onStatus: _handleSpeechStatus,
        debugLogging: false,
      );

      if (_isDisposed) return false;

      _initialized = true;
      if (!available) {
        _lastError = const VoiceError(
          type: VoiceErrorType.serviceNotAvailable,
          message: 'Thiết bị hoặc trình duyệt chưa hỗ trợ nhận diện giọng nói.',
          technicalMessage: 'SpeechToText.initialize returned false',
        );
        _setState(VoiceState.unsupported);
        return false;
      }

      _setState(VoiceState.idle);
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _lastError = VoiceError(
        type: VoiceErrorType.serviceNotAvailable,
        message: 'Không thể khởi tạo micro hoặc dịch vụ nhận diện.',
        technicalMessage: e.toString(),
      );
      _setState(VoiceState.unsupported);
      return false;
    }
  }

  @override
  Future<bool> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<double>? onSoundLevel,
    String localeId = 'vi_VN',
  }) async {
    if (_isDisposed) return false;

    // Ngăn chặn gọi trùng lặp khi đang nghe hoặc đang xin quyền
    if (_state == VoiceState.listening ||
        _state == VoiceState.requestingPermission) {
      return true;
    }

    _resultCallback = onResult;
    _soundLevelCallback = onSoundLevel;
    _recognizedWords = '';
    _soundLevel = 0.0;
    _lastError = null;

    if (!_initialized) {
      final ok = await initialize();
      if (!ok) return false;
    }

    if (!_speech.isAvailable) {
      _lastError = const VoiceError(
        type: VoiceErrorType.serviceNotAvailable,
        message: 'Micro hoặc nhận diện giọng nói không khả dụng.',
      );
      _setState(VoiceState.unsupported);
      return false;
    }

    try {
      _setState(VoiceState.listening);

      await _speech.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: _handleSoundLevelChange,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
          localeId: localeId,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );

      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _lastError = VoiceError(
        type: VoiceErrorType.unknown,
        message: 'Không thể bắt đầu nghe. Bé thử lại nhé!',
        technicalMessage: e.toString(),
      );
      _setState(VoiceState.error);
      return false;
    }
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (_isDisposed) return;
    _recognizedWords = result.recognizedWords;
    _resultCallback?.call(_recognizedWords);

    if (result.finalResult) {
      if (_recognizedWords.trim().isEmpty) {
        _lastError = const VoiceError(
          type: VoiceErrorType.noSpeech,
          message: 'Cú chưa nghe rõ, bé bấm micro và nói lại nhé!',
        );
        _setState(VoiceState.error);
      } else {
        _setState(VoiceState.recognized);
      }
    } else {
      if (_state != VoiceState.listening) {
        _setState(VoiceState.listening);
      } else {
        notifyListeners();
      }
    }
  }

  void _handleSoundLevelChange(double level) {
    if (_isDisposed) return;
    _soundLevel = level;
    _soundLevelCallback?.call(level);
    notifyListeners();
  }

  void _handleSpeechStatus(String status) {
    if (_isDisposed) return;
    switch (status) {
      case 'listening':
        _setState(VoiceState.listening);
        break;
      case 'notListening':
      case 'done':
        if (_state == VoiceState.listening) {
          if (_recognizedWords.trim().isNotEmpty) {
            _setState(VoiceState.recognized);
          } else if (_lastError == null) {
            _setState(VoiceState.idle);
          }
        }
        break;
    }
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    if (_isDisposed) return;
    final errStr = error.errorMsg.toLowerCase();
    VoiceErrorType type = VoiceErrorType.unknown;
    String friendlyMessage = 'Có lỗi khi nghe. Bé thử lại nhé!';

    if (errStr.contains('permission') ||
        errStr.contains('denied') ||
        errStr.contains('not_allowed')) {
      type = VoiceErrorType.permissionDenied;
      friendlyMessage = 'Ứng dụng cần quyền micro để nghe bé nói. Bé nhờ bố mẹ bật quyền micro nhé!';
    } else if (errStr.contains('no_match') ||
        errStr.contains('speech_timeout') ||
        errStr.contains('speech timeout') ||
        errStr.contains('nothing')) {
      type = VoiceErrorType.noSpeech;
      friendlyMessage = 'Cú chưa nghe rõ âm thanh, bé bấm nói lại nhé!';
    } else if (errStr.contains('network') ||
        errStr.contains('server') ||
        errStr.contains('connection')) {
      type = VoiceErrorType.networkError;
      friendlyMessage = 'Mạng chập chờn, bé kiểm tra kết nối mạng nhé!';
    } else if (errStr.contains('busy')) {
      type = VoiceErrorType.busy;
      friendlyMessage = 'Micro đang bận, bé đợi một chút rồi bấm lại nhé!';
    }

    _lastError = VoiceError(
      type: type,
      message: friendlyMessage,
      technicalMessage: error.errorMsg,
    );
    _setState(VoiceState.error);
  }

  @override
  Future<void> stopListening() async {
    if (_isDisposed) return;
    if (_speech.isListening) {
      _setState(VoiceState.processing);
      await _speech.stop();
    }
    if (_state == VoiceState.processing || _state == VoiceState.listening) {
      _setState(
        _recognizedWords.trim().isNotEmpty
            ? VoiceState.recognized
            : VoiceState.idle,
      );
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_isDisposed) return;
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _setState(VoiceState.idle);
  }

  @override
  void reset() {
    if (_isDisposed) return;
    _recognizedWords = '';
    _soundLevel = 0.0;
    _lastError = null;
    _setState(VoiceState.idle);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.stop();
    _resultCallback = null;
    _soundLevelCallback = null;
    super.dispose();
  }
}

/// Mock SpeechService để phục vụ kiểm thử tự động (Unit test, Widget test)
class MockSpeechService extends SpeechService {
  VoiceState _state = VoiceState.idle;
  String _recognizedWords = '';
  double _soundLevel = 0.0;
  VoiceError? _lastError;
  bool shouldSucceedInit = true;
  bool isAvailableMock = true;
  ValueChanged<String>? _resultCallback;
  ValueChanged<double>? _soundLevelCallback;

  @override
  VoiceState get state => _state;

  @override
  String get recognizedWords => _recognizedWords;

  @override
  double get soundLevel => _soundLevel;

  @override
  VoiceError? get lastError => _lastError;

  @override
  bool get isListening => _state == VoiceState.listening;

  @override
  bool get isAvailable => isAvailableMock;

  @override
  Future<bool> initialize() async {
    _state = VoiceState.requestingPermission;
    notifyListeners();
    if (!shouldSucceedInit) {
      _state = VoiceState.unsupported;
      _lastError = const VoiceError(
        type: VoiceErrorType.serviceNotAvailable,
        message: 'Thiết bị không hỗ trợ nhận diện giọng nói.',
      );
      notifyListeners();
      return false;
    }
    _state = VoiceState.idle;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<double>? onSoundLevel,
    String localeId = 'vi_VN',
  }) async {
    if (_state == VoiceState.listening) return true;
    _resultCallback = onResult;
    _soundLevelCallback = onSoundLevel;
    _recognizedWords = '';
    _lastError = null;
    _state = VoiceState.listening;
    notifyListeners();
    return true;
  }

  /// Giả lập nói một câu
  void simulateSpeech(String words, {bool isFinal = false}) {
    _recognizedWords = words;
    _resultCallback?.call(words);
    if (isFinal) {
      _state = words.trim().isEmpty ? VoiceState.error : VoiceState.recognized;
      if (words.trim().isEmpty) {
        _lastError = const VoiceError(
          type: VoiceErrorType.noSpeech,
          message: 'Cú chưa nghe rõ, bé nói lại nhé!',
        );
      }
    }
    notifyListeners();
  }

  /// Giả lập lỗi
  void simulateError(VoiceError error) {
    _lastError = error;
    _state = VoiceState.error;
    notifyListeners();
  }

  /// Giả lập mức âm lượng micro
  void simulateSoundLevel(double level) {
    _soundLevel = level;
    _soundLevelCallback?.call(level);
    notifyListeners();
  }

  @override
  Future<void> stopListening() async {
    if (_state == VoiceState.listening) {
      _state = _recognizedWords.isNotEmpty
          ? VoiceState.recognized
          : VoiceState.idle;
      notifyListeners();
    }
  }

  @override
  Future<void> cancelListening() async {
    _state = VoiceState.idle;
    notifyListeners();
  }

  @override
  void reset() {
    _recognizedWords = '';
    _soundLevel = 0.0;
    _lastError = null;
    _state = VoiceState.idle;
    notifyListeners();
  }
}
