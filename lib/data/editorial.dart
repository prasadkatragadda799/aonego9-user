/// Editorial content for the digest and the about story.
/// Live API payloads overlay this when the backend has published issues.
library;

import 'directory.dart';

class NewsletterIssue {
  final String id;
  final String kind; // happening | trend
  final String title;
  final String excerpt;
  final String body;
  final String city;
  final String date;
  final String tag;
  final String emoji;
  final int bg;
  final String? imageUrl;
  final String author;

  /// Industry vertical — fashion, film, music, agency, modelling, production,
  /// events, organisation. The brief asks the digest to be filterable by the
  /// industry a story belongs to, not only by happening/trend.
  final String vertical;

  const NewsletterIssue({
    required this.id,
    required this.kind,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.city,
    required this.date,
    required this.tag,
    required this.emoji,
    required this.bg,
    this.imageUrl,
    this.author = 'AOneGo9 Desk',
    this.vertical = 'all',
  });

  factory NewsletterIssue.fromJson(Map<String, dynamic> j) {
    final tag = j['tag'] as String? ?? j['category'] as String? ?? 'Digest';
    final title = j['title'] as String? ?? '';
    final body = j['body'] as String? ?? j['content'] as String? ?? '';
    final declared = (j['vertical'] as String? ?? '').trim().toLowerCase();
    return NewsletterIssue(
        id: '${j['id'] ?? ''}',
        kind: (j['kind'] as String? ?? j['type'] as String? ?? 'happening').toLowerCase().contains('trend')
            ? 'trend'
            : 'happening',
        title: j['title'] as String? ?? '',
        excerpt: j['excerpt'] as String? ?? j['summary'] as String? ?? '',
        body: j['body'] as String? ?? j['content'] as String? ?? '',
        city: j['city'] as String? ?? 'India',
        date: j['date'] as String? ?? j['published_at'] as String? ?? '',
        tag: tag,
        emoji: j['emoji'] as String? ?? '✦',
        bg: (j['bg'] as num?)?.toInt() ?? 0,
        imageUrl: (j['image_url'] as String?)?.trim().isNotEmpty == true ? j['image_url'] as String : null,
        author: j['author'] as String? ?? j['author_name'] as String? ?? 'AOneGo9 Desk',
        // Trust the desk's own tagging; infer only when it hasn't tagged one,
        // so the filter is useful before the backend ships the field.
        vertical: newsVerticals.any((v) => v.id == declared) && declared != 'all'
            ? declared
            : inferVertical(tag, title, body),
      );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'title': title,
        'excerpt': excerpt,
        'body': body,
        'city': city,
        'date': date,
        'tag': tag,
        'emoji': emoji,
        'bg': bg,
        'image_url': imageUrl,
        'author': author,
        'vertical': vertical,
      };
}

/// Digest content is API-only. No in-app seed stories.
const List<NewsletterIssue> seedNewsletters = [];

const List<Map<String, String>> aboutModules = [
  {
    'id': 'user',
    'icon': '✦',
    'name': 'Marketplace',
    'line': 'The AOneGo9 you are in now.',
    'copy':
        'Browse verified models, photographers, videographers, venues and event teams. Read the book, the packages and the scene rules — then inquire with a real brief.',
  },
  {
    'id': 'vendor',
    'icon': '⌂',
    'name': 'Vendor console',
    'line': 'For the people who get booked.',
    'copy':
        'Portfolio, packages, calendar, KYC and earnings live in the dedicated vendor app. The marketplace never becomes an admin panel.',
  },
  {
    'id': 'admin',
    'icon': '▣',
    'name': 'Super admin',
    'line': 'The desk that keeps the floor honest.',
    'copy':
        'Approvals, events, the live poster, subscriptions and the digest you are reading. Nothing reaches the public feed without this module.',
  },
];

/// Platform events are API-only. No in-app seed calendar.
const List<Map<String, dynamic>> seedEvents = [];
