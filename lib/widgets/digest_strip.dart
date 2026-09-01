import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../data/editorial.dart';
import 'common.dart';

/// Home-page strip: What's happening + Trends, as upload-style cards.
class DigestStrip extends StatelessWidget {
  const DigestStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pad = isNarrow(context) ? 16.0 : 20.0;
    final happening = app.happeningIssues.take(4).toList();
    final trends = app.trendIssues.take(4).toList();
    if (happening.isEmpty && trends.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 4, pad, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('On the floor this week',
                    style: F.fraunces(size: 22, weight: FontWeight.w700, color: T.cream, letterSpacing: -0.4)),
              ),
              HoverFx(
                onTap: () => app.setView('newsletter'),
                builder: (h) => Text('Full digest →',
                    style: F.syne(size: 12.5, weight: FontWeight.w700, color: h ? T.cream : T.gold)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Uploads from the desk — what\'s happening, and what\'s trending.',
              style: F.syne(size: 13, weight: FontWeight.w400, color: T.mut)),
          const SizedBox(height: 16),
          if (happening.isNotEmpty) ...[
            const _RailLabel(icon: '◉', label: 'What\'s happening'),
            const SizedBox(height: 10),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: happening.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _HappenCard(issue: happening[i], onTap: () => app.openIssue(happening[i])),
              ),
            ),
            const SizedBox(height: 22),
          ],
          if (trends.isNotEmpty) ...[
            const _RailLabel(icon: '△', label: 'Trends'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in trends)
                  _TrendChip(issue: t, onTap: () => app.openIssue(t)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RailLabel extends StatelessWidget {
  final String icon;
  final String label;
  const _RailLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: TextStyle(fontSize: 11, color: T.gold)),
        const SizedBox(width: 8),
        Text(label.toUpperCase(),
            style: F.syne(size: 10, weight: FontWeight.w700, color: T.dim, letterSpacing: 2)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: T.bdr)),
      ],
    );
  }
}

class _HappenCard extends StatelessWidget {
  final NewsletterIssue issue;
  final VoidCallback onTap;
  const _HappenCard({required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
        builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 240,
        height: 210,
        decoration: BoxDecoration(
          color: T.card,
          border: Border.all(color: h ? T.gold.withValues(alpha: .4) : T.bdr),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(0, h ? -3 : 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: issue.imageUrl != null
                  ? Image.network(issue.imageUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 34))
                  : GradientArt(bgIndex: issue.bg, emoji: issue.emoji, emojiSize: 34),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${issue.tag.toUpperCase()}  ·  ${issue.city}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: F.syne(size: 9.5, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(issue.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: F.fraunces(size: 14.5, weight: FontWeight.w700, color: T.cream, height: 1.2)),
                    const Spacer(),
                    Text(issue.date, style: F.mono(size: 10, color: T.dim)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final NewsletterIssue issue;
  final VoidCallback onTap;
  const _TrendChip({required this.issue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverFx(
      onTap: onTap,
      builder: (h) => Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
        decoration: BoxDecoration(
          color: h ? T.gold.withValues(alpha: .08) : T.card,
          border: Border.all(color: h ? T.gold.withValues(alpha: .4) : T.bdr),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: T.gr(issue.bg),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(issue.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue.tag.toUpperCase(),
                      style: F.syne(size: 9, weight: FontWeight.w700, color: T.gold, letterSpacing: 1.3)),
                  const SizedBox(height: 3),
                  Text(issue.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: F.syne(size: 12.5, weight: FontWeight.w700, color: T.cream, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
