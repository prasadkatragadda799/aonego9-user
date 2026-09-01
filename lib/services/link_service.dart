import 'package:url_launcher/url_launcher.dart';

/// Opens outbound links — social handles, partner sites, ad click-throughs.
///
/// Centralised for two reasons: every caller gets the same "open in a new tab,
/// don't leave the marketplace" behaviour, and every URL is validated before
/// it is handed to the platform. Profile data is vendor-supplied, so a field
/// can legitimately contain a `javascript:` string or plain garbage; those are
/// refused here rather than at twenty call sites.
class LinkService {
  const LinkService._();

  static const _allowedSchemes = {'http', 'https', 'mailto', 'tel'};

  /// Normalises a vendor-typed link. Returns null when it can't be trusted.
  static Uri? normalise(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;

    final parsed = Uri.tryParse(v.contains('://') || v.startsWith('mailto:') || v.startsWith('tel:')
        ? v
        : 'https://$v');
    if (parsed == null) return null;
    if (!_allowedSchemes.contains(parsed.scheme)) return null;
    if (parsed.scheme == 'http' || parsed.scheme == 'https') {
      if (parsed.host.isEmpty || !parsed.host.contains('.')) return null;
    }
    return parsed;
  }

  /// Opens [raw] in a new tab/window. Returns false when the link was
  /// rejected or the platform refused it, so the caller can toast.
  static Future<bool> open(String raw) async {
    final uri = normalise(raw);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Pre-filled WhatsApp share for a profile link.
  static Future<bool> shareOnWhatsApp(String text) =>
      open('https://wa.me/?text=${Uri.encodeComponent(text)}');
}
