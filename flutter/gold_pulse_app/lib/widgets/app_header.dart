import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../screens/admin_screen.dart';
import '../screens/alerts_screen.dart';
import 'common.dart';

class GoldLogo extends StatelessWidget {
  final double size;
  const GoldLogo({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD9AC45).withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class GoldHeader extends StatelessWidget {
  final Widget? leading;
  final bool compact;
  const GoldHeader({super.key, this.leading, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // على الشاشات الضيقة (≤ 380) نُخفي شارة التحديث لتظلّ الترويسة مقروءة.
        final narrow = constraints.maxWidth < 390;
        final logoSize = narrow ? 36.0 : 42.0;
        final buttonSize = narrow ? 34.0 : 38.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            narrow ? 12 : 16,
            8,
            narrow ? 12 : 16,
            4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              // ضغط مطوّل على الشعار = دخول المالك (مخفي عن المستخدم العادي).
              GestureDetector(
                onLongPress: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
                child: GoldLogo(size: logoSize),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l.appName,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: narrow ? 16 : (compact ? 17 : 19),
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!narrow) ...[
                          const SizedBox(width: 7),
                          LiveBadge(
                            at: state.marketUpdatedAt,
                            l: l,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    if (!compact)
                      Text(
                        l.tagline,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: narrow ? 9.5 : 10.5,
                          color: c.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _RoundButton(
                label: state.en ? 'ع' : 'EN',
                onTap: () => state.setLanguage(state.en ? 'ar' : 'en'),
                tooltip: l.language,
                size: buttonSize,
              ),
              const SizedBox(width: 5),
              _RoundButton(
                icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: () =>
                    state.setThemeMode(dark ? ThemeMode.light : ThemeMode.dark),
                tooltip: l.theme,
                size: buttonSize,
              ),
              const SizedBox(width: 5),
              _NotificationButton(count: state.activeUnread, size: buttonSize),
            ],
          ),
        );
      },
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  const _RoundButton({
    this.label,
    this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  )
                : Icon(icon, size: 18, color: c.ink),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final double size;
  const _NotificationButton({required this.count, this.size = 38});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Tooltip(
      message: AppScope.of(context).l.alerts,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 19, color: c.ink),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 14),
                      decoration: BoxDecoration(
                        color: c.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
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

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: c.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
