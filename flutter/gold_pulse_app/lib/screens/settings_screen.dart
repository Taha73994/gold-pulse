import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import '../widgets/rate_sheet.dart';
import 'alerts_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.settings),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                children: [
                  _Section(
                    title: l.language,
                    icon: Icons.translate_rounded,
                    child: _Segmented(
                      options: [(l.arabic, !state.en), (l.english, state.en)],
                      onTap: (index) =>
                          state.setLanguage(index == 0 ? 'ar' : 'en'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.theme,
                    icon: Icons.palette_outlined,
                    child: _Segmented(
                      options: [
                        (l.systemTheme, state.themeMode == ThemeMode.system),
                        (l.lightTheme, state.themeMode == ThemeMode.light),
                        (l.darkTheme, state.themeMode == ThemeMode.dark),
                      ],
                      onTap: (index) => state.setThemeMode(
                        index == 0
                            ? ThemeMode.system
                            : index == 1
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.autoRefresh,
                    icon: Icons.autorenew_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.autoRefreshNote,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: state.autoRefresh,
                          activeThumbColor: c.gold,
                          onChanged: state.setAutoRefresh,
                        ),
                      ],
                    ),
                  ),
                  _Section(
                    title: l.displayUnit,
                    icon: Icons.payments_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Segmented(
                          options: [
                            (l.usdUnit, !state.iqdMode),
                            (l.iqdUnit, state.iqdMode),
                          ],
                          onTap: (index) => state.setPriceUnit(index == 1),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          l.pick(
                            'الأونصة والمثقال والغرام تظهر بالعملة التي تختارها، محسوبة بسعر السوق الموازي.',
                            'Ounce, mithqal and gram are shown in your chosen currency, calculated at the parallel market rate.',
                          ),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            height: 1.5,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.alertSettings,
                    icon: Icons.notifications_active_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SwitchRow(
                          icon: state.alertSound
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          label: l.alertSound,
                          value: state.alertSound,
                          onChanged: state.setAlertSound,
                        ),
                        _SwitchRow(
                          icon: Icons.notifications_outlined,
                          label: l.notifications,
                          value: state.notificationsEnabled,
                          onChanged: (value) async {
                            final ok = await state.setNotifications(value);
                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.notificationsBlocked)),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.testAlert,
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 16,
                                ),
                                label: Text(l.testAlert),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AlertsScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.tune_rounded, size: 16),
                                label: Text(l.alertCenter),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Section(
                    title: l.privacy,
                    icon: Icons.privacy_tip_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.privacyNote,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            height: 1.6,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fingerprint_rounded,
                                size: 15,
                                color: c.gold,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  state.deviceId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
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
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => showRateSheet(context),
                    icon: const Icon(Icons.star_rounded, size: 17),
                    label: Text(l.rateApp),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                    icon: const Icon(Icons.shield_outlined, size: 17),
                    label: Text(l.privacyPolicy),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _reset(context, state),
                    icon: const Icon(Icons.restart_alt_rounded, size: 17),
                    label: Text(l.resetSettings),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.red,
                      side: BorderSide(color: c.red.withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${l.version} ${state.config.version} · ${l.developer}: ${l.owner}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
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
    );
  }

  Future<void> _reset(BuildContext context, AppState state) async {
    final l = state.l;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l.resetSettings,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Text(
          l.resetConfirm,
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.ok),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.resetSettings();
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: c.gold),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: value ? c.green : c.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: c.gold,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  final List<(String, bool)> options;
  final ValueChanged<int> onTap;

  const _Segmented({required this.options, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.asMap().entries.map((entry) {
          final active = entry.value.$2;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? c.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  entry.value.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF191305) : c.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
