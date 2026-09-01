import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web Speech API binding.
///
/// Chrome and Edge expose `webkitSpeechRecognition`; the unprefixed
/// `SpeechRecognition` is the standard name. Safari and Firefox may expose
/// neither, which is why every entry point checks [isSupported] first.
class VoiceSearch {
  const VoiceSearch._();

  static JSObject? _active;

  static JSFunction? _constructor() {
    final w = globalContext;
    for (final name in const ['SpeechRecognition', 'webkitSpeechRecognition']) {
      if (w.hasProperty(name.toJS).toDart) {
        final ctor = w.getProperty(name.toJS);
        if (ctor.isDefinedAndNotNull) return ctor as JSFunction;
      }
    }
    return null;
  }

  static bool get isSupported => _constructor() != null;

  /// Listens for a single utterance and resolves with the transcript.
  ///
  /// Times out rather than hanging: a denied mic permission fires `onerror`
  /// on most browsers, but a tab that loses focus mid-listen can leave the
  /// recogniser silent forever, and a search box stuck in "listening" with no
  /// way out is worse than a failed attempt.
  static Future<VoiceResult> listen({String lang = 'en-IN'}) async {
    final ctor = _constructor();
    if (ctor == null) {
      return const VoiceResult.error('This browser does not support voice search');
    }

    stop(); // never run two recognisers at once

    final JSObject rec;
    try {
      rec = ctor.callAsConstructor<JSObject>();
    } catch (_) {
      return const VoiceResult.error('Voice search could not start');
    }
    _active = rec;

    rec.setProperty('lang'.toJS, lang.toJS);
    rec.setProperty('interimResults'.toJS, false.toJS);
    rec.setProperty('maxAlternatives'.toJS, 1.toJS);
    rec.setProperty('continuous'.toJS, false.toJS);

    final done = Completer<VoiceResult>();
    void finish(VoiceResult r) {
      if (!done.isCompleted) done.complete(r);
    }

    rec.setProperty(
      'onresult'.toJS,
      ((JSObject event) {
        try {
          final results = event.getProperty('results'.toJS) as JSObject;
          final first = results.getProperty(0.toJS) as JSObject;
          final alt = first.getProperty(0.toJS) as JSObject;
          final text = (alt.getProperty('transcript'.toJS) as JSString).toDart;
          finish(VoiceResult(text.trim()));
        } catch (_) {
          finish(const VoiceResult.error('Could not read what was said'));
        }
      }).toJS,
    );

    rec.setProperty(
      'onerror'.toJS,
      ((JSObject event) {
        final code = event.getProperty('error'.toJS);
        final key = code.isDefinedAndNotNull ? (code as JSString).toDart : '';
        finish(VoiceResult.error(switch (key) {
          'not-allowed' || 'service-not-allowed' =>
            'Microphone blocked — allow mic access to search by voice',
          'no-speech' => 'Didn\'t catch that — try again',
          'audio-capture' => 'No microphone found',
          'network' => 'Voice search needs a connection',
          _ => 'Voice search failed — type instead',
        }));
      }).toJS,
    );

    rec.setProperty(
      'onend'.toJS,
      (() {
        // Fires after onresult too; harmless because finish() is idempotent.
        finish(const VoiceResult.error('Didn\'t catch that — try again'));
      }).toJS,
    );

    try {
      (rec.getProperty('start'.toJS) as JSFunction).callAsFunction(rec);
    } catch (_) {
      _active = null;
      return const VoiceResult.error('Voice search could not start');
    }

    final result = await done.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => const VoiceResult.error('Voice search timed out'),
    );
    stop();
    return result;
  }

  static void stop() {
    final rec = _active;
    _active = null;
    if (rec == null) return;
    try {
      (rec.getProperty('stop'.toJS) as JSFunction).callAsFunction(rec);
    } catch (_) {
      // already stopped / never started
    }
  }
}

/// Outcome of one dictation attempt.
class VoiceResult {
  final String transcript;
  final String? error;
  const VoiceResult(this.transcript) : error = null;
  const VoiceResult.error(this.error) : transcript = '';
  bool get ok => error == null && transcript.trim().isNotEmpty;
}
