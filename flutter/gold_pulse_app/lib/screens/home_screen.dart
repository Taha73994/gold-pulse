import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/forecast_card.dart';
import '../widgets/local_quote_card.dart';
import '../widgets/parallel_rate_card.dart';
import '../widgets/plan_sheet.dart';
import 'alerts_screen.dart';
import 'ads_screen.dart';
import 'calculator_screen.dart';
import 'currency_screen.dart';
import 'news_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int index) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final analysis = state.analysis;
    final market = state.market;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: c.gold,
        // لا سحب للتحديث: التحديث يتم تلقائياً في الخلفية.
        notificationPredicate: (_) => false,
        onRefresh: state.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 26),
          children: [
            const GoldHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.lastError != null)
                    ErrorBanner(
                      message: state.lastError!,
                      onRetry: state.refreshAll,
                      l: l,
                    ),
                  _PriceHero(
                    market: market,
                    l: l,
                    loading: state.loadingMarket,
                    onTap: () => onNavigate(1),
                  ),
                  if (market?.fx != null) ...[
                    const SizedBox(height: 12),
                    ParallelRateCard(
                      fx: market!.fx!,
                      compact: true,
                      officialGram24: market.iqdGramOfficial[24] ?? 0,
                    ),
                  ],
                  if (market?.local != null && !market!.local!.isEmpty) ...[
                    const SizedBox(height: 12),
                    LocalQuoteCard(quote: market.local!),
                  ],
                  const SizedBox(height: 14),
                  _QuickActions(l: l),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: l.todaySignal,
                    subtitle: l.pick(
                      'تحليل فني + أخبار + دولار وفائدة، بلغة واضحة.',
                      'Technicals + news + dollar and rates, in plain language.',
                    ),
                    icon: Icons.radar_rounded,
                    trailing: analysis == null
                        ? null
                        : Pill(
                            text: '${analysis.confidence}%',
                            color: toneColor(analysis.tone, c),
                          ),
                  ),
                  if (analysis != null)
                    _SignalCard(state: state, onOpenMentor: () => onNavigate(2))
                  else
                    const _LoadingCard(height: 190),
                  if (analysis != null && analysis.forecast.ok) ...[
                    const SizedBox(height: 14),
                    ForecastCard(forecast: analysis.forecast, l: l),
                  ],
                  if (analysis != null && analysis.mentor.note.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _MentorNote(
                      mentor: analysis.mentor,
                      l: l,
                      onTap: () => onNavigate(2),
                    ),
                  ],
                  if (analysis != null) ...[
                    const SizedBox(height: 18),
                    _PlanPreview(
                      analysis: analysis,
                      l: l,
                      onOpen: () => showPlanSheet(context, state),
                    ),
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: l.reasons,
                      icon: Icons.fact_check_outlined,
                    ),
                    _ReasonsList(reasons: analysis.topReasons, l: l),
                  ],
                  if (state.newsData != null &&
                      state.newsData!.catalysts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: l.catalysts,
                      icon: Icons.newspaper_rounded,
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NewsScreen()),
                        ),
                        child: Text(l.viewAll),
                      ),
                    ),
                    ...state.newsData!.catalysts
                        .take(3)
                        .map(
                          (item) => _MiniNews(
                            item: item,
                            l: l,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NewsScreen(),
                              ),
                            ),
                          ),
                        ),
                  ],
                  if (state.homeAds.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: l.featuredAds,
                      subtitle: l.pick(
                        'إعلانات مدفوعة من محلات ومنتجات.',
                        'Paid offers from shops and products.',
                      ),
                      icon: Icons.campaign_rounded,
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdsScreen()),
                        ),
                        child: Text(l.viewAll),
                      ),
                    ),
                    SizedBox(
                      height: 214,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: state.homeAds.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, i) => _HomeAdCard(
                          ad: state.homeAds[i],
                          state: state,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.shops.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: l.shops,
                      subtitle: l.pick(
                        'عناوين وأرقام محلات الذهب.',
                        'Gold shop addresses and phone numbers.',
                      ),
                      icon: Icons.storefront_rounded,
                      trailing: TextButton(
                        onPressed: () => onNavigate(3),
                        child: Text(l.viewAll),
                      ),
                    ),
                    ...state.shops
                        .take(2)
                        .map(
                          (shop) => _ShopMini(
                            shop: shop,
                            en: state.en,
                            onTap: () => onNavigate(3),
                          ),
                        ),
                  ],
                  const SizedBox(height: 20),
                  _UsersStrip(state: state),
                  const SizedBox(height: 14),
                  DisclaimerBox(
                    label: l.disclaimer,
                    text: state.config.disclaimer.isNotEmpty
                        ? state.config.disclaimer
                        : l.financialDisclaimer,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const GoldLogo(size: 34),
                        const SizedBox(height: 7),
                        Text(
                          '${l.appName} · v${state.config.version}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.copyright,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceHero extends StatelessWidget {
  final MarketSnapshot? market;
  final dynamic l;
  final bool loading;
  final VoidCallback onTap;

  const _PriceHero({
    required this.market,
    required this.l,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (market == null) {
      return GoldGlow(
        child: SizedBox(
          height: 200,
          child: Center(
            child: loading
                ? CircularProgressIndicator(color: c.gold)
                : Text(
                    l.connectionError,
                    style: TextStyle(fontFamily: 'Cairo', color: c.muted),
                  ),
          ),
        ),
      );
    }
    final m = market!;
    final up = m.changePct >= 0;
    final color = up ? c.green : c.red;
    return GoldGlow(
      padding: const EdgeInsets.all(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 7, color: c.green),
                const SizedBox(width: 6),
                Text(
                  l.goldPrice,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Pill(text: l.live, color: c.green, fontSize: 8),
                const Spacer(),
                Text(
                  '${l.updated} ${l.timeAgo(m.asOf)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: c.muted,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.chevron_left_rounded, size: 15, color: c.muted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l.usd(m.usdOz, digits: 2),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ChangeChip(
                    value: m.changePct,
                    absolute: m.changeUsd,
                    l: l,
                    large: true,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  l.usdOz,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: c.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${l.openLabel} ${l.number(m.open)} · ${l.highLabel} ${l.number(m.high)} · ${l.lowLabel} ${l.number(m.low)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: c.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Sparkline(values: m.spark, color: color, height: 44),
            const SizedBox(height: 10),
            Divider(color: c.border, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [24, 22, 21, 18].map((karat) {
                final value = m.gram(karat);
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: c.gold.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '$karat',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: c.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l.en ? 'K' : 'عيار',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 8.5,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.number(value),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l.en ? 'IQD/g' : 'د.ع/غ',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8.5,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(Icons.currency_exchange_rounded, size: 12, color: c.muted),
                const SizedBox(width: 4),
                Text(
                  '${l.parallelDollarShort} ${l.number(m.usdIqd, digits: 1)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: c.muted,
                  ),
                ),
                const Spacer(),
                Text(
                  l.priceSource,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final dynamic l;
  const _QuickActions({required this.l});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calculate_rounded, l.calculator, const CalculatorScreen()),
      (Icons.currency_exchange_rounded, l.currencies, const CurrencyScreen()),
      (Icons.newspaper_rounded, l.news, const NewsScreen()),
      (Icons.notifications_active_outlined, l.alerts, const AlertsScreen()),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _QuickAction(
              icon: item.$1,
              label: item.$2,
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => item.$3)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: c.gold),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final AppState state;
  final VoidCallback onOpenMentor;

  const _SignalCard({required this.state, required this.onOpenMentor});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final a = state.analysis!;
    final color = toneColor(a.tone, c);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, color.withValues(alpha: 0.07)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  a.actionLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  a.regime,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: c.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${l.horizon} ${a.horizon}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.5,
                  color: c.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.plan.verdict,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          ScoreBar(score: a.score, l: l),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.confidence,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: a.confidence / 100,
                        minHeight: 6,
                        backgroundColor: c.surfaceAlt,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${a.confidence}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            a.summary,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              height: 1.6,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 11),
          _AdviceBlock(state: state, analysis: a),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenMentor,
                  icon: const Icon(Icons.psychology_alt_rounded, size: 17),
                  label: Text(l.readMentor),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => showPlanSheet(context, state),
                child: Text(l.weeklyPlan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceBlock extends StatelessWidget {
  final AppState state;
  final Analysis analysis;

  const _AdviceBlock({required this.state, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final plan = analysis.plan;
    final color = toneColor(analysis.tone, c);
    final steps = plan.steps.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, size: 15, color: c.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.whatNow,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              Text(
                analysis.actionLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (steps.isNotEmpty) const SizedBox(height: 8),
          ...steps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 17,
                    height: 17,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: c.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        height: 1.55,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (plan.riskNote.isNotEmpty) ...[
            Divider(color: c.border, height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 13, color: c.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l.avoidNow}: ${plan.riskNote}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      height: 1.5,
                      color: c.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (plan.invalidation > 0) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sync_problem_rounded, size: 13, color: c.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l.changeDecision} ${l.usd(plan.invalidation, digits: 0)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      height: 1.5,
                      color: c.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MentorNote extends StatelessWidget {
  final Mentor mentor;
  final dynamic l;
  final VoidCallback onTap;

  const _MentorNote({
    required this.mentor,
    required this.l,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  size: 17,
                  color: Color(0xFF1B1505),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  l.mentorShort,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.gold,
                  ),
                ),
              ),
              Pill(text: mentor.conviction, color: c.gold),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            mentor.headline,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              height: 1.45,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            mentor.note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              height: 1.6,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                l.readMentor,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.gold,
                ),
              ),
              Icon(Icons.chevron_left_rounded, size: 15, color: c.gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  final Analysis analysis;
  final dynamic l;
  final VoidCallback onOpen;

  const _PlanPreview({
    required this.analysis,
    required this.l,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final plan = analysis.plan;
    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.weeklyPlan,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: onOpen,
                child: Text(l.pick('التفاصيل', 'Details')),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _MiniLevel(
                  label: l.entryZone,
                  value: l.usdRange(plan.entryLow, plan.entryHigh),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _MiniLevel(
                  label: l.target1,
                  value: l.usd(plan.target1, digits: 0),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _MiniLevel(
                  label: l.stopLoss,
                  value: l.usd(plan.invalidation, digits: 0),
                  color: c.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLevel extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _MiniLevel({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: c.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color ?? c.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReasonsList extends StatelessWidget {
  final List<SignalComponent> reasons;
  final dynamic l;
  const _ReasonsList({required this.reasons, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (reasons.isEmpty) {
      return SurfaceCard(child: Text(l.noData));
    }
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: reasons.map((r) {
          final positive = r.impact == 'positive';
          final negative = r.impact == 'negative';
          final color = positive
              ? c.green
              : negative
              ? c.red
              : c.amber;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : negative
                      ? Icons.trending_down_rounded
                      : Icons.remove_rounded,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        r.detail,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          height: 1.5,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniNews extends StatelessWidget {
  final NewsItem item;
  final dynamic l;
  final VoidCallback onTap;

  const _MiniNews({required this.item, required this.l, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final positive = item.positive;
    final negative = item.negative;
    final color = positive
        ? c.green
        : negative
        ? c.red
        : c.amber;
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
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
              positive
                  ? Icons.trending_up_rounded
                  : negative
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${item.source} · ${l.timeAgo(item.publishedAt)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9.5,
                          color: c.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
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

class _HomeAdCard extends StatelessWidget {
  final AdItem ad;
  final AppState state;
  final VoidCallback onTap;

  const _HomeAdCard({
    required this.ad,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final image = state.api.mediaUrl(ad.imageUrl);
    return SizedBox(
      width: 218,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImageBox(url: image, height: 96, radius: 20),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Pill(
                    text: l.sponsored,
                    color: c.gold,
                    filled: true,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.displayTitle(state.en),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.price > 0
                        ? '${l.number(ad.price)} ${ad.currency}'
                        : l.priceOnRequest,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ad.city,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopMini extends StatelessWidget {
  final Shop shop;
  final bool en;
  final VoidCallback onTap;

  const _ShopMini({required this.shop, required this.en, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFF1B1505),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.displayName(en),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${shop.displayCity(en)} · ${shop.displayAddress(en)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    color: c.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (shop.isVerified)
            const Pill(text: '✓', color: Color(0xFF2DD4BF), fontSize: 10),
          const SizedBox(width: 6),
          Icon(Icons.chevron_left_rounded, size: 18, color: c.muted),
        ],
      ),
    );
  }
}

class _UsersStrip extends StatelessWidget {
  final AppState state;
  const _UsersStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final p = state.presence;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, size: 15, color: c.gold),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              l.en
                  ? '${p.onlineNow} online · ${p.activeToday} active today · ${p.totalUsers} total users'
                  : '${p.onlineNow} متصل الآن · ${p.activeToday} نشط اليوم · ${p.totalUsers} إجمالي المستخدمين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                color: c.muted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Center(child: CircularProgressIndicator(color: c.gold)),
    );
  }
}
