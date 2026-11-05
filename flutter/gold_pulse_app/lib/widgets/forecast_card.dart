import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';

class ForecastCard extends StatelessWidget {
  final Forecast forecast;
  final L10n l;
  final bool compact;

  const ForecastCard({
    super.key,
    required this.forecast,
    required this.l,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (!forecast.ok || forecast.horizons.isEmpty) {
      return const SizedBox.shrink();
    }
    final s = forecast.summary;
    final up = s.direction == 'up';
    final down = s.direction == 'down';
    final accent = up ? c.green : down ? c.red : c.amber;
    final fraction = (s.upProbability / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.surface,
            accent.withValues(alpha: 0.07),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.insights_rounded, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.en ? 'Probability forecast' : 'توقع احتمالي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.muted,
                      ),
                    ),
                    Text(
                      l.en
                          ? 'Next ${s.days} trading sessions'
                          : 'خلال ${s.days} جلسات تداول قادمة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Pill(
                text: '${s.confidence}% ${l.confidence}',
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            s.headline,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 15 : 17,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (fraction * 1000).round().clamp(1, 999),
                    child: Container(color: c.green),
                  ),
                  Expanded(
                    flex: ((1 - fraction) * 1000).round().clamp(1, 999),
                    child: Container(color: c.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l.en ? 'Up' : 'صعود'} ${l.number(s.upProbability, digits: 0)}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.green,
                ),
              ),
              Text(
                '${l.en ? 'Down' : 'هبوط'} ${l.number(s.downProbability, digits: 0)}%',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l.en ? 'Expected range' : 'النطاق المتوقع',
                  value:
                      l.usdRange(s.rangeLow, s.rangeHigh),
                  l: l,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: l.en ? 'Expected price' : 'السعر المتوقع',
                  value: l.usd(s.expected, digits: 0),
                  l: l,
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: forecast.horizons.map((h) {
                final hUp = h.direction == 'up';
                final hColor = hUp ? c.green : h.direction == 'down' ? c.red : c.amber;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: c.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.en ? '${h.days}d' : '${h.days} يوم',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l.number(hUp ? h.upProbability : h.downProbability, digits: 0)}%',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: hColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        hUp ? Icons.north_east_rounded : h.direction == 'down' ? Icons.south_east_rounded : Icons.east_rounded,
                        size: 12,
                        color: hColor,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              s.prepareText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                height: 1.55,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              forecast.disclaimer,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                height: 1.5,
                color: c.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final L10n l;

  const _MiniStat({required this.label, required this.value, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: c.muted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
