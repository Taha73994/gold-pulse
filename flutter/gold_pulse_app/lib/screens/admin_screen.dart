import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.of(context);
      if (state.adminPin.isNotEmpty && state.adminStats == null) {
        state.loadAdminData();
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await state.adminLogin(_pin.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _error = state.l.wrongPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);

    if (state.adminPin.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PageHeader(title: l.ownerLogin),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const GoldLogo(size: 64),
                      const SizedBox(height: 18),
                      Text(
                        l.ownerLogin,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l.pinHint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _pin,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _login(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                        decoration: InputDecoration(
                          hintText: l.enterPin,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _login,
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l.login),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.pinStored,
                        textAlign: TextAlign.center,
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
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              PageHeader(
                title: l.dashboard,
                subtitle: '${l.owner}: ${l.owner}',
                actions: [
                  IconButton(
                    onPressed: state.loadingAdmin ? null : state.loadAdminData,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: l.refresh,
                  ),
                  IconButton(
                    onPressed: state.logoutAdmin,
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: l.logout,
                  ),
                ],
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: c.gold,
                unselectedLabelColor: c.muted,
                indicatorColor: c.gold,
                labelStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: l.overview),
                  Tab(text: l.manageShops),
                  Tab(text: l.manageAds),
                  Tab(text: l.contactTab),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(state: state),
                    _ShopsTab(state: state),
                    _AdsTab(state: state),
                    _ContactTab(state: state),
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

class _OverviewTab extends StatelessWidget {
  final AppState state;
  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final s = state.adminStats;
    if (s == null) {
      return Center(
        child: state.loadingAdmin
            ? CircularProgressIndicator(color: c.gold)
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  state.adminError ?? l.noData,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Cairo', color: c.muted),
                ),
              ),
      );
    }
    final tiles = <(String, String, IconData, Color?)>[
      (l.totalUsers, '${s.totalUsers}', Icons.people_alt_rounded, null),
      (l.activeToday, '${s.usersToday}', Icons.today_rounded, c.green),
      (l.onlineNow, '${s.online}', Icons.wifi_tethering_rounded, c.blue),
      (l.totalShops, '${s.shopsTotal}', Icons.storefront_rounded, null),
      (l.totalAds, '${s.adsTotal}', Icons.campaign_rounded, null),
      (l.viewsCount, '${s.adViews}', Icons.visibility_rounded, null),
      (l.clicksCount, '${s.adClicks}', Icons.touch_app_rounded, c.blue),
      (l.revenue, l.iqd(s.revenueIqd), Icons.payments_rounded, c.gold),
      (l.totalAlerts, '${s.alertsTotal}', Icons.notifications_rounded, null),
      (l.signals, '${s.signals}', Icons.radar_rounded, null),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.gold.withValues(alpha: 0.32)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surface, c.gold.withValues(alpha: 0.08)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.pick('ملخص التشغيل', 'Operations summary'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l.pick(
                  'إحصائيات الإعلانات والمحلات والمستخدمين والتنبيهات.',
                  'Ads, shops, users and alerts at a glance.',
                ),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 10,
                  color: c.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.85,
          children: tiles
              .map(
                (t) => StatTile(
                  label: t.$1,
                  value: t.$2,
                  icon: t.$3,
                  valueColor: t.$4,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => showShopForm(context),
                icon: const Icon(Icons.add_business_rounded, size: 17),
                label: Text(l.addYourShop),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showAdForm(context),
                icon: const Icon(Icons.campaign_rounded, size: 17),
                label: Text(l.postAd),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${l.apiBase}: ${state.api.normalizedBase}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 9.5,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}

class _ShopsTab extends StatelessWidget {
  final AppState state;
  const _ShopsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final shops = state.adminShops;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showShopForm(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('${l.addNew} · ${l.shops}'),
            ),
          ),
        ),
        Expanded(
          child: shops.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    EmptyState(
                      icon: Icons.storefront_rounded,
                      title: l.noShopsAdmin,
                      action: FilledButton(
                        onPressed: () => showShopForm(context),
                        child: Text(l.addYourShop),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  itemCount: shops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final shop = shops[i];
                    return SurfaceCard(
                      padding: const EdgeInsets.all(11),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: shop.imageUrl.isEmpty
                                  ? Container(
                                      color: c.surfaceAlt,
                                      child: Icon(
                                        Icons.storefront_rounded,
                                        color: c.gold,
                                        size: 20,
                                      ),
                                    )
                                  : Image.network(
                                      state.api.mediaUrl(shop.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: c.surfaceAlt,
                                        child: Icon(
                                          Icons.storefront_rounded,
                                          color: c.gold,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.ink,
                                  ),
                                ),
                                Text(
                                  '${shop.city} · ${shop.views} ${l.views}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9.5,
                                    color: c.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!shop.isActive)
                            Pill(text: l.inactive, color: c.red, fontSize: 8),
                          IconButton(
                            onPressed: () => showShopForm(context, shop: shop),
                            icon: const Icon(Icons.edit_outlined, size: 17),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () => _confirmDeleteShop(context, state, shop),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: c.red,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteShop(
    BuildContext context,
    AppState state,
    Shop shop,
  ) async {
    final l = state.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.delete, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(
          '${l.deleteConfirm}\n${shop.name}',
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteShop(shop.id);
  }
}

class _AdsTab extends StatelessWidget {
  final AppState state;
  const _AdsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l = state.l;
    final c = AppColors.of(context);
    final ads = state.adminAds;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showAdForm(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('${l.addNew} · ${l.ads}'),
            ),
          ),
        ),
        Expanded(
          child: ads.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    EmptyState(
                      icon: Icons.campaign_rounded,
                      title: l.noAdsAdmin,
                      action: FilledButton(
                        onPressed: () => showAdForm(context),
                        child: Text(l.postAd),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  itemCount: ads.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final ad = ads[i];
                    return SurfaceCard(
                      padding: const EdgeInsets.all(11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ad.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                              if (!ad.isActive)
                                Pill(text: l.inactive, color: c.red, fontSize: 8),
                              if (ad.isFeatured)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Pill(text: l.featured, color: c.gold, fontSize: 8),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ad.categoryAr} · ${ad.placement} · '
                            '${ad.views} ${l.views} · ${ad.clicks} ${l.clicksCount}'
                            '${ad.daysLeft == null ? '' : ' · ${ad.daysLeft} ${l.daysLeft}'}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 9.5,
                              color: c.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => showAdForm(context, ad: ad),
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: Text(l.edit),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 30),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _confirmDeleteAd(context, state, ad),
                                icon: const Icon(Icons.delete_outline_rounded, size: 15),
                                label: Text(l.delete),
                                style: TextButton.styleFrom(
                                  foregroundColor: c.red,
                                  minimumSize: const Size(0, 30),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteAd(
    BuildContext context,
    AppState state,
    AdItem ad,
  ) async {
    final l = state.l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.delete, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(
          '${l.deleteConfirm}\n${ad.title}',
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteAd(ad.id);
  }
}

// ─────────────────────────── صور ───────────────────────────

Future<String?> _pickAndUpload(BuildContext context, String current) async {
  final state = AppScope.of(context);
  final l = state.l;
  try {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 82,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l.uploading)));
    final url = await state.uploadImage(file.name, bytes);
    messenger.hideCurrentSnackBar();
    if (url.isEmpty) return current;
    messenger.showSnackBar(SnackBar(content: Text(l.saved)));
    return url;
  } catch (e) {
    if (!context.mounted) return current;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${state.l.uploadImage}: $e')),
    );
    return current;
  }
}

Widget _imagePickerBlock(
  BuildContext context,
  String url,
  VoidCallback onPick,
  TextEditingController urlController,
  ValueChanged<String> onUrlChanged,
) {
  final state = AppScope.of(context);
  final l = state.l;
  final c = AppColors.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LabeledField(
        label: l.image,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: url.isEmpty
                    ? Container(
                        color: c.surfaceAlt,
                        child: Icon(Icons.image_outlined, color: c.gold, size: 24),
                      )
                    : Image.network(
                        state.api.mediaUrl(url),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: c.surfaceAlt,
                          child: Icon(Icons.broken_image_outlined,
                              color: c.muted, size: 22),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text(l.uploadImage, style: const TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: urlController,
        onChanged: onUrlChanged,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
        decoration: InputDecoration(
          hintText: l.orImageUrl,
          isDense: true,
          prefixIcon: const Icon(Icons.link_rounded, size: 16),
        ),
      ),
    ],
  );
}

// ─────────────────────────── نموذج المحل ───────────────────────────

Future<void> showShopForm(BuildContext context, {Shop? shop}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).surface,
    builder: (_) => _ShopForm(shop: shop),
  );
}

class _ShopForm extends StatefulWidget {
  final Shop? shop;
  const _ShopForm({this.shop});

  @override
  State<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<_ShopForm> {
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _city;
  late final TextEditingController _cityEn;
  late final TextEditingController _address;
  late final TextEditingController _addressEn;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _mapUrl;
  late final TextEditingController _image;
  late final TextEditingController _description;
  late final TextEditingController _descriptionEn;
  late final TextEditingController _hours;
  late bool _verified;
  late bool _featured;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.shop;
    _name = TextEditingController(text: s?.name ?? '');
    _nameEn = TextEditingController(text: s?.nameEn ?? '');
    _city = TextEditingController(text: s?.city ?? '');
    _cityEn = TextEditingController(text: s?.cityEn ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _addressEn = TextEditingController(text: s?.addressEn ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _whatsapp = TextEditingController(text: s?.whatsapp ?? '');
    _lat = TextEditingController(
      text: s == null || s.latitude == 0 ? '' : '${s.latitude}',
    );
    _lng = TextEditingController(
      text: s == null || s.longitude == 0 ? '' : '${s.longitude}',
    );
    _mapUrl = TextEditingController(text: s?.mapUrl ?? '');
    _image = TextEditingController(text: s?.imageUrl ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _descriptionEn = TextEditingController(text: s?.descriptionEn ?? '');
    _hours = TextEditingController(text: s?.workingHours ?? '');
    _verified = s?.isVerified ?? true;
    _featured = s?.isFeatured ?? false;
    _active = s?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _nameEn,
      _city,
      _cityEn,
      _address,
      _addressEn,
      _phone,
      _whatsapp,
      _lat,
      _lng,
      _mapUrl,
      _image,
      _description,
      _descriptionEn,
      _hours,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final l = state.l;
    if (_name.text.trim().length < 2) {
      setState(() => _error = l.requiredField);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await state.saveShop({
      'name': _name.text.trim(),
      'name_en': _nameEn.text.trim(),
      'city': _city.text.trim(),
      'city_en': _cityEn.text.trim(),
      'address': _address.text.trim(),
      'address_en': _addressEn.text.trim(),
      'phone': _phone.text.trim(),
      'whatsapp': _whatsapp.text.trim(),
      'latitude': double.tryParse(_lat.text.trim()) ?? 0,
      'longitude': double.tryParse(_lng.text.trim()) ?? 0,
      'map_url': _mapUrl.text.trim(),
      'image_url': _image.text.trim(),
      'description': _description.text.trim(),
      'description_en': _descriptionEn.text.trim(),
      'working_hours': _hours.text.trim(),
      'is_verified': _verified,
      'is_featured': _featured,
      'is_active': _active,
    }, id: widget.shop?.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _error = state.adminError ?? l.connectionFailed;
    });
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        maxChildSize: 0.98,
        minChildSize: 0.5,
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
            Text(
              widget.shop == null ? l.addYourShop : l.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _AdminField(controller: _name, label: l.shopName, required: true),
            const SizedBox(height: 10),
            _AdminField(controller: _nameEn, label: l.shopNameEn),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _AdminField(controller: _city, label: l.cityLabel)),
                const SizedBox(width: 8),
                Expanded(child: _AdminField(controller: _cityEn, label: l.cityEnLabel)),
              ],
            ),
            const SizedBox(height: 10),
            _AdminField(controller: _address, label: l.addressLabel),
            const SizedBox(height: 10),
            _AdminField(controller: _addressEn, label: l.addressEnLabel),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminField(
                    controller: _phone,
                    label: l.contactPhone,
                    keyboard: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminField(
                    controller: _whatsapp,
                    label: l.contactWhatsapp,
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminField(controller: _hours, label: l.workingHours),
            const SizedBox(height: 10),
            _AdminField(controller: _description, label: l.description, maxLines: 3),
            const SizedBox(height: 10),
            _AdminField(
              controller: _descriptionEn,
              label: l.descriptionEn,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminField(
                    controller: _lat,
                    label: l.latitude,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminField(
                    controller: _lng,
                    label: l.longitude,
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminField(controller: _mapUrl, label: '${l.map} URL'),
            const SizedBox(height: 12),
            _imagePickerBlock(
              context,
              _image.text,
              () async {
                final url = await _pickAndUpload(context, _image.text);
                if (url != null && mounted) setState(() => _image.text = url);
              },
              _image,
              (v) => setState(() {}),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.verifiedLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _verified,
              activeThumbColor: c.gold,
              onChanged: (v) => setState(() => _verified = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.featuredLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _featured,
              activeThumbColor: c.gold,
              onChanged: (v) => setState(() => _featured = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.activeLabel, style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _active,
              activeThumbColor: c.gold,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: c.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── نموذج الإعلان ───────────────────────────

Future<void> showAdForm(BuildContext context, {AdItem? ad}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.of(context).surface,
    builder: (_) => _AdForm(ad: ad),
  );
}

const _categories = ['general', 'jewelry', 'gold', 'watches', 'services', 'electronics'];
const _placements = ['home', 'shops', 'news', 'market'];

class _AdForm extends StatefulWidget {
  final AdItem? ad;
  const _AdForm({this.ad});

  @override
  State<_AdForm> createState() => _AdFormState();
}

class _AdFormState extends State<_AdForm> {
  late final TextEditingController _title;
  late final TextEditingController _titleEn;
  late final TextEditingController _description;
  late final TextEditingController _descriptionEn;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _link;
  late final TextEditingController _city;
  late final TextEditingController _image;
  late final TextEditingController _days;
  late String _category;
  late String _placement;
  late String _package;
  late bool _featured;
  late bool _active;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.ad;
    _title = TextEditingController(text: a?.title ?? '');
    _titleEn = TextEditingController(text: a?.titleEn ?? '');
    _description = TextEditingController(text: a?.description ?? '');
    _descriptionEn = TextEditingController(text: a?.descriptionEn ?? '');
    _price = TextEditingController(text: a == null || a.price == 0 ? '' : '${a.price}');
    _currency = TextEditingController(text: a?.currency ?? 'IQD');
    _phone = TextEditingController(text: a?.phone ?? '');
    _whatsapp = TextEditingController(text: a?.whatsapp ?? '');
    _link = TextEditingController(text: a?.link ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _image = TextEditingController(text: a?.imageUrl ?? '');
    _days = TextEditingController(text: '30');
    _category = _categories.contains(a?.category) ? a!.category : 'general';
    _placement = _placements.contains(a?.placement) ? a!.placement : 'home';
    _package = a?.package ?? 'basic';
    _featured = a?.isFeatured ?? false;
    _active = a?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _titleEn,
      _description,
      _descriptionEn,
      _price,
      _currency,
      _phone,
      _whatsapp,
      _link,
      _city,
      _image,
      _days,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    final l = state.l;
    if (_title.text.trim().length < 2) {
      setState(() => _error = l.requiredField);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await state.saveAd({
      'title': _title.text.trim(),
      'title_en': _titleEn.text.trim(),
      'description': _description.text.trim(),
      'description_en': _descriptionEn.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'currency': _currency.text.trim().isEmpty ? 'IQD' : _currency.text.trim(),
      'image_url': _image.text.trim(),
      'phone': _phone.text.trim(),
      'whatsapp': _whatsapp.text.trim(),
      'link': _link.text.trim(),
      'city': _city.text.trim(),
      'category': _category,
      'placement': _placement,
      'package': _package,
      'is_featured': _featured,
      'is_active': _active,
      'days': int.tryParse(_days.text.trim()) ?? 30,
    }, id: widget.ad?.id);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _error = state.adminError ?? l.connectionFailed;
    });
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        maxChildSize: 0.98,
        minChildSize: 0.5,
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
            Text(
              widget.ad == null ? l.postAd : l.edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _AdminField(controller: _title, label: l.adTitle, required: true),
            const SizedBox(height: 10),
            _AdminField(controller: _titleEn, label: l.adTitleEn),
            const SizedBox(height: 10),
            _AdminField(controller: _description, label: l.description, maxLines: 3),
            const SizedBox(height: 10),
            _AdminField(
              controller: _descriptionEn,
              label: l.descriptionEn,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminField(
                    controller: _price,
                    label: l.price,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminField(controller: _currency, label: l.currency),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: l.categoryLabel,
                    value: _category,
                    items: _categories
                        .map((v) => MapEntry(v, l.category(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DropdownField(
                    label: l.placement,
                    value: _placement,
                    items: _placements
                        .map(
                          (v) => MapEntry(
                            v,
                            v == 'home'
                                ? l.pick('الرئيسية', 'Home')
                                : v == 'shops'
                                    ? l.pick('المحلات', 'Shops')
                                    : v == 'news'
                                        ? l.pick('الأخبار', 'News')
                                        : l.pick('السوق', 'Market'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _placement = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DropdownField(
              label: l.packageLabel,
              value: _package,
              items: state.packages.isEmpty
                  ? const [MapEntry('basic', 'Basic')]
                  : state.packages
                      .map((p) => MapEntry(p.code, p.displayName(state.en)))
                      .toList(),
              onChanged: (v) => setState(() => _package = v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _AdminField(
                    controller: _phone,
                    label: l.contactPhone,
                    keyboard: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdminField(
                    controller: _whatsapp,
                    label: l.contactWhatsapp,
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminField(controller: _city, label: l.pick('المدينة', 'City')),
            const SizedBox(height: 10),
            _AdminField(controller: _link, label: l.websiteLink),
            const SizedBox(height: 10),
            _AdminField(
              controller: _days,
              label: l.pick('مدة الإعلان (أيام)', 'Ad duration (days)'),
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _imagePickerBlock(
              context,
              _image.text,
              () async {
                final url = await _pickAndUpload(context, _image.text);
                if (url != null && mounted) setState(() => _image.text = url);
              },
              _image,
              (v) => setState(() {}),
            ),
            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.featuredLabel,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _featured,
              activeThumbColor: c.gold,
              onChanged: (v) => setState(() => _featured = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l.activeLabel,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
              value: _active,
              activeThumbColor: c.gold,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: c.red),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTab extends StatefulWidget {
  final AppState state;
  const _ContactTab({required this.state});

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  late final TextEditingController _name;
  late final TextEditingController _nameEn;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _telegram;
  late final TextEditingController _email;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.state.ownerContact;
    _name = TextEditingController(text: c.name);
    _nameEn = TextEditingController(text: c.nameEn);
    _phone = TextEditingController(text: c.phone);
    _whatsapp = TextEditingController(text: c.whatsapp);
    _telegram = TextEditingController(text: c.telegram);
    _email = TextEditingController(text: c.email);
  }

  @override
  void dispose() {
    for (final c in [_name, _nameEn, _phone, _whatsapp, _telegram, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    final ok = await widget.state.saveOwnerContact({
      'name': _name.text.trim(),
      'name_en': _nameEn.text.trim(),
      'phone': _phone.text.trim(),
      'whatsapp': _whatsapp.text.trim(),
      'telegram': _telegram.text.trim(),
      'email': _email.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _saved = ok;
      if (!ok) _error = widget.state.adminError ?? widget.state.l.connectionFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.state.l;
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Text(
          l.contactSubtitle,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            height: 1.6,
            color: c.muted,
          ),
        ),
        const SizedBox(height: 12),
        _AdminField(controller: _name, label: l.contactName),
        const SizedBox(height: 10),
        _AdminField(controller: _nameEn, label: '${l.contactName} (EN)'),
        const SizedBox(height: 10),
        _AdminField(
          controller: _phone,
          label: l.contactPhone,
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _AdminField(
          controller: _whatsapp,
          label: l.contactWhatsapp,
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _AdminField(
          controller: _telegram,
          label: l.contactTelegram,
        ),
        const SizedBox(height: 10),
        _AdminField(
          controller: _email,
          label: l.contactEmail,
          keyboard: TextInputType.emailAddress,
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: c.red),
          ),
        ],
        if (_saved) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: c.green),
              const SizedBox(width: 6),
              Text(
                l.contactSaved,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: c.green,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: Text(l.save),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.pick(
            'يظهر للمستخدم فقط ما تعبّئه هنا. اترك الحقل فارغاً ولن يظهر زرّه.',
            'Only the fields you fill in are shown to users. Leave a field empty and its button disappears.',
          ),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            height: 1.6,
            color: c.muted,
          ),
        ),
      ],
    );
  }
}

class _AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;
  final bool required;

  const _AdminField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboard,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: required ? '$label *' : label,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12.5),
        decoration: const InputDecoration(isDense: true),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return LabeledField(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: c.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.any((e) => e.key == value) ? value : items.first.key,
            isExpanded: true,
            dropdownColor: c.surfaceAlt,
            icon: Icon(Icons.expand_more_rounded, color: c.muted, size: 18),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: c.ink,
            ),
            items: items
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(
                      e.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: c.ink,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
