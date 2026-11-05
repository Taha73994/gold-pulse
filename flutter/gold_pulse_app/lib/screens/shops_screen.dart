import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';

class ShopsScreen extends StatefulWidget {
  const ShopsScreen({super.key});

  @override
  State<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends State<ShopsScreen> {
  final _search = TextEditingController();
  String _city = '';
  bool _featuredOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final state = AppScope.of(context);
    state.loadShops(q: _search.text.trim(), city: _city);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final shops = state.shops;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.shopsDirectory,
              subtitle: l.shopsSubtitle,
              showBack: false,
              actions: [
                if (state.isOwner)
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    icon: const Icon(Icons.add_business_rounded),
                    tooltip: l.addYourShop,
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                onChanged: (_) => _load(),
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                decoration: InputDecoration(
                  hintText: l.searchShops,
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            _load();
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CityChip(
                    label: l.allCities,
                    active: _city.isEmpty,
                    onTap: () {
                      setState(() => _city = '');
                      _load();
                    },
                  ),
                  _CityChip(
                    label: l.featured,
                    active: _featuredOnly,
                    icon: Icons.star_rounded,
                    onTap: () {
                      setState(() => _featuredOnly = !_featuredOnly);
                      _load();
                    },
                  ),
                  ...state.shopCities.map(
                    (city) => _CityChip(
                      label: city.display(state.en),
                      active: _city == city.city,
                      onTap: () {
                        setState(() => _city = city.city);
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                onRefresh: () async {
                  await Future.wait([state.loadShops(), state.loadShopCities()]);
                },
                child: shops.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (state.loadingShops)
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Center(
                                child: CircularProgressIndicator(color: c.gold),
                              ),
                            )
                          else
                            EmptyState(
                              icon: Icons.storefront_rounded,
                              title: l.noShops,
                              subtitle: l.noShopsHint,
                            ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 26),
                        itemCount: shops.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ShopCard(
                          shop: shops[i],
                          state: state,
                          onTap: () => _openShop(context, shops[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openShop(BuildContext context, Shop shop) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShopDetailScreen(shop: shop)),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  const _CityChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: active ? c.gold : c.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: active ? c.gold : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: active ? const Color(0xFF191305) : c.gold,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF191305) : c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final AppState state;
  final VoidCallback onTap;

  const _ShopCard({
    required this.shop,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ImageBox(
                url: state.api.mediaUrl(shop.imageUrl),
                height: 132,
                radius: 20,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  children: [
                    if (shop.isFeatured)
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Pill(
                          text: l.featured,
                          color: c.gold,
                          filled: true,
                          fontSize: 8,
                          icon: Icons.star_rounded,
                        ),
                      ),
                    if (shop.isVerified)
                      Pill(
                        text: l.verified,
                        color: c.green,
                        filled: true,
                        fontSize: 8,
                        icon: Icons.verified_rounded,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.displayName(state.en),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 12, color: c.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '${shop.displayCity(state.en)} · ${shop.displayAddress(state.en)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10.5,
                          color: c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                if (shop.workingHours.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: c.muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shop.workingHours,
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
                ],
                if (shop.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    shop.displayDescription(state.en),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10.5,
                      height: 1.5,
                      color: c.ink,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (shop.phone.isNotEmpty)
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.call_rounded,
                          label: l.call,
                          onTap: () => launchUri('tel:${shop.phone}'),
                        ),
                      ),
                    if (shop.phone.isNotEmpty && shop.whatsapp.isNotEmpty)
                      const SizedBox(width: 7),
                    if (shop.whatsapp.isNotEmpty)
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.chat_rounded,
                          label: l.whatsapp,
                          color: c.green,
                          onTap: () => launchUri(
                            whatsappUrl(shop.whatsapp),
                            web: true,
                          ),
                        ),
                      ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.map_rounded,
                        label: l.map,
                        color: c.blue,
                        onTap: () => launchUri(mapUrlFor(shop)),
                      ),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tone = color ?? c.gold;
    return Material(
      color: tone.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: tone),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  const ShopDetailScreen({super.key, required this.shop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Shop _shop = widget.shop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final fresh = await AppScope.of(context).api.shop(_shop.id);
        if (mounted) setState(() => _shop = fresh);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final shop = _shop;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.shopDetails),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  ImageBox(
                    url: state.api.mediaUrl(shop.imageUrl),
                    height: 190,
                    radius: 22,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.displayName(state.en),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${shop.displayCity(state.en)} · ${shop.displayAddress(state.en)}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (shop.isVerified)
                        Pill(
                          text: l.verified,
                          color: c.green,
                          filled: true,
                          icon: Icons.verified_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      if (shop.isFeatured)
                        Pill(text: l.featured, color: c.gold),
                      Pill(
                        text: '${l.views} ${l.number(shop.views)}',
                        color: c.blue,
                      ),
                    ],
                  ),
                  if (shop.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SurfaceCard(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        shop.displayDescription(state.en),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          height: 1.7,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.call_outlined,
                          label: l.phone,
                          value: shop.phone.isEmpty ? l.noPhone : shop.phone,
                          onTap: shop.phone.isEmpty
                              ? null
                              : () => launchUri('tel:${shop.phone}'),
                        ),
                        _InfoRow(
                          icon: Icons.chat_outlined,
                          label: l.whatsapp,
                          value: shop.whatsapp.isEmpty ? '—' : shop.whatsapp,
                          onTap: shop.whatsapp.isEmpty
                              ? null
                              : () => launchUri(
                                    whatsappUrl(shop.whatsapp),
                                    web: true,
                                  ),
                        ),
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: l.address,
                          value: shop.displayAddress(state.en),
                          onTap: () => launchUri(mapUrlFor(shop)),
                        ),
                        _InfoRow(
                          icon: Icons.schedule_outlined,
                          label: l.workingHours,
                          value: shop.workingHours.isEmpty ? '—' : shop.workingHours,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (shop.phone.isNotEmpty) ...[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => launchUri('tel:${shop.phone}'),
                            icon: const Icon(Icons.call_rounded, size: 17),
                            label: Text(l.callNow),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (shop.whatsapp.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => launchUri(
                              whatsappUrl(shop.whatsapp),
                              web: true,
                            ),
                            icon: const Icon(Icons.chat_rounded, size: 17),
                            label: Text(l.whatsapp),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => launchUri(mapUrlFor(shop)),
                      icon: const Icon(Icons.map_rounded, size: 17),
                      label: Text(l.openMap),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DisclaimerBox(
                    label: l.pick('ملاحظة', 'Note'),
                    text: l.pick(
                      'تحقق من سعر اليوم والوزن والعيار قبل الشراء. بيانات المحل يضيفها المالك.',
                      'Confirm today\'s rate, weight and karat before buying. Shop details are supplied by the owner.',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.gold),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 9.5,
                    color: c.muted,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (onTap != null)
              Icon(Icons.chevron_left_rounded, size: 17, color: c.muted),
          ],
        ),
      ),
    );
  }
}

Future<void> launchUri(String url, {bool web = false}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(
      uri,
      mode: web ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
  } catch (_) {}
}

String whatsappUrl(String raw) {
  var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '964${digits.substring(1)}';
  if (digits.length == 10 && digits.startsWith('7')) digits = '964$digits';
  return 'https://wa.me/$digits';
}

String mapUrlFor(Shop shop) {
  if (shop.mapUrl.isNotEmpty) return shop.mapUrl;
  if (shop.latitude != 0 || shop.longitude != 0) {
    return 'https://www.google.com/maps/search/?api=1&query=${shop.latitude},${shop.longitude}';
  }
  final query = Uri.encodeComponent(
    '${shop.name} ${shop.city} ${shop.address}'.trim(),
  );
  return 'https://www.google.com/maps/search/?api=1&query=$query';
}
