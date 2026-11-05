import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'common.dart';

/// بطاقة سعر السوق العراقي: سعر الشاشة مقابل سعر البيع (ask) وسعر الشراء (bid)
/// والفرق بينهما لكل عيار.
class LocalQuoteCard extends StatefulWidget {
  final LocalQuote quote;
  final bool compact;

  const LocalQuoteCard({super.key, required this.quote, this.compact = false});

  @override
  State<LocalQuoteCard> createState() => _LocalQuoteCardState();
}

class _LocalQuoteCardState extends State<LocalQuoteCard> {
  int? _selected;

  int get _karat {
    if (_selected != null && widget.quote.byKarat.containsKey(_selected)) {
      return _selected!;
    }
    for (final k in const [24, 22, 21, 18]) {
      if (widget.quote.byKarat.containsKey(k)) return k;
    }
    return widget.quote.byKarat.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final quote = widget.quote;
    if (quote.isEmpty) return const SizedBox.shrink();

    final karats = quote.byKarat.keys.toList()..sort((a, b) => b.compareTo(a));
    final karat = _karat;
    final q = quote.byKarat[karat]!;
    final note = state.en ? quote.noteEn : quote.noteAr;

    return SurfaceCard(
      padding: EdgeInsets.all(widget.compact ? 13 : 15),
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
                child: Icon(Icons.storefront_rounded, size: 16, color: c.gold),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.iraqLocalTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      l.iraqLocalSubtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.5,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Pill(text: l.iqdGram, color: c.gold, fontSize: 8),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: karats
                .map(
                  (k) => _KaratChip(
                    karat: k,
                    selected: k == karat,
                    label: l.en ? '${k}K' : 'عيار $k',
                    onTap: () => setState(() => _selected = k),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuoteTile(
                  label: l.localSellPrice,
                  hint: l.localSellHint,
                  value: l.number(q.ask),
                  unit: l.en ? 'IQD/g' : 'د.ع/غ',
                  color: c.gold,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuoteTile(
                  label: l.localBuyPrice,
                  hint: l.localBuyHint,
                  value: l.number(q.bid),
                  unit: l.en ? 'IQD/g' : 'د.ع/غ',
                  color: c.green,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _QuoteTile(
                  label: l.screenPrice,
                  hint: l.screenHint,
                  value: l.number(q.screen),
                  unit: l.en ? 'IQD/g' : 'د.ع/غ',
                  color: c.ink,
                  icon: Icons.monitor_rounded,
                  dense: true,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuoteTile(
                  label: l.localSpread,
                  hint: l.localSpreadHint,
                  value:
                      '${l.number(q.spread)} · ${l.percent(q.spreadPct, digits: 1)}',
                  unit: l.en ? 'IQD/g' : 'د.ع/غ',
                  color: c.red,
                  icon: Icons.swap_horiz_rounded,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.isEmpty ? l.localEstimateNote : note,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9,
              height: 1.55,
              color: c.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _KaratChip extends StatelessWidget {
  final int karat;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _KaratChip({
    required this.karat,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.gold.withValues(alpha: 0.16) : c.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? c.gold : c.border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? c.gold : c.muted,
          ),
        ),
      ),
    );
  }
}

class _QuoteTile extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final bool dense;

  const _QuoteTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: dense ? 13 : 15,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.15,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 8, color: c.muted),
          ),
          if (!dense)
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 8,
                color: c.muted,
              ),
            ),
        ],
      ),
    );
  }
}
