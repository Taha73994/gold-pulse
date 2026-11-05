import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final payload = state.alertsData;
    final alerts = payload?.items ?? const <AlertItem>[];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.alertCenter,
              subtitle: payload == null
                  ? null
                  : '${payload.unread} ${l.unread}',
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
                onRefresh: () => state.loadAlerts(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  children: [
                    _GuideCard(l: l),
                    const SizedBox(height: 14),
                    if (alerts.isEmpty)
                      EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: l.noAlerts,
                        subtitle: l.noAlertsHint,
                      )
                    else
                      ...alerts.map(
                        (alert) => _AlertCard(
                          alert: alert,
                          state: state,
                          onTap: () {
                            if (!alert.isRead) state.markAlertRead(alert.id);
                            _showAlert(context, alert, state);
                          },
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

  void _showAlert(BuildContext context, AlertItem alert, AppState state) {
    final l = state.l;
    final c = AppColors.of(context);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          alert.displayTitle(state.en),
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, height: 1.4),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.displayBody(state.en),
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 10),
            Text(
              '${l.kind(alert.kind)} · ${l.dateShort(alert.createdAt)}',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: c.muted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final dynamic l;
  const _GuideCard({required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = [l.alertGuide1, l.alertGuide2, l.alertGuide3];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.gold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: c.gold),
              const SizedBox(width: 7),
              Text(
                l.alertGuide,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: c.gold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        height: 1.55,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    final color = alert.severity == 'high'
        ? c.red
        : alert.severity == 'medium'
            ? c.amber
            : c.blue;
    final icon = switch (alert.kind) {
      'forecast' => Icons.insights_rounded,
      'signal' => Icons.radar_rounded,
      'price' => Icons.show_chart_rounded,
      'momentum' => Icons.speed_rounded,
      _ => Icons.info_outline_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: alert.isRead ? c.surface : c.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: alert.isRead
              ? c.border
              : color.withValues(alpha: 0.45),
          width: alert.isRead ? 1 : 1.4,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!alert.isRead)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 5),
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
                                height: 1.45,
                                fontWeight:
                                    alert.isRead ? FontWeight.w600 : FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.displayBody(state.en),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          height: 1.55,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Pill(
                            text: l.kind(alert.kind),
                            color: color,
                            fontSize: 8,
                          ),
                          if (alert.action.isNotEmpty) ...[
                            const SizedBox(width: 5),
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
                          ],
                          const Spacer(),
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
      ),
    );
  }
}

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
          final color = up ? c.green : down ? c.red : c.amber;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
