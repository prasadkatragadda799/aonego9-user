/// Non-web fallback. Reports unsupported so callers hide the mic entirely.
class VoiceSearch {
  const VoiceSearch._();

  static bool get isSupported => false;

  static Future<VoiceResult> listen({String lang = 'en-IN'}) async =>
      const VoiceResult.error('Voice search needs a browser that supports speech input');

  static void stop() {}
}

/// Outcome of one dictation attempt.
class VoiceResult {
  final String transcript;
  final String? error;
  const VoiceResult(this.transcript) : error = null;
  const VoiceResult.error(this.error) : transcript = '';
  bool get ok => error == null && transcript.trim().isNotEmpty;
}
