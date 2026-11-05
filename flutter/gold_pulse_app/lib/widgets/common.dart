import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/l10n.dart';
import '../core/theme.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.notifier!;
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;
  final double radius;
  final Gradient? gradient;

  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.border,
    this.radius = 20,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    final wrapped = onTap == null
        ? content
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: content,
            ),
          );
    return margin == null ? wrapped : Padding(padding: margin!, child: wrapped);
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(0, 6, 0, 10),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: c.gold),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;
  final double fontSize;

  const Pill({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.filled = false,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: filled ? 0.9 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: fontSize + 2,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChangeChip extends StatelessWidget {
  final double value;
  final double? absolute;
  final L10n l;
  final bool large;

  const ChangeChip({
    super.key,
    required this.value,
    required this.l,
    this.absolute,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final up = value >= 0;
    final color = up ? c.green : c.red;
    final text = absolute == null
        ? l.percent(value, sign: true)
        : '${up ? '+' : ''}${l.number(absolute!, digits: 2)} (${l.percent(value, sign: true)})';
    // عزل الاتجاه حتى يظهر +104.50 (2.65%+) من اليسار لليمين داخل واجهة RTL.
    final display = '\u2066$text\u2069';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 11 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: large ? 16 : 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            display,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final String? hint;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: c.muted),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? c.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: c.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: c.gold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class DisclaimerBox extends StatelessWidget {
  final String text;
  final String label;

  const DisclaimerBox({super.key, required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surfaceAlt.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, size: 16, color: c.muted),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    height: 1.55,
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

class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final L10n l;
  final String? detail;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    required this.l,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: c.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 17, color: c.red),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l.connectionError} · $message',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    color: c.red,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail != null && detail!.isNotEmpty)
                  Text(
                    detail!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9.5,
                      color: c.red.withValues(alpha: 0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: c.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
            ),
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }
}

class LiveBadge extends StatefulWidget {
  final DateTime? at;
  final L10n l;
  final bool dense;

  const LiveBadge({
    super.key,
    required this.at,
    required this.l,
    this.dense = false,
  });

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> {
  Timer? _timer;
  bool _pulse = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _pulse = !_pulse);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _age(int seconds) {
    if (seconds < 60) {
      return widget.l.pick('قبل $seconds ث', '${seconds}s ago');
    }
    if (seconds < 3600) {
      return widget.l.pick('قبل ${seconds ~/ 60} د', '${seconds ~/ 60}m ago');
    }
    return widget.l.pick('قبل ${seconds ~/ 3600} س', '${seconds ~/ 3600}h ago');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final at = widget.at;
    final age = at == null ? null : DateTime.now().difference(at).inSeconds;
    final text = age == null
        ? widget.l.live
        : '${widget.l.live} · ${_age(age)}';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.dense ? 7 : 9,
        vertical: widget.dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: c.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.green.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: c.green.withValues(alpha: _pulse ? 1 : 0.35),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: widget.dense ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
              color: c.green,
            ),
          ),
        ],
      ),
    );
  }
}

class ImageBox extends StatelessWidget {
  final String url;
  final double height;
  final double radius;
  final IconData fallbackIcon;

  const ImageBox({
    super.key,
    required this.url,
    this.height = 140,
    this.radius = 16,
    this.fallbackIcon = Icons.storefront_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fallback = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.gold.withValues(alpha: 0.22), c.surfaceAlt],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(fallbackIcon, size: 34, color: c.gold.withValues(alpha: 0.8)),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surfaceAlt,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const LabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class GoldGlow extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const GoldGlow({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.gold.withValues(alpha: 0.32)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, c.gold.withValues(alpha: 0.08)],
        ),
        boxShadow: [
          BoxShadow(
            color: c.gold.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
