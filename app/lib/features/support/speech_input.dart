import 'package:speech_to_text/speech_to_text.dart';

/// Voice-to-text for the note field. Behind an interface so the screen tests
/// deterministically (a fake feeds transcripts) and degrades gracefully where
/// speech isn't available (the mic button simply hides).
abstract interface class SpeechInput {
  /// Prepare the engine and permissions. Returns false if unavailable/denied.
  Future<bool> init();
  bool get isAvailable;
  bool get isListening;

  /// Start transcribing; [onText] receives the running transcript.
  Future<void> start({required void Function(String text) onText});
  Future<void> stop();
}

/// The real engine, wrapping `speech_to_text`. On-device; needs only the mic +
/// speech-recognition permissions (declared in the platform manifests — no Apple
/// Developer Program required, unlike signing).
class DeviceSpeechInput implements SpeechInput {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> init() async {
    _available = await _speech.initialize();
    return _available;
  }

  @override
  Future<void> start({required void Function(String text) onText}) async {
    if (!_available) return;
    await _speech.listen(
      onResult: (r) => onText(r.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

/// The default when speech isn't wired (tests, unsupported platforms): reports
/// unavailable so the mic button is hidden. Never pretends to listen.
class NoSpeechInput implements SpeechInput {
  const NoSpeechInput();
  @override
  Future<bool> init() async => false;
  @override
  bool get isAvailable => false;
  @override
  bool get isListening => false;
  @override
  Future<void> start({required void Function(String text) onText}) async {}
  @override
  Future<void> stop() async {}
}
