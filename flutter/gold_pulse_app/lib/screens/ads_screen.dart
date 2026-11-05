import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'shops_screen.dart' show launchUri, whatsappUrl;

class AdsScreen extends StatelessWidget {
  const AdsScreen({super.key});

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
            PageHeader(
              title: l.marketplace,
              subtitle: l.marketplaceSubtitle,
              actions: [
                if (state.isOwner)
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    icon: const Icon(Icons.add_box_outlined),
                    tooltip: l.postAd,
                  ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                color: c.gold,
                onRefresh: () async {
                  await Future.wait([state.loadAds(), state.loadPackages()]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                  children: [
                    if (state.isOwner) _AdvertiseBanner(l: l, state: state),
                    if (state.ads.isEmpty) ...[
                      const SizedBox(height: 14),
                      if (state.loadingAds)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30),
                            child: CircularProgressIndicator(color: c.gold),
                          ),
                        )
                      else
                        EmptyState(
                          icon: Icons.campaign_rounded,
                          title: l.noAds,
                          subtitle: l.noAdsHint,
                        ),
                    ] else ...[
                      const SizedBox(height: 16),
                      SectionHeader(
                        title: l.ads,
                        subtitle: '${state.ads.length} ${l.pick('إعلان', 'offers')}',
                        icon: Icons.local_offer_rounded,
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: state.ads.length,
                        itemBuilder: (context, i) => _AdCard(
                          ad: state.ads[i],
                          state: state,
                          onTap: () => _openAd(context, state.ads[i]),
                        ),
                      ),
                    ],
                    if (state.packages.isNotEmpty && state.isOwner) ...[
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: l.adPackages,
                        subtitle: l.advertiseSubtitle,
                        icon: Icons.workspace_premium_rounded,
                      ),
                      ...state.packages.map(
                        (p) => _PackageCard(package: p, state: state),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DisclaimerBox(
                      label: l.pick('تنبيه', 'Notice'),
                      text: l.adNote,
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

  void _openAd(BuildContext context, AdItem ad) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    state.adClick(ad.id);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
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
            ImageBox(
              url: state.api.mediaUrl(ad.imageUrl),
              height: 190,
              radius: 20,
              fallbackIcon: Icons.sell_rounded,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Pill(text: l.sponsored, color: c.gold, filled: true, fontSize: 8),
                Pill(text: ad.displayCategory(state.en), color: c.blue, fontSize: 9),
                if (ad.isFeatured) Pill(text: l.featured, color: c.amber, fontSize: 9),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ad.displayTitle(state.en),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ad.price > 0
                  ? '${l.number(ad.price)} ${ad.currency}'
                  : l.priceOnRequest,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: c.gold,
              ),
            ),
            if (ad.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.place_outlined, size: 13, color: c.muted),
                  const SizedBox(width: 4),
                  Text(
                    ad.city,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ],
            if (ad.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                ad.displayDescription(state.en),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  height: 1.7,
                  color: c.ink,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (ad.phone.isNotEmpty)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => launchUri('tel:${ad.phone}'),
                      icon: const Icon(Icons.call_rounded, size: 17),
                      label: Text(l.callNow),
                    ),
                  ),
                if (ad.phone.isNotEmpty && ad.whatsapp.isNotEmpty)
                  const SizedBox(width: 8),
                if (ad.whatsapp.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          launchUri(whatsappUrl(ad.whatsapp), web: true),
                      icon: const Icon(Icons.chat_rounded, size: 17),
                      label: Text(l.whatsapp),
                    ),
                  ),
              ],
            ),
            if (ad.link.isNotEmpty) ...[
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => launchUri(ad.link, web: true),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: Text(l.visitLink),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              l.adNote,
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
    );
  }
}

class _AdvertiseBanner extends StatelessWidget {
  final dynamic l;
  final AppState state;

  const _AdvertiseBanner({required this.l, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surface, c.gold.withValues(alpha: 0.12)],
        ),
        border: Border.all(color: c.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              size: 20,
              color: Color(0xFF1B1505),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.advertiseHere,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                Text(
                  l.advertiseSubtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    height: 1.45,
                    color: c.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            ),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            style: IconButton.styleFrom(
              backgroundColor: c.gold.withValues(alpha: 0.13),
              foregroundColor: c.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdItem ad;
  final AppState state;
  final VoidCallback onTap;

  const _AdCard({
    required this.ad,
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
                url: state.api.mediaUrl(ad.imageUrl),
                height: 104,
                radius: 18,
                fallbackIcon: Icons.sell_rounded,
              ),
              Positioned(
                top: 7,
                left: 7,
                child: Pill(
                  text: l.sponsored,
                  color: c.gold,
                  filled: true,
                  fontSize: 7,
                ),
              ),
              if (ad.daysLeft != null)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ad.daysLeft} ${l.pick('ي', 'd')}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.displayTitle(state.en),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ad.price > 0
                        ? '${l.number(ad.price)} ${ad.currency}'
                        : l.priceOnRequest,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: c.gold,
                    ),
                  ),
                  Text(
                    ad.city.isEmpty ? ad.displayCategory(state.en) : ad.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 9,
                      color: c.muted,
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

class _PackageCard extends StatelessWidget {
  final AdPackage package;
  final AppState state;

  const _PackageCard({required this.package, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = state.l;
    final perks = package.perks(state.en);
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.displayName(state.en),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              Text(
                l.iqd(package.priceIqd),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: c.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Pill(
                text: '${package.days} ${l.days}',
                color: c.blue,
                fontSize: 8,
              ),
              const SizedBox(width: 5),
              Pill(
                text: package.placement == 'home'
                    ? l.pick('الرئيسية', 'Home')
                    : l.pick('دليل المحلات', 'Shops'),
                color: c.amber,
                fontSize: 8,
              ),
              if (package.featured) ...[
                const SizedBox(width: 5),
                Pill(text: l.featured, color: c.gold, fontSize: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...perks.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 12, color: c.green),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      p,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10.5,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(l.postAd),
            ),
          ),
        ],
      ),
    );
  }
}
