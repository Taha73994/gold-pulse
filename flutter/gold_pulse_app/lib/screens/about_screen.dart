import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/owner_contact_card.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final presence = state.presence;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.aboutApp),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.gold.withValues(alpha: 0.32)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.surface, c.gold.withValues(alpha: 0.09)],
                      ),
                    ),
                    child: Column(
                      children: [
                        const GoldLogo(size: 64),
                        const SizedBox(height: 12),
                        Text(
                          l.appName,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        Text(
                          l.tagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Pill(
                          text: '${l.version} ${state.config.version}',
                          color: c.gold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.aboutText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            height: 1.75,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.insights_rounded,
                    title: l.methodology,
                    body: l.pick(
                      'إشارة مركّبة تجمع الاتجاه والمتوسطات وRSI وMACD والزخم مع الدولار وعوائد السندات ومخاطر السوق ومعنويات الأخبار. التوقعات الاحتمالية تُحسب بمحاكاة مونت كارلو على التقلب التاريخي، وهي احتمالات لا ضمانات.',
                      'A composite signal combining trend, moving averages, RSI, MACD and momentum with the dollar, bond yields, market risk and news sentiment. Probability forecasts use a Monte Carlo simulation on historical volatility — probabilities, not guarantees.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.storage_rounded,
                    title: l.dataSources,
                    body: l.dataSourcesText,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.people_alt_rounded,
                    title: l.activeUsers,
                    body:
                        '${l.onlineNow}: ${presence.onlineNow}\n'
                        '${l.activeToday}: ${presence.activeToday}\n'
                        '${l.totalUsers}: ${presence.totalUsers}\n\n'
                        '${l.usersNote}\n${l.publicStatsNote}',
                  ),
                  if (state.isOwner) ...[
                    const SizedBox(height: 10),
                    _OwnerUsersCard(state: state),
                  ],
                  if (state.ownerContact.hasAny) ...[
                    const SizedBox(height: 10),
                    OwnerContactCard(state: state),
                  ],
                  const SizedBox(height: 10),
                  _InfoCard(
                    icon: Icons.gavel_rounded,
                    title: l.disclaimer,
                    body: l.financialDisclaimer,
                  ),
                  const SizedBox(height: 10),
                  SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 18, color: c.gold),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            l.settings,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded, size: 18, color: c.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '${l.madeBy} ${l.owner}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          l.copyright,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.5,
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

class _OwnerUsersCard extends StatelessWidget {
  final AppState state;

  const _OwnerUsersCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final d = state.presenceDetails;
    String formatter(Map<String, int> map) => map.isEmpty
        ? '—'
        : map.entries
            .map((e) => '${e.key}: ${e.value}')
            .join(' · ');

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_person_rounded, size: 16, color: c.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.userDetails,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              Pill(text: l.ownerOnly, color: c.gold, fontSize: 8),
              IconButton(
                onPressed: state.loadPresenceDetails,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                tooltip: l.refresh,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            d == null
                ? l.usersLiveHint
                : '${l.activeWeek}: ${d.activeWeek} · ${l.activeMonth}: ${d.activeMonth}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              height: 1.65,
              color: c.ink,
            ),
          ),
          if (d != null) ...[
            const SizedBox(height: 6),
            _kv(l.platformsLabel, formatter(d.platforms), c),
            _kv(l.languagesLabel, formatter(d.locales), c),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
              icon: const Icon(Icons.dashboard_customize_outlined, size: 16),
              label: Text(l.dashboard),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String key, String value, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.5,
              color: c.muted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10.5,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: c.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    height: 1.7,
                    color: c.muted,
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
