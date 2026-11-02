import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract interface class LanguageAudio {
  Future<void> speak(String text, {bool slow = false});
  Future<bool> listen({
    required void Function(String) onWords,
    required void Function() onDone,
    required void Function() onError,
  });
  Future<void> stop();
}

/// One recognizer per app; permission is requested only after an explicit tap.
/// Raw audio is never stored or uploaded by Matlingo. The OS may use its services.
class DeviceLanguageAudio implements LanguageAudio {
  DeviceLanguageAudio._();
  static final shared = DeviceLanguageAudio._();
  final _tts = FlutterTts();
  final _speech = SpeechToText();
  void Function()? _done, _error;
  int _generation = 0;

  @override
  Future<void> speak(String text, {bool slow = false}) async {
    await stop();
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(slow ? .3 : .45);
    final result = await _tts.speak(text);
    if (result == 0) throw StateError('Speech unavailable');
  }

  @override
  Future<bool> listen({
    required void Function(String) onWords,
    required void Function() onDone,
    required void Function() onError,
  }) async {
    await stop();
    final generation = _generation;
    _done = onDone;
    _error = onError;
    final available = await _speech.initialize(
      options: [SpeechToText.androidNoBluetooth],
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _done?.call();
      },
      onError: (_) => _error?.call(),
    );
    if (!available || generation != _generation) return false;
    final locales = await _speech.locales();
    final english = locales
        .where((l) => l.localeId.replaceAll('_', '-').toLowerCase() == 'en-us')
        .firstOrNull;
    if (english == null || generation != _generation) return false;
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: english.localeId,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) {
        if (generation == _generation && result.finalResult) {
          onWords(result.recognizedWords);
        }
      },
    );
    return true;
  }

  @override
  Future<void> stop() async {
    _generation++;
    _done = null;
    _error = null;
    await _speech.cancel();
    await _tts.stop();
  }
}
