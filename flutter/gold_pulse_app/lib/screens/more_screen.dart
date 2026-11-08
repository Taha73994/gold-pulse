import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/owner_contact_card.dart';
import '../widgets/rate_sheet.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'ads_screen.dart';
import 'alerts_screen.dart';
import 'calculator_screen.dart';
import 'currency_screen.dart';
import 'news_screen.dart';
import 'privacy_screen.dart';
import 'settings_screen.dart';
import 'zakat_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    final tools = <(IconData, String, VoidCallback)>[
      (
        Icons.calculate_rounded,
        l.calculator,
        () => _push(context, const CalculatorScreen()),
      ),
      (
        Icons.currency_exchange_rounded,
        l.currencies,
        () => _push(context, const CurrencyScreen()),
      ),
      (
        Icons.volunteer_activism_rounded,
        l.pick('زكاة الذهب', 'Gold zakat'),
        () => _push(context, const ZakatScreen()),
      ),
      (
        Icons.newspaper_rounded,
        l.news,
        () => _push(context, const NewsScreen()),
      ),
      (
        Icons.notifications_active_outlined,
        l.alerts,
        () => _push(context, const AlertsScreen()),
      ),
      (Icons.campaign_rounded, l.ads, () => _push(context, const AdsScreen())),
      (Icons.star_rounded, l.rateApp, () => showRateSheet(context)),
      (
        Icons.privacy_tip_outlined,
        l.privacyPolicy,
        () => _push(context, const PrivacyScreen()),
      ),
      (
        Icons.settings_outlined,
        l.settings,
        () => _push(context, const SettingsScreen()),
      ),
      (
        Icons.info_outline_rounded,
        l.about,
        () => _push(context, const AboutScreen()),
      ),
      // لوحة المالك لا تظهر إلا لمن سجّل دخوله برمز المالك.
      if (state.isOwner)
        (
          Icons.admin_panel_settings_outlined,
          l.admin,
          () => _push(context, const AdminScreen()),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 26),
          children: [
            const GoldHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SectionHeader(
                    title: l.tools,
                    subtitle: l.pick(
                      'كل ما تحتاجه في مكان واحد.',
                      'Everything you need, in one place.',
                    ),
                    icon: Icons.grid_view_rounded,
                  ),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.92,
                    children: tools
                        .map(
                          (tool) => _ToolTile(
                            icon: tool.$1,
                            label: tool.$2,
                            onTap: tool.$3,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(title: l.settings, icon: Icons.tune_rounded),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.language_rounded,
                          label: l.language,
                          value: state.en ? l.english : l.arabic,
                          onTap: () =>
                              state.setLanguage(state.en ? 'ar' : 'en'),
                        ),
                        Divider(color: c.border, height: 1),
                        _SettingRow(
                          icon: Icons.dark_mode_outlined,
                          label: l.theme,
                          value: switch (state.themeMode) {
                            ThemeMode.light => l.lightTheme,
                            ThemeMode.system => l.systemTheme,
                            _ => l.darkTheme,
                          },
                          onTap: () => state.setThemeMode(
                            state.themeMode == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          ),
                        ),
                        Divider(color: c.border, height: 1),
                        _SettingRow(
                          icon: Icons.autorenew_rounded,
                          label: l.autoRefresh,
                          value: state.autoRefresh ? l.yes : l.no,
                          onTap: () => state.setAutoRefresh(!state.autoRefresh),
                        ),
                        Divider(color: c.border, height: 1),
                        _SettingRow(
                          icon: Icons.people_alt_outlined,
                          label: l.activeUsers,
                          value: '${state.presence.totalUsers}',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AboutScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.ownerContact.hasAny) ...[
                    const SizedBox(height: 12),
                    OwnerContactCard(state: state),
                  ],
                  if (state.isOwner) ...[
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: l.community,
                      icon: Icons.handshake_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_business_rounded,
                            label: l.addYourShop,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.campaign_outlined,
                            label: l.postAd,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminScreen(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
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

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolTile({
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: c.gold),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 17, color: c.gold),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: c.muted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_left_rounded, size: 16, color: c.muted),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 22, color: c.gold),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
