import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

enum _AlertFilter { all, unread, price, signal, rate, momentum, forecast }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter _filter = _AlertFilter.all;

  bool _matches(AlertItem a) {
    switch (_filter) {
      case _AlertFilter.all:
        return true;
      case _AlertFilter.unread:
        return !a.isRead;
      case _AlertFilter.price:
        return a.kind == 'price';
      case _AlertFilter.signal:
        return a.kind == 'signal';
      case _AlertFilter.rate:
        return a.kind == 'rate';
      case _AlertFilter.momentum:
        return a.kind == 'momentum';
      case _AlertFilter.forecast:
        return a.kind == 'forecast';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final payload = state.alertsData;
    final all = [...(payload?.items ?? const <AlertItem>[])]
      ..sort((a, b) => b.id.compareTo(a.id));
    final alerts = all.where(_matches).toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.alertCenter,
              subtitle: payload == null
                  ? null
                  : '${payload.unread} ${l.unread} · ${all.length} ${l.allKinds}',
              actions: [
                if ((payload?.unread ?? 0) > 0)
                  TextButton(
                    onPressed: state.markAllAlertsRead,
                    child: Text(l.markAllRead),
                  ),
                IconButton(
                  onPressed: state.loadingAlerts ? null : state.loadAlerts,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l.refresh,
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                notificationPredicate: (_) => false,
                onRefresh: () => state.loadAlerts(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  children: [
                    _AlertHero(state: state),
                    const SizedBox(height: 12),
                    _FilterRow(
                      selected: _filter,
                      onSelect: (f) => setState(() => _filter = f),
                      unread: payload?.unread ?? 0,
                    ),
                    const SizedBox(height: 12),
                    if (state.lastError != null)
                      ErrorBanner(
                        message: state.lastError!,
                        onRetry: () => state.loadAlerts(),
                        l: l,
                      ),
                    if (alerts.isEmpty)
                      EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: all.isEmpty ? l.noAlerts : l.noFilterResults,
                        subtitle: all.isEmpty ? l.noAlertsHint : l.alertTipGold,
                      )
                    else
                      ...alerts.map(
                        (alert) => _AlertCard(
                          alert: alert,
                          state: state,
                          onTap: () => _openAlert(context, alert, state),
                        ),
                      ),
                    if ((payload?.signalHistory ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: l.signalHistory,
                        icon: Icons.history_rounded,
                      ),
                      _HistoryCard(points: payload!.signalHistory, l: l),
                    ],
                    const SizedBox(height: 16),
                    DisclaimerBox(
                      label: l.disclaimer,
                      text: state.config.disclaimer.isNotEmpty
                          ? state.config.disclaimer
                          : l.financialDisclaimer,
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

  void _openAlert(BuildContext context, AlertItem alert, AppState state) {
    if (!alert.isRead) state.markAlertRead(alert.id);
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertSheet(alert: alert, state: state),
    );
  }
}

// ── البطاقة الذهبية العلوية ──────────────────────────────
class _AlertHero extends StatelessWidget {
  final AppState state;
  const _AlertHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final m = state.market;
    final iqd = state.iqdMode;
    final goldText = m == null ? '—' : l.priceCompact(m.ounceIn(iqd), iqd: iqd);
    final rateText = m == null ? '—' : l.number(m.parallelRate, digits: 1);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.gold.withValues(alpha: 0.40)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.gold.withValues(alpha: 0.22),
            c.surface,
            c.gold.withValues(alpha: 0.06),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: c.gold.withValues(alpha: 0.10),
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          PositionedDirectional(
            end: -18,
            bottom: -24,
            child: Opacity(
              opacity: 0.13,
              child: Image.asset(
                'assets/images/alert_bell.png',
                width: 150,
                height: 150,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 20,
                        color: c.gold,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.alertsHeroTitle,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            l.alertsHeroHint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.5,
                              height: 1.45,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pill(
                      text: l.alertsLive,
                      color: c.green,
                      icon: Icons.circle,
                      fontSize: 8,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: l.unread,
                        value: '${state.unreadAlerts}',
                        color: c.amber,
                        icon: Icons.mark_email_unread_rounded,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeroStat(
                        label: l.goldNow,
                        value: goldText,
                        color: c.gold,
                        icon: Icons.workspace_premium_rounded,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _HeroStat(
                        label: l.rateNow,
                        value: rateText,
                        color: c.blue,
                        icon: Icons.currency_exchange_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniToggle(
                      icon: state.alertSound
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      label: l.alertSound,
                      active: state.alertSound,
                      onTap: () => state.setAlertSound(!state.alertSound),
                    ),
                    const SizedBox(width: 6),
                    _MiniToggle(
                      icon: state.notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      label: l.notifications,
                      active: state.notificationsEnabled,
                      onTap: () async {
                        final ok = await state.setNotifications(
                          !state.notificationsEnabled,
                        );
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.notificationsBlocked)),
                          );
                        }
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _AlertPrefsSheet(state: state),
                      ),
                      icon: Icon(Icons.tune_rounded, size: 18, color: c.muted),
                      tooltip: l.alertSettings,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 8,
                    color: c.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
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

class _MiniToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = active ? c.green : c.muted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── الفلاتر ──────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final _AlertFilter selected;
  final ValueChanged<_AlertFilter> onSelect;
  final int unread;

  const _FilterRow({
    required this.selected,
    required this.onSelect,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final items = <(_AlertFilter, String, int?)>[
      (_AlertFilter.all, l.allKinds, null),
      (_AlertFilter.unread, l.unreadOnly, unread > 0 ? unread : null),
      (_AlertFilter.price, l.priceAlert, null),
      (_AlertFilter.signal, l.signalAlert, null),
      (_AlertFilter.rate, l.rateAlert, null),
      (_AlertFilter.momentum, l.momentumAlert, null),
      (_AlertFilter.forecast, l.kind('forecast'), null),
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final item = items[i];
          final active = item.$1 == selected;
          return GestureDetector(
            onTap: () => onSelect(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? c.gold : c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? c.gold : c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: active ? const Color(0xFF191305) : c.muted,
                    ),
                  ),
                  if (item.$3 != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF191305).withValues(alpha: 0.16)
                            : c.red.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.$3}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: active ? const Color(0xFF191305) : c.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── بطاقة تنبيه ─────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  final AppState state;
  final VoidCallback onTap;

  const _AlertCard({
    required this.alert,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final color = _severityColor(alert.severity, c);
    final icon = _kindIcon(alert.kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: alert.isRead ? c.border : color.withValues(alpha: 0.50),
          width: alert.isRead ? 1 : 1.4,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: alert.isRead ? 0.35 : 1),
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(17),
                      bottomStart: Radius.circular(17),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 16, color: color),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Row(
                            children: [
                              if (!alert.isRead)
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  alert.displayTitle(state.en),
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: alert.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_left_rounded,
                          size: 16,
                          color: c.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.displayBody(state.en),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        height: 1.55,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Pill(
                          text: l.kind(alert.kind),
                          color: color,
                          fontSize: 8,
                        ),
                        if (alert.action.isNotEmpty)
                          Pill(
                            text: l.action(alert.action),
                            color: toneColor(
                              alert.action == 'BUY'
                                  ? 'green'
                                  : alert.action == 'SELL'
                                  ? 'red'
                                  : 'orange',
                              c,
                            ),
                            fontSize: 8,
                          ),
                        Text(
                          l.timeAgo(alert.createdAt),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _severityColor(String severity, AppColors c) {
  switch (severity) {
    case 'high':
      return c.red;
    case 'medium':
      return c.amber;
    default:
      return c.blue;
  }
}

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'forecast':
      return Icons.insights_rounded;
    case 'signal':
      return Icons.radar_rounded;
    case 'price':
      return Icons.show_chart_rounded;
    case 'momentum':
      return Icons.speed_rounded;
    case 'rate':
      return Icons.currency_exchange_rounded;
    default:
      return Icons.info_outline_rounded;
  }
}

// ── تفاصيل التنبيه ──────────────────────────────────────
class _AlertSheet extends StatelessWidget {
  final AlertItem alert;
  final AppState state;

  const _AlertSheet({required this.alert, required this.state});

  String _why(AppState state) {
    final l = state.l;
    switch (alert.kind) {
      case 'rate':
        return l.alertTipRate;
      case 'signal':
        return l.pick(
          'تغيّر الإشارة يعني أن موازين المخاطرة والعائد تغيّرت. القرار يعتمد على خطتك لا على التنبيه وحده.',
          'A signal change means the risk/reward balance moved. Act on your plan, not on the alert alone.',
        );
      case 'momentum':
        return l.pick(
          'الزخم يقيس سرعة الحركة. الزخم القوي قد يستمر أو ينعكس سريعاً، لذا راقب التأكيد.',
          'Momentum measures the speed of the move. Strong momentum can extend or reverse quickly, so wait for confirmation.',
        );
      case 'forecast':
        return l.pick(
          'التوقع احتمالي وليس وعداً. استخدمه لتحديد النطاقات لا للدخول بكل رأس المال.',
          'A forecast is probabilistic, not a promise. Use it to set ranges, not to commit all your capital.',
        );
      case 'price':
        return l.pick(
          'حركة السعر وحدها لا تكفي. تحقق من سبب الحركة ومن سعر الصرف الموازي قبل الشراء أو البيع.',
          'Price movement alone is not enough. Check the reason and the parallel exchange rate before buying or selling.',
        );
      default:
        return l.alertTipGold;
    }
  }

  String _action(AppState state) {
    final l = state.l;
    switch (alert.action) {
      case 'BUY':
        return l.pick(
          'ادخل على دفعات، واحتفظ بجزء من السيولة، وحدد وقف الخسارة قبل الشراء.',
          'Enter in stages, keep part of your cash, and set your stop before buying.',
        );
      case 'SELL':
        return l.pick(
          'راجع وقف الخسارة وقلّل التعرض تدريجياً بدل البيع كاملاً بضغطة واحدة.',
          'Review your stop and reduce exposure gradually instead of selling everything at once.',
        );
      case 'REDUCE':
        return l.pick(
          'خفّف المراكز الضعيفة واحتفظ بالمراكز القوية، وراجع مستوى الدعم.',
          'Trim weak positions, keep the strong ones, and watch the support level.',
        );
      case 'ACCUMULATE':
        return l.pick(
          'اجمع على دفعات قرب مناطق الدعم ولا تلاحق السعر بعد ارتفاعه.',
          'Accumulate near support in stages and do not chase the price after a rally.',
        );
      default:
        return l.pick(
          'راقب السعر وسعر الصرف، ولا تتحرك قبل ظهور تأكيد واضح.',
          'Watch the price and the exchange rate, and wait for clear confirmation.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final color = _severityColor(alert.severity, c);
    final iqd = state.iqdMode;
    final m = state.market;
    final alertPrice = alert.price > 0 && m != null && m.parallelRate > 0
        ? l.priceText(
            iqd ? alert.price * m.parallelRate : alert.price,
            iqd: iqd,
            digits: iqd ? 0 : 2,
          )
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: c.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 26),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _kindIcon(alert.kind),
                          size: 24,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                Pill(
                                  text: l.kind(alert.kind),
                                  color: color,
                                  fontSize: 9,
                                ),
                                Pill(
                                  text: alert.severity == 'high'
                                      ? l.severityHigh
                                      : alert.severity == 'medium'
                                      ? l.severityMedium
                                      : l.severityInfo,
                                  color: color,
                                  fontSize: 9,
                                ),
                                if (alert.action.isNotEmpty)
                                  Pill(
                                    text: l.action(alert.action),
                                    color: toneColor(
                                      alert.action == 'BUY'
                                          ? 'green'
                                          : alert.action == 'SELL'
                                          ? 'red'
                                          : 'orange',
                                      c,
                                    ),
                                    fontSize: 9,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.dateShort(alert.createdAt),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 9.5,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    alert.displayTitle(state.en),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 19,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.displayBody(state.en),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      height: 1.75,
                      color: c.ink.withValues(alpha: 0.88),
                    ),
                  ),
                  if (alertPrice != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: c.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: c.gold.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: c.gold,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l.priceAtAlert,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: c.muted,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            alertPrice,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _InfoBlock(
                    title: l.whyItMatters,
                    text: _why(state),
                    icon: Icons.lightbulb_outline_rounded,
                    color: c.amber,
                  ),
                  const SizedBox(height: 9),
                  _InfoBlock(
                    title: l.whatToDo,
                    text: _action(state),
                    icon: Icons.checklist_rounded,
                    color: c.green,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: c.gold,
                            foregroundColor: const Color(0xFF191305),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            l.understood,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text:
                                  '${alert.displayTitle(state.en)}\n${alert.displayBody(state.en)}',
                            ),
                          );
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l.copied)));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        tooltip: l.copy,
                      ),
                    ],
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

class _InfoBlock extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _InfoBlock({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              height: 1.7,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── إعدادات التنبيهات ───────────────────────────────────
class _AlertPrefsSheet extends StatefulWidget {
  final AppState state;
  const _AlertPrefsSheet({required this.state});

  @override
  State<_AlertPrefsSheet> createState() => _AlertPrefsSheetState();
}

class _AlertPrefsSheetState extends State<_AlertPrefsSheet> {
  final TextEditingController _target = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.state.targetOunceIqd;
    if (t != null) _target.text = t.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  Future<void> _saveTarget() async {
    final raw = _target.text.replaceAll(',', '').replaceAll(' ', '');
    final value = double.tryParse(raw);
    if (raw.isEmpty) {
      await widget.state.setTargetOunce(null);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (value == null || value < 10000 || value > 100000000) {
      setState(
        () => _error = widget.state.l.pick(
          'أدخل سعراً صحيحاً بالأونصة (مثال: 7000000).',
          'Enter a valid ounce price (example: 7,000,000).',
        ),
      );
      return;
    }
    await widget.state.setTargetOunce(value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = state.l;
    final c = AppColors.of(context);
    final current = state.targetOunceIqd;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: c.border),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: c.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: c.gold),
                    const SizedBox(width: 7),
                    Text(
                      l.alertSettings,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PrefSwitch(
                  icon: state.alertSound
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  title: l.alertSound,
                  subtitle: l.alertSoundNote,
                  value: state.alertSound,
                  onChanged: state.setAlertSound,
                ),
                const SizedBox(height: 8),
                _PrefSwitch(
                  icon: Icons.notifications_active_rounded,
                  title: l.notifications,
                  subtitle: l.notificationsNote,
                  value: state.notificationsEnabled,
                  onChanged: (v) async {
                    final ok = await state.setNotifications(v);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.notificationsBlocked)),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                Divider(color: c.border, height: 1),
                const SizedBox(height: 14),
                Text(
                  l.targetPrice,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.targetPriceNote,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    height: 1.55,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _error == null ? c.border : c.red,
                    ),
                  ),
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '7,000,000',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: c.muted.withValues(alpha: 0.6),
                      ),
                      suffixText: l.en ? 'IQD' : 'د.ع',
                      suffixStyle: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: c.muted,
                      ),
                    ),
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: c.red,
                    ),
                  ),
                ],
                if (current != null && current > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${l.targetPrice}: ${l.moneyIqd(current)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: c.gold,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.gold,
                          foregroundColor: const Color(0xFF191305),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _saveTarget,
                        icon: const Icon(Icons.flag_rounded, size: 16),
                        label: Text(
                          l.setTarget,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    OutlinedButton(
                      onPressed: () async {
                        await state.setTargetOunce(null);
                        _target.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.clearTarget)),
                          );
                        }
                      },
                      child: Text(l.clearTarget),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: state.testAlert,
                    icon: const Icon(Icons.volume_up_rounded, size: 17),
                    label: Text(l.testAlert),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12, color: c.muted),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l.notificationsBlocked,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 9,
                          height: 1.5,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrefSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrefSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: value ? c.green : c.muted),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9,
                    height: 1.45,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: c.gold,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ── سجل الإشارات ────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final List<SignalHistoryPoint> points;
  final dynamic l;

  const _HistoryCard({required this.points, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      child: Column(
        children: points.take(12).map((p) {
          final up = p.action == 'BUY' || p.action == 'ACCUMULATE';
          final down = p.action == 'SELL' || p.action == 'REDUCE';
          final color = up
              ? c.green
              : down
              ? c.red
              : c.amber;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.actionLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ),
                Text(
                  l.usd(p.price, digits: 0),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: c.muted,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l.dateShort(p.createdAt),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
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
