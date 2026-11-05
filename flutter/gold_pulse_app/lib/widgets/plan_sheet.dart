import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import 'common.dart';

Future<void> showPlanSheet(BuildContext context, AppState state) async {
  final analysis = state.analysis;
  if (analysis == null) return;
  final l = state.l;
  final c = AppColors.of(context);
  final plan = analysis.plan;
  final color = toneColor(analysis.tone, c);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.weeklyPlan,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Pill(text: analysis.actionLabel, color: color, filled: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.verdict,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PlanStat(
                      label: l.entryZone,
                      value: l.usdRange(plan.entryLow, plan.entryHigh),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PlanStat(
                      label: l.target1,
                      value: l.usd(plan.target1, digits: 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PlanStat(
                      label: l.stopLoss,
                      value: l.usd(plan.invalidation, digits: 0),
                      color: c.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.plan, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...plan.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.gold.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: c.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            height: 1.55,
                            color: c.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (plan.watch.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l.catalysts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...plan.watch
                    .take(5)
                    .map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.source} · ${item.categoryLabel} · ${item.sentimentLabel}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: c.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.riskNote,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          height: 1.5,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DisclaimerBox(label: l.disclaimer, text: analysis.disclaimer),
            ],
          );
        },
      );
    },
  );
}

class _PlanStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _PlanStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 10, color: c.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
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
