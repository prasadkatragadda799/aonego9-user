/// Voice search — "voice search bar" from the brief.
///
/// Implemented against the browser's own Web Speech API rather than a plugin,
/// so it adds no dependency and no platform permission plumbing. On targets
/// without it the stub reports [isSupported] == false and the mic button is
/// simply not rendered — nothing shows a control that cannot work.
library;

export 'voice_search_stub.dart' if (dart.library.js_interop) 'voice_search_web.dart';
