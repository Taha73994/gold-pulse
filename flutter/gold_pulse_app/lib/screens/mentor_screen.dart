import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/forecast_card.dart';
import '../widgets/plan_sheet.dart';

class MentorScreen extends StatelessWidget {
  const MentorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final analysis = state.analysis;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.navMentor,
              subtitle: l.mentorSubtitle,
              showBack: false,
              actions: [
                LiveBadge(at: state.analysisUpdatedAt, l: l),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: state.loadingAnalysis ? null : state.loadAnalysis,
                  icon: state.loadingAnalysis
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
            Expanded(
              child: analysis == null
                  ? _MentorLoading(l: l, loading: state.loadingAnalysis)
                  : RefreshIndicator(
                      color: c.gold,
                      onRefresh: () async {
                        await Future.wait([
                          state.loadAnalysis(),
                          state.loadMarket(),
                          state.loadNews(),
                        ]);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                        children: [
                          if (state.lastError != null)
                            ErrorBanner(
                              message: state.lastError!,
                              onRetry: state.loadAnalysis,
                              l: l,
                            ),
                          _StanceCard(analysis: analysis, l: l),
                          const SizedBox(height: 14),
                          if (analysis.forecast.ok)
                            ForecastCard(forecast: analysis.forecast, l: l),
                          const SizedBox(height: 14),
                          _TimingCard(mentor: analysis.mentor, l: l),
                          if (analysis.mentor.keyLevels.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SectionHeader(
                              title: l.keyLevels,
                              icon: Icons.straighten_rounded,
                            ),
                            _LevelsList(levels: analysis.mentor.keyLevels, l: l),
                          ],
                          if (analysis.mentor.scenarios.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: l.scenarios,
                              subtitle: l.pick(
                                'خطة جاهزة لكل احتمال — لا تفاجئك الحركة.',
                                'A ready plan for each outcome — no surprises.',
                              ),
                              icon: Icons.alt_route_rounded,
                            ),
                            ...analysis.mentor.scenarios
                                .map((s) => _ScenarioCard(scenario: s, l: l)),
                          ],
                          if (analysis.mentor.weekly.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: l.weeklyPlan,
                              icon: Icons.event_note_rounded,
                            ),
                            _NumberedList(items: analysis.mentor.weekly, l: l),
                          ],
                          if (analysis.mentor.rules.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: l.rules,
                              icon: Icons.shield_outlined,
                            ),
                            _BulletList(
                              items: analysis.mentor.rules,
                              color: c.blue,
                              icon: Icons.check_circle_outline_rounded,
                              l: l,
                            ),
                          ],
                          if (analysis.mentor.checklist.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: l.checklist,
                              icon: Icons.task_alt_rounded,
                            ),
                            SurfaceCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Column(
                                children: analysis.mentor.checklist
                                    .map((check) => _CheckRow(check: check))
                                    .toList(),
                              ),
                            ),
                          ],
                          if (analysis.mentor.mistakes.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            SectionHeader(
                              title: l.mistakes,
                              icon: Icons.report_gmailerrorred_rounded,
                            ),
                            _BulletList(
                              items: analysis.mentor.mistakes,
                              color: c.red,
                              icon: Icons.close_rounded,
                              l: l,
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => showPlanSheet(context, state),
                            icon: const Icon(Icons.description_outlined, size: 17),
                            label: Text(l.pick('افتح خطة الأسبوع الكاملة', 'Open the full weekly plan')),
                          ),
                          const SizedBox(height: 14),
                          DisclaimerBox(
                            label: l.disclaimer,
                            text: analysis.mentor.disclaimer.isNotEmpty
                                ? analysis.mentor.disclaimer
                                : analysis.disclaimer,
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

class _MentorLoading extends StatelessWidget {
  final dynamic l;
  final bool loading;
  const _MentorLoading({required this.l, required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: c.gold),
          const SizedBox(height: 14),
          Text(
            loading ? l.loading : l.connectionError,
            style: TextStyle(fontFamily: 'Cairo', color: c.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StanceCard extends StatelessWidget {
  final Analysis analysis;
  final dynamic l;

  const _StanceCard({required this.analysis, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = toneColor(analysis.tone, c);
    final mentor = analysis.mentor;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, color.withValues(alpha: 0.09)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  size: 20,
                  color: Color(0xFF1B1505),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.todayStance,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.muted,
                      ),
                    ),
                    Text(
                      analysis.actionLabel,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l.conviction,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: c.muted,
                    ),
                  ),
                  Text(
                    mentor.conviction.isNotEmpty
                        ? mentor.conviction
                        : '${analysis.confidence}%',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mentor.headline.isNotEmpty ? mentor.headline : analysis.plan.verdict,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          if (mentor.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              mentor.note,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
                height: 1.65,
                color: c.ink,
              ),
            ),
          ],
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Pill(text: '${l.score} ${l.number(analysis.score, digits: 0)}', color: color),
              Pill(text: '${l.confidence} ${analysis.confidence}%', color: c.blue),
              Pill(text: analysis.regime, color: c.gold),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final Mentor mentor;
  final dynamic l;

  const _TimingCard({required this.mentor, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (mentor.timingNote.isEmpty) return const SizedBox.shrink();
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: c.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded, size: 17, color: c.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.timing,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: c.blue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  mentor.timingNote,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    height: 1.6,
                    color: c.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelsList extends StatelessWidget {
  final List<MentorLevel> levels;
  final dynamic l;

  const _LevelsList({required this.levels, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: levels.map((level) {
          final color = switch (level.type) {
            'support' => c.blue,
            'resistance' => c.amber,
            'stop' => c.red,
            'target' => c.green,
            _ => c.gold,
          };
          final price = level.priceHigh == null
              ? l.usd(level.price, digits: 0)
              : l.usdRange(level.price, level.priceHigh!);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level.label,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      if (level.note.isNotEmpty)
                        Text(
                          level.note,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            height: 1.4,
                            color: c.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
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

class _ScenarioCard extends StatelessWidget {
  final MentorScenario scenario;
  final dynamic l;

  const _ScenarioCard({required this.scenario, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.alt_route_rounded, size: 12, color: c.gold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scenario.title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _ScenarioRow(label: l.trigger, value: scenario.trigger, color: c.blue),
          _ScenarioRow(label: l.actionLabel, value: scenario.action, color: c.gold),
          _ScenarioRow(label: l.targetLabel, value: scenario.target, color: c.green),
          _ScenarioRow(label: l.riskLabel, value: scenario.risk, color: c.red),
        ],
      ),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScenarioRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
    );
  }
}

class _NumberedList extends StatelessWidget {
  final List<String> items;
  final dynamic l;
  const _NumberedList({required this.items, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.gold.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.key + 1}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
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
                      fontSize: 11.5,
                      height: 1.6,
                      color: c.ink,
                    ),
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

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  final IconData icon;
  final dynamic l;

  const _BulletList({
    required this.items,
    required this.color,
    required this.icon,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      height: 1.6,
                      color: c.ink,
                    ),
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

class _CheckRow extends StatelessWidget {
  final MentorCheck check;
  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            check.ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 15,
            color: check.ok ? c.green : c.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              check.text,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                height: 1.55,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
