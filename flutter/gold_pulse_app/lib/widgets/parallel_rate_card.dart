import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';

/// بطاقة سعر صرف الدولار: السوق الموازي (السوداء) مقابل السعر الرسمي.
class ParallelRateCard extends StatelessWidget {
  final MarketFx fx;
  final bool compact;
  final double officialGram24;

  const ParallelRateCard({
    super.key,
    required this.fx,
    this.compact = false,
    this.officialGram24 = 0,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    if (fx.parallelSell <= 0) return const SizedBox.shrink();

    final change = fx.changeToday ?? fx.change ?? 0;
    final changePct = fx.changeTodayPct ?? fx.changePct ?? 0;
    final up = change > 0;
    final changeColor = change == 0 ? c.muted : (up ? c.green : c.red);
    final gap = fx.gapPct;
    final market = fx.parallelSell;
    final official = fx.official;
    final updated = DateTime.tryParse(fx.publishedAt)?.toLocal();

    return SurfaceCard(
      padding: EdgeInsets.all(compact ? 13 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.currency_exchange_rounded,
                  size: 16,
                  color: c.gold,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.rateTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.rateSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Pill(text: l.parallelMarket, color: c.gold, fontSize: 8),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.blackMarketHint,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l.number(market, digits: 1),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: compact ? 26 : 30,
                              fontWeight: FontWeight.w800,
                              color: c.gold,
                              height: 1.1,
                              letterSpacing: -0.8,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              ' ${l.perDollar}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (change != 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: changeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.rateToday,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8,
                          color: c.muted,
                        ),
                      ),
                      Text(
                        '${up ? '+' : ''}${l.number(change, digits: 0)} · ${l.percent(changePct, digits: 1, sign: true)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.rateBuyShort,
                  value: l.number(
                    fx.shopBuy > 0 ? fx.shopBuy : fx.parallelBuy,
                    digits: 1,
                  ),
                  color: c.ink,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniStat(
                  label: l.rateSellShort,
                  value: l.number(
                    fx.shopSell > 0 ? fx.shopSell : fx.parallelSell,
                    digits: 1,
                  ),
                  color: c.ink,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniStat(
                  label: l.officialCbi,
                  value: l.number(official, digits: 1),
                  color: c.muted,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _MiniStat(
                  label: l.rateGap,
                  value: l.percent(gap, digits: 1, sign: true),
                  color: gap > 0 ? c.red : c.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 11, color: c.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fx.estimated ? l.rateEstimated : l.goldUsesParallel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    height: 1.5,
                    color: fx.estimated ? c.red : c.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (officialGram24 > 0)
            Text(
              '${l.officialGram24}: ${l.iqd(officialGram24)}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 8.5,
                color: c.muted,
              ),
            ),
          Text(
            '${l.rateSource}: IQWealth (iraqsm.com)'
            '${updated == null ? '' : ' · ${l.rateUpdated} ${l.dateShort(updated.toIso8601String())}'}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 8,
              color: c.muted.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 7.5,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
