import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/forecast_card.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  static const _ranges = ['1mo', '3mo', '6mo', '1y', '5y'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.of(context);
      state.loadHistory(state.historyRange);
    });
  }

  String _rangeLabel(String value, bool en) {
    switch (value) {
      case '1mo':
        return en ? '1M' : 'شهر';
      case '3mo':
        return en ? '3M' : '3 أشهر';
      case '6mo':
        return en ? '6M' : '6 أشهر';
      case '5y':
        return en ? '5Y' : '5 سنوات';
      default:
        return en ? '1Y' : 'سنة';
    }
  }

  String _macroLabel(String key, bool en) {
    switch (key) {
      case 'dxy':
        return en ? 'Dollar index (DXY)' : 'مؤشر الدولار (DXY)';
      case 'us10y':
        return en ? 'US 10Y yield' : 'عائد السند الأمريكي 10 سنوات';
      case 'sp500':
        return 'S&P 500';
      case 'vix':
        return en ? 'VIX volatility' : 'مؤشر التقلب (VIX)';
      default:
        return key.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final analysis = state.analysis;
    final history = state.historyData;
    final market = state.market;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.market,
              subtitle: l.pick(
                'الرسم البياني والمستويات والمؤشرات',
                'Chart, levels and indicators',
              ),
              showBack: false,
              actions: [
                LiveBadge(at: state.marketUpdatedAt, l: l),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => state.loadHistory(state.historyRange),
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l.refresh,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                onRefresh: () async {
                  await Future.wait([
                    state.loadMarket(),
                    state.loadAnalysis(),
                    state.loadHistory(state.historyRange),
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                  children: [
                    if (state.lastError != null)
                      ErrorBanner(
                        message: state.lastError!,
                        onRetry: () => state.loadHistory(state.historyRange),
                        l: l,
                      ),
                    _HistoryCard(
                      history: history,
                      loading: state.loadingHistory,
                      l: l,
                      rangeLabel: (r) => _rangeLabel(r, state.en),
                      selected: state.historyRange,
                      ranges: _ranges,
                      onSelect: (r) => state.loadHistory(r),
                    ),
                    if (analysis != null) ...[
                      const SizedBox(height: 14),
                      ForecastCard(forecast: analysis.forecast, l: l, compact: true),
                      const SizedBox(height: 14),
                      _LevelsCard(analysis: analysis, l: l),
                      const SizedBox(height: 14),
                      _IndicatorsCard(analysis: analysis, l: l),
                    ],
                    if (market != null && market.macro.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SectionHeader(
                        title: l.macro,
                        subtitle: l.pick(
                          'العوامل التي تحرك الذهب الآن',
                          'The forces moving gold right now',
                        ),
                        icon: Icons.public_rounded,
                      ),
                      _MacroGrid(
                        macro: market.macro,
                        l: l,
                        labelFor: (k) => _macroLabel(k, state.en),
                      ),
                    ],
                    if (analysis != null) ...[
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: l.reasons,
                        icon: Icons.fact_check_outlined,
                      ),
                      _ComponentsList(components: analysis.shortTerm.components, l: l),
                    ],
                    const SizedBox(height: 16),
                    if (analysis != null)
                      DisclaimerBox(
                        label: l.disclaimer,
                        text: analysis.disclaimer,
                      ),
                    const SizedBox(height: 10),
                    Text(
                      l.priceNote,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        height: 1.55,
                        color: c.muted,
                      ),
                    ),
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

class _HistoryCard extends StatelessWidget {
  final HistoryPayload? history;
  final bool loading;
  final dynamic l;
  final String Function(String) rangeLabel;
  final String selected;
  final List<String> ranges;
  final ValueChanged<String> onSelect;

  const _HistoryCard({
    required this.history,
    required this.loading,
    required this.l,
    required this.rangeLabel,
    required this.selected,
    required this.ranges,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final data = history;
    final up = data != null && data.changePct >= 0;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.pick('سعر الذهب التاريخي', 'Gold price history'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (loading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: ranges.map((r) {
              final active = r == selected;
              return GestureDetector(
                onTap: () => onSelect(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? c.gold : c.surfaceAlt,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: active ? c.gold : c.border),
                  ),
                  child: Text(
                    rangeLabel(r),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? const Color(0xFF191305) : c.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (data == null || data.candles.isEmpty)
            SizedBox(
              height: 240,
              child: Center(
                child: loading
                    ? CircularProgressIndicator(color: c.gold)
                    : Text(
                        l.noData,
                        style: TextStyle(fontFamily: 'Cairo', color: c.muted),
                      ),
              ),
            )
          else ...[
            PriceChart(
              candles: data.candles,
              l: l,
              lineColor: up ? c.green : c.red,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: l.highLabel,
                    value: l.usd(data.high, digits: 0),
                    icon: Icons.north_rounded,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: StatTile(
                    label: l.lowLabel,
                    value: l.usd(data.low, digits: 0),
                    icon: Icons.south_rounded,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: StatTile(
                    label: l.pick('تغير الفترة', 'Period change'),
                    value: l.percent(data.changePct, sign: true),
                    valueColor: data.changePct >= 0 ? c.green : c.red,
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

class _LevelsCard extends StatelessWidget {
  final Analysis analysis;
  final dynamic l;

  const _LevelsCard({required this.analysis, required this.l});

  @override
  Widget build(BuildContext context) {
    final levels = analysis.levels;
    final c = AppColors.of(context);
    final items = <(String, String, Color?)>[
      (l.entryZone, l.usdRange(levels.entryLow, levels.entryHigh), c.gold),
      (l.target1, l.usd(levels.target1, digits: 0), c.green),
      (l.target2, l.usd(levels.target2, digits: 0), c.green),
      (l.stopLoss, l.usd(levels.stop, digits: 0), c.red),
      (l.support, l.usd(levels.support, digits: 0), c.blue),
      (l.resistance, l.usd(levels.resistance, digits: 0), c.amber),
    ];
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.levels,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (levels.riskReward != null)
                Pill(
                  text: '${l.riskReward} 1:${l.number(levels.riskReward!, digits: 1)}',
                  color: c.blue,
                  fontSize: 9,
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1.55,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: item.$3 ?? c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'ATR(14) ${l.usd(levels.atr, digits: 2)} · ${l.regime}: ${analysis.regime}',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 9.5, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _IndicatorsCard extends StatelessWidget {
  final Analysis analysis;
  final dynamic l;

  const _IndicatorsCard({required this.analysis, required this.l});

  @override
  Widget build(BuildContext context) {
    final ind = analysis.indicators;
    final c = AppColors.of(context);

    String num(double? v) => v == null ? '—' : l.number(v, digits: 2);

    final rows = <(String, String, Color?)>[
      ('RSI(14)', num(ind.rsi14),
          ind.rsi14 == null ? null : ind.rsi14! > 70 ? c.red : ind.rsi14! < 30 ? c.green : c.ink),
      ('MACD', num(ind.macdHist),
          ind.macdHist == null ? null : ind.macdHist! >= 0 ? c.green : c.red),
      ('SMA 20', num(ind.sma20),
          ind.sma20 == null ? null : ind.close >= ind.sma20! ? c.green : c.red),
      ('SMA 50', num(ind.sma50),
          ind.sma50 == null ? null : ind.close >= ind.sma50! ? c.green : c.red),
      ('SMA 200', num(ind.sma200),
          ind.sma200 == null ? null : ind.close >= ind.sma200! ? c.green : c.red),
      (l.pick('تقلب 20 يوم', '20d vol'), l.percent(ind.volatility20), null),
      (l.pick('عائد 5 أيام', '5d return'), l.percent(ind.return5d, sign: true),
          ind.return5d >= 0 ? c.green : c.red),
      (l.pick('عائد 20 يوم', '20d return'), l.percent(ind.return20d, sign: true),
          ind.return20d >= 0 ? c.green : c.red),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pick('المؤشرات الفنية', 'Technical indicators'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: c.muted,
                      ),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: row.$3 ?? c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  final Map<String, MacroPoint> macro;
  final dynamic l;
  final String Function(String) labelFor;

  const _MacroGrid({
    required this.macro,
    required this.l,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final entries = macro.entries.where((e) => e.value.ok).toList();
    if (entries.isEmpty) {
      return SurfaceCard(child: Text(l.noData));
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9,
      crossAxisSpacing: 9,
      childAspectRatio: 1.7,
      children: entries.map((entry) {
        final p = entry.value;
        final up = p.change5d >= 0;
        final color = up ? c.green : c.red;
        return Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                labelFor(entry.key),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: c.muted),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.number(p.value, digits: 2),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    l.percent(p.change5d, sign: true),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l.pick('آخر 20 يوم', '20 days'),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 8.5, color: c.muted),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ComponentsList extends StatelessWidget {
  final List<SignalComponent> components;
  final dynamic l;

  const _ComponentsList({required this.components, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (components.isEmpty) {
      return SurfaceCard(child: Text(l.noData));
    }
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: components.map((comp) {
          final positive = comp.score > 5;
          final negative = comp.score < -5;
          final color = positive ? c.green : negative ? c.red : c.amber;
          final width = (comp.score.abs() / 100).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comp.label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    Text(
                      l.number(comp.score, digits: 0),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: width,
                    minHeight: 4,
                    backgroundColor: c.surfaceAlt,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comp.detail,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    height: 1.4,
                    color: c.muted,
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
