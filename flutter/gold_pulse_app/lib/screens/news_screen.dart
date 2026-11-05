import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _category = 'all';

  static const _categories = [
    'all',
    'fed',
    'inflation',
    'jobs',
    'election',
    'geopolitics',
    'dollar',
    'technical',
    'other',
  ];

  String _label(String code, dynamic l) =>
      code == 'all' ? l.all : l.category(code);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final payload = state.newsData;
    final items = payload == null
        ? const <NewsItem>[]
        : (_category == 'all'
            ? payload.items
            : payload.items.where((i) => i.category == _category).toList());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.newsCenter,
              subtitle: l.newsLangNote,
              actions: [
                IconButton(
                  onPressed: state.loadingNews ? null : state.loadNews,
                  icon: state.loadingNews
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.gold,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  tooltip: l.refresh,
                ),
              ],
            ),
            if (payload != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: _SummaryBar(summary: payload.summary, l: l),
              ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((code) {
                  final active = code == _category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () => setState(() => _category = code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active ? c.gold : c.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: active ? c.gold : c.border),
                        ),
                        child: Text(
                          _label(code, l),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? const Color(0xFF191305) : c.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                onRefresh: () => state.loadNews(),
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (state.loadingNews)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: CircularProgressIndicator(color: c.gold),
                              ),
                            )
                          else
                            EmptyState(
                              icon: Icons.newspaper_rounded,
                              title: l.noNews,
                              subtitle: l.newsLangNote,
                            ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, i) => _NewsCard(
                          item: items[i],
                          state: state,
                          onTap: () => _open(context, items[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, NewsItem item) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(text: item.categoryLabel, color: c.gold),
                  Pill(
                    text: l.impact(item.impact),
                    color: item.impact == 'high' ? c.red : c.amber,
                  ),
                  Pill(
                    text: item.sentimentLabel,
                    color: item.positive
                        ? c.green
                        : item.negative
                            ? c.red
                            : c.muted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.source} · ${l.timeAgo(item.publishedAt)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: c.muted,
                ),
              ),
              if (item.why.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l.whyItMatters,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.gold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.why,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    height: 1.7,
                    color: c.ink,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (item.link.isNotEmpty)
                FilledButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(item.link);
                    if (uri == null) return;
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(l.openArticle),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final NewsSummary summary;
  final dynamic l;

  const _SummaryBar({required this.summary, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final positive = summary.score > 0.05;
    final negative = summary.score < -0.05;
    final color = positive ? c.green : negative ? c.red : c.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            positive
                ? Icons.trending_up_rounded
                : negative
                    ? Icons.trending_down_rounded
                    : Icons.remove_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.newsSummary}: ${summary.label}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  '${summary.count} ${l.articles} · ${summary.sources} ${l.sources} · '
                  '${summary.positive}+ / ${summary.negative}-',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            l.number(summary.score * 100, digits: 0),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final AppState state;
  final VoidCallback onTap;

  const _NewsCard({
    required this.item,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final color = item.positive
        ? c.green
        : item.negative
            ? c.red
            : c.amber;
    return SurfaceCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              item.positive
                  ? Icons.trending_up_rounded
                  : item.negative
                      ? Icons.trending_down_rounded
                      : Icons.remove_rounded,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${item.source} · ${l.timeAgo(item.publishedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9.5,
                          color: c.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Pill(text: item.categoryLabel, color: c.gold, fontSize: 8),
                    const SizedBox(width: 4),
                    Pill(
                      text: l.impact(item.impact),
                      color: item.impact == 'high' ? c.red : c.amber,
                      fontSize: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
