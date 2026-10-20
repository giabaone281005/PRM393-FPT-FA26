import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/services/voice/speech_service.dart';

void main() {
  group('MockSpeechService lifecycle & states', () {
    late MockSpeechService service;

    setUp(() {
      service = MockSpeechService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is idle and words are empty', () {
      expect(service.state, VoiceState.idle);
      expect(service.recognizedWords, '');
      expect(service.lastError, isNull);
      expect(service.isListening, isFalse);
    });

    test('initialize transitions to idle on success', () async {
      final success = await service.initialize();
      expect(success, isTrue);
      expect(service.state, VoiceState.idle);
    });

    test('initialize transitions to unsupported on failure', () async {
      service.shouldSucceedInit = false;
      final success = await service.initialize();
      expect(success, isFalse);
      expect(service.state, VoiceState.unsupported);
      expect(service.lastError?.type, VoiceErrorType.serviceNotAvailable);
    });

    test(
      'startListening transitions to listening state and receives speech',
      () async {
        String? resultReceived;
        final started = await service.startListening(
          onResult: (words) => resultReceived = words,
        );
        expect(started, isTrue);
        expect(service.state, VoiceState.listening);
        expect(service.isListening, isTrue);

        service.simulateSpeech('năm quả', isFinal: false);
        expect(resultReceived, 'năm quả');
        expect(service.recognizedWords, 'năm quả');
        expect(service.state, VoiceState.listening);

        service.simulateSpeech('năm quả táo', isFinal: true);
        expect(resultReceived, 'năm quả táo');
        expect(service.recognizedWords, 'năm quả táo');
        expect(service.state, VoiceState.recognized);
      },
    );

    test('final empty speech triggers noSpeech error', () async {
      await service.startListening(onResult: (_) {});
      service.simulateSpeech('', isFinal: true);

      expect(service.state, VoiceState.error);
      expect(service.lastError?.type, VoiceErrorType.noSpeech);
    });

    test('simulateError updates error state and friendly message', () {
      service.simulateError(
        const VoiceError(
          type: VoiceErrorType.permissionDenied,
          message: 'Cần quyền micro',
        ),
      );
      expect(service.state, VoiceState.error);
      expect(service.lastError?.type, VoiceErrorType.permissionDenied);
      expect(service.lastError?.message, 'Cần quyền micro');
    });

    test('reset clears words and errors, returning to idle', () {
      service.simulateSpeech('ba quả', isFinal: true);
      expect(service.state, VoiceState.recognized);

      service.reset();
      expect(service.state, VoiceState.idle);
      expect(service.recognizedWords, '');
      expect(service.lastError, isNull);
    });

    test('stopListening transitions listening state to recognized if words present', () async {
      await service.startListening(onResult: (_) {});
      service.simulateSpeech('mười lăm', isFinal: false);
      await service.stopListening();

      expect(service.state, VoiceState.recognized);
    });

    test('cancelListening immediately resets to idle', () async {
      await service.startListening(onResult: (_) {});
      await service.cancelListening();

      expect(service.state, VoiceState.idle);
    });
  });
}
