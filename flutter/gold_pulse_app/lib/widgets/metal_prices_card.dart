import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';
import 'price_unit_toggle.dart';

/// لوحة أسعار الذهب المرجعية: الأونصة والغرام والمثقال بوحدة العرض المختارة،
/// مع عرض القيمة المكافئة بالوحدة الأخرى على سعر السوق الموازي.
class MetalPricesCard extends StatelessWidget {
  final MarketSnapshot market;
  final bool compact;

  const MetalPricesCard({
    super.key,
    required this.market,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final iqd = state.iqdMode;
    final other = !iqd;

    String primary(double value, {int? digits}) =>
        l.priceText(value, iqd: iqd, digits: digits);
    String secondary(double value) => l.priceText(value, iqd: other);

    final rows = <(IconData, String, double, double, Color)>[
      (
        Icons.workspace_premium_rounded,
        l.ouncePrice,
        market.ounceIn(iqd),
        market.ounceIn(other),
        c.gold,
      ),
      (
        Icons.circle,
        l.en ? 'Gram 24K' : 'غرام عيار 24',
        market.gramIn(24, iqd),
        market.gramIn(24, other),
        c.ink,
      ),
      (
        Icons.circle_outlined,
        l.en ? 'Gram 21K' : 'غرام عيار 21',
        market.gramIn(21, iqd),
        market.gramIn(21, other),
        c.ink,
      ),
      (
        Icons.scale_rounded,
        l.mithqal21,
        market.mithqalIn(21, iqd),
        market.mithqalIn(21, other),
        c.green,
      ),
      (
        Icons.scale_outlined,
        l.mithqal24,
        market.mithqalIn(24, iqd),
        market.mithqalIn(24, other),
        c.ink,
      ),
    ];

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
                  Icons.workspace_premium_rounded,
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
                      l.pick('أسعار الذهب المرجعية', 'Reference gold prices'),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.priceInParallel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const PriceUnitToggle(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 4 : 5),
              child: Row(
                children: [
                  Icon(row.$1, size: 12, color: row.$5),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          primary(
                            row.$3,
                            digits: row.$1 == Icons.workspace_premium_rounded
                                ? null
                                : (iqd ? 0 : 2),
                          ),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: compact ? 12.5 : 14,
                            fontWeight: FontWeight.w800,
                            color: row.$5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        secondary(row.$4),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8.5,
                          color: c.muted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: c.border, height: 1),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.swap_vert_rounded, size: 11, color: c.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l.mithqalNote} · ${l.parallelDollarShort} ${l.number(market.parallelRate, digits: 1)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 8.5,
                    color: c.muted,
                  ),
                ),
              ),
              Text(
                l.perDollar,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 8.5,
                  color: c.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
