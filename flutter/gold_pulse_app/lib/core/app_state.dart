import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'l10n.dart';
import 'models.dart';
import 'notify.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  SharedPreferences? _prefs;

  bool ready = false;
  bool en = false;
  ThemeMode themeMode = ThemeMode.dark;
  bool autoRefresh = true;
  bool iqdMode = true;
  bool alertSound = true;
  bool notificationsEnabled = false;
  double? targetOunceIqd;
  AlertItem? latestAlert;
  String deviceId = '';
  String adminPin = '';
  int myRating = 0;
  String historyRange = '1y';
  static const int marketRefreshSeconds = 20;

  AppConfig config = AppConfig.fallback;
  MarketSnapshot? market;
  Analysis? analysis;
  NewsPayload? newsData;
  AlertsPayload? alertsData;
  HistoryPayload? historyData;
  List<Shop> shops = [];
  List<ShopCity> shopCities = [];
  List<AdItem> ads = [];
  List<AdPackage> packages = [];
  CurrenciesPayload? currencies;
  PresenceStats presence = PresenceStats.empty;
  PresenceStats? presenceDetails;
  OwnerContact ownerContact = OwnerContact.empty;
  AdminStats? adminStats;
  List<Shop> adminShops = [];
  List<AdItem> adminAds = [];

  bool loadingMarket = false;
  bool loadingAnalysis = false;
  bool loadingNews = false;
  bool loadingAlerts = false;
  bool loadingHistory = false;
  bool loadingShops = false;
  bool loadingAds = false;
  bool loadingCurrencies = false;
  bool loadingPresence = false;
  bool loadingAdmin = false;

  String? lastError;
  String? adminError;
  DateTime? marketUpdatedAt;
  DateTime? analysisUpdatedAt;
  Timer? _marketTimer;
  Timer? _analysisTimer;
  Timer? _presenceTimer;
  bool _disposed = false;
  int _lastAlertId = 0;
  double? _prevOunceIqd;

  L10n get l => L10n(en);
  String get langCode => en ? 'en' : 'ar';
  bool get isOwner => adminPin.isNotEmpty;
  int get unreadAlerts => alertsData?.unread ?? 0;
  int get activeUnread => alertsData?.items.where((a) => !a.isRead).length ?? 0;

  /// ثواني متبقية حتى التحديث التلقائي التالي.
  int get secondsToRefresh {
    final at = marketUpdatedAt;
    if (at == null) return marketRefreshSeconds;
    final passed = DateTime.now().difference(at).inSeconds;
    final left = marketRefreshSeconds - (passed % marketRefreshSeconds);
    return left <= 0 ? marketRefreshSeconds : left;
  }

  int get secondsSinceRefresh {
    final at = marketUpdatedAt;
    return at == null ? 0 : DateTime.now().difference(at).inSeconds;
  }

  bool get hasFreshMarket {
    final at = marketUpdatedAt;
    return at != null && DateTime.now().difference(at).inSeconds < 45;
  }

  List<AdItem> get homeAds =>
      ads.where((a) => a.placement == 'home' || a.isFeatured).take(6).toList();

  List<AdItem> get featuredAds =>
      ads.where((a) => a.isFeatured).take(6).toList();

  Future<void> init() async {
    // لا نسمح لفشل التخزين المحلي أو الشبكة أن يعلّق شاشة البداية.
    try {
      _prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 8),
      );
    } catch (e) {
      debugPrint('تعذرت قراءة الإعدادات المحلية: $e');
    }
    final p = _prefs;
    if (p != null) {
      try {
    final query = Uri.base.queryParameters;
    final queryLocale = query['lang'];
    en =
        queryLocale == 'en' ||
        (queryLocale != 'ar' && p.getString('locale') == 'en');
    final theme = query['theme'] ?? p.getString('theme') ?? 'dark';
    themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'system'
        ? ThemeMode.system
        : ThemeMode.dark;
    api.baseUrl = ApiClient.defaultBaseUrl;
    final savedBase = p.getString('api_base');
    if (savedBase != null &&
        savedBase.isNotEmpty &&
        savedBase != ApiClient.defaultBaseUrl) {
      // لا نثق بعنوان محفوظ من نسخة قديمة (شبكة محلية/نفق منتهي):
      // نستخدمه فقط إذا كان HTTPS وخادماً حياً فعلاً.
      final usable =
          savedBase.startsWith('https://') &&
          await ApiClient(baseUrl: savedBase).ping();
      if (usable) {
        api.baseUrl = savedBase;
      } else {
        await p.remove('api_base');
      }
    }
    // العامل الخلفي (WorkManager) يقرأ هذا العنوان بنفسه.
    await p.setString('worker_api_base', api.baseUrl);
    adminPin = p.getString('admin_pin') ?? '';
    myRating = p.getInt('my_rating') ?? 0;
    autoRefresh = p.getBool('auto_refresh') ?? true;
    iqdMode = (p.getString('price_unit') ?? 'iqd') == 'iqd';
    alertSound = p.getBool('alert_sound') ?? true;
    notificationsEnabled = p.getBool('notifications') ?? false;
    targetOunceIqd = p.getDouble('target_ounce_iqd');
    _lastAlertId = p.getInt('last_alert_id') ?? 0;
    deviceId = p.getString('device_id') ?? _newDeviceId();
    if (p.getString('device_id') == null) {
      await p.setString('device_id', deviceId);
    }
      } catch (e) {
        debugPrint('تعذر تحميل التفضيلات: $e');
      }
    }
    try {
      await Notifier.init();
    } catch (_) {
      // الإشعارات اختيارية ولا تمنع فتح التطبيق.
    }
    try {
      await _bootstrap().timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('تعذر تحميل البيانات الأولية: $e');
    }
    if (adminPin.isNotEmpty) {
      // جلسة المالك محفوظة: نحمّل لوحة التحكم بالخلفية.
      unawaited(loadAdminData());
    }
    ready = true;
    _notify();
    _startTimers();
    unawaited(_prepareNotifications());
  }

  /// يطلب إذن الإشعارات أول مرة، ويزامن الحالة مع إعدادات الهاتف.
  Future<void> _prepareNotifications() async {
    final p = _prefs;
    if (p == null) return;
    final asked = p.getBool('notif_asked') ?? false;
    if (!asked) {
      final granted = await Notifier.requestPermission();
      notificationsEnabled = granted;
      await p.setBool('notif_asked', true);
      await p.setBool('notifications', granted);
      if (granted) await Notifier.init();
      _notify();
      return;
    }
    if (p.getBool('notifications') == true) {
      final allowed = await Notifier.areEnabled();
      if (allowed != notificationsEnabled) {
        notificationsEnabled = allowed;
        if (!allowed) await p.setBool('notifications', false);
        _notify();
      }
    }
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      loadConfig(),
      loadMarket(silent: true),
      loadAnalysis(silent: true),
      loadNews(silent: true),
      loadAlerts(silent: true),
      loadShops(),
      loadShopCities(),
      loadAds(),
      loadPackages(),
      loadCurrencies(),
      sendPresence(),
      loadContact(),
      loadHistory(historyRange, silent: true),
    ]);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// رسالة خطأ نظيفة لا تكشف عنوان الخادم أو تفاصيل الشبكة للمستخدم.
  String _cleanError(Object e) {
    var text = e.toString();
    text = text.replaceAll(RegExp(r'https?://\S+'), '');
    text = text.replaceAll(
      RegExp(
        r'\b[\w.-]+\.(?:vercel\.app|onrender\.com|ngrok\.io|trycloudflare\.com|localhost)\b',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll('ClientException', 'تعذر الاتصال');
    text = text.replaceAll('SocketException', 'انقطاع الشبكة');
    text = text.replaceAll('HandshakeException', 'فشل تأمين الاتصال');
    text = text.replaceAll('TimeoutException', 'انتهت المهلة');
    text = text.replaceAll(RegExp(r'[\s:\-]+$'), '').trim();
    if (text.isEmpty || text == 'Exception') {
      return en
          ? 'Could not reach the server. Check your connection and try again.'
          : 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.';
    }
    return text;
  }

  String _newDeviceId() {
    final rand = Random.secure();
    final part = List.generate(
      8,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return 'dev-${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}-$part';
  }

  void _startTimers() {
    _marketTimer?.cancel();
    _analysisTimer?.cancel();
    _presenceTimer?.cancel();
    _marketTimer = Timer.periodic(
      const Duration(seconds: marketRefreshSeconds),
      (_) {
        if (autoRefresh) {
          loadMarket(silent: true);
          loadAlerts(silent: true);
        }
      },
    );
    _analysisTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (autoRefresh) {
        loadAnalysis(silent: true);
        loadNews(silent: true);
      }
    });
    _presenceTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      sendPresence();
    });
  }

  Future<void> setLanguage(String code) async {
    final next = code == 'en';
    if (next == en) return;
    en = next;
    await _prefs?.setString('locale', langCode);
    _notify();
    await Future.wait([
      loadConfig(),
      loadMarket(silent: true),
      loadAnalysis(silent: true),
      loadNews(silent: true),
      sendPresence(),
    ]);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setString(
      'theme',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
          ? 'system'
          : 'dark',
    );
    _notify();
  }

  Future<void> setAutoRefresh(bool value) async {
    autoRefresh = value;
    await _prefs?.setBool('auto_refresh', value);
    _notify();
  }

  /// اختيار وحدة العرض: الدولار أو الدينار العراقي.
  Future<void> setPriceUnit(bool iqd) async {
    if (iqd == iqdMode) return;
    iqdMode = iqd;
    await _prefs?.setString('price_unit', iqd ? 'iqd' : 'usd');
    _notify();
  }

  Future<void> setAlertSound(bool value) async {
    alertSound = value;
    await _prefs?.setBool('alert_sound', value);
    if (value) await Notifier.playAlertSound();
    _notify();
  }

  Future<bool> setNotifications(bool value) async {
    notificationsEnabled = value;
    if (value) {
      final granted = await Notifier.requestPermission();
      if (!granted) {
        notificationsEnabled = false;
        _notify();
        return false;
      }
    }
    await _prefs?.setBool('notifications', notificationsEnabled);
    _notify();
    return true;
  }

  Future<void> setTargetOunce(double? value) async {
    targetOunceIqd = value;
    if (value == null) {
      await _prefs?.remove('target_ounce_iqd');
    } else {
      await _prefs?.setDouble('target_ounce_iqd', value);
    }
    _notify();
  }

  Future<void> testAlert() async {
    await Notifier.playAlertSound();
    await Notifier.showAlert(
      id: 990001,
      title: en ? 'Gold alert test' : 'تجربة تنبيه ذهبي',
      body: en
          ? 'This is how a Gold Pulse alert looks and sounds.'
          : 'هكذا يظهر تنبيه نبض الذهب ويبدو صوته.',
      severity: 'medium',
    );
  }

  Future<void> setApiBase(String value) async {
    api.baseUrl = value.trim();
    await _prefs?.setString('api_base', api.baseUrl);
    await _prefs?.setString('worker_api_base', api.baseUrl);
    clearData();
    await _bootstrap();
    _notify();
  }

  Future<bool> testConnection() async {
    try {
      await api.config(lang: langCode);
      return true;
    } catch (e) {
      lastError = _cleanError(e);
      _notify();
      return false;
    }
  }

  /// إرسال تقييم التطبيق وحفظه محلياً أيضاً.
  Future<Map<String, dynamic>?> rateApp(int rating, String comment) async {
    try {
      final res = await api.sendFeedback(
        deviceId: deviceId,
        rating: rating,
        comment: comment,
        lang: langCode,
        appVersion: config.version,
      );
      myRating = rating;
      await _prefs?.setInt('my_rating', rating);
      _notify();
      return res;
    } catch (e) {
      lastError = _cleanError(e);
      _notify();
      return null;
    }
  }

  Future<void> resetSettings() async {
    en = false;
    themeMode = ThemeMode.dark;
    autoRefresh = true;
    iqdMode = true;
    alertSound = true;
    notificationsEnabled = false;
    targetOunceIqd = null;
    adminPin = '';
    api.baseUrl = ApiClient.defaultBaseUrl;
    final p = _prefs;
    if (p != null) {
      await p.remove('locale');
      await p.remove('theme');
      await p.remove('api_base');
      await p.remove('admin_pin');
      await p.remove('auto_refresh');
      await p.remove('price_unit');
      await p.remove('alert_sound');
      await p.remove('notifications');
      await p.remove('notif_asked');
      await p.remove('target_ounce_iqd');
      await p.remove('last_alert_id');
    }
    clearData();
    await _bootstrap();
    _notify();
  }

  void clearData() {
    market = null;
    analysis = null;
    newsData = null;
    alertsData = null;
    historyData = null;
    shops = [];
    shopCities = [];
    ads = [];
    adminStats = null;
    adminShops = [];
    adminAds = [];
  }

  Future<void> loadConfig() async {
    try {
      config = await api.config(lang: langCode);
      _notify();
    } catch (e) {
      lastError = _cleanError(e);
      _notify();
    }
  }

  Future<void> loadMarket({bool silent = false}) async {
    if (!silent) {
      loadingMarket = true;
      _notify();
    }
    try {
      final next = await api.market(lang: langCode);
      market = next;
      marketUpdatedAt = DateTime.now();
      lastError = null;
      _checkTarget(next);
      _prevOunceIqd = next.ounceIqd;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingMarket = false;
      _notify();
    }
  }

  /// تنبيه محلي عند وصول الأونصة إلى السعر الذي حدده المستخدم.
  Future<void> _checkTarget(MarketSnapshot m) async {
    final target = targetOunceIqd;
    if (target == null || target <= 0 || m.ounceIqd <= 0) return;
    final prev = _prevOunceIqd;
    final price = m.ounceIqd;
    final distance = (price - target).abs() / target;
    final crossed =
        prev != null &&
        ((prev < target && price >= target) ||
            (prev > target && price <= target));
    if (!crossed && distance > 0.0015) return;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    // نفس كتم التنبيه المستخدم في العامل الخلفي حتى لا يتكرر الإشعار.
    final storedMs = _prefs?.getInt('target_alert_ms') ?? 0;
    if (nowMs - storedMs < 360 * 60 * 1000) return;
    await _prefs?.setInt('target_alert_ms', nowMs);
    final title = en ? 'Target price reached' : 'وصل السعر إلى هدفك';
    final body = en
        ? 'Gold ounce is now ${l.moneyIqd(price)} — your target was ${l.moneyIqd(target)}.'
        : 'سعر الأونصة الآن ${l.moneyIqd(price)} — هدفك كان ${l.moneyIqd(target)}.';
    latestAlert = AlertItem(
      id: now.millisecondsSinceEpoch ~/ 1000,
      createdAt: now.toIso8601String(),
      kind: 'price',
      severity: 'high',
      title: title,
      titleEn: title,
      body: body,
      bodyEn: body,
      action: 'WATCH',
      price: m.usdOz,
      isRead: false,
    );
    if (alertSound) await Notifier.playAlertSound();
    await Notifier.showAlert(
      id: 99001,
      title: title,
      body: body,
      severity: 'high',
    );
    _notify();
  }

  Future<void> loadAnalysis({bool silent = false}) async {
    if (!silent) {
      loadingAnalysis = true;
      _notify();
    }
    try {
      analysis = await api.analysis(lang: langCode);
      analysisUpdatedAt = DateTime.now();
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingAnalysis = false;
      _notify();
    }
  }

  Future<void> loadNews({bool silent = false}) async {
    if (!silent) {
      loadingNews = true;
      _notify();
    }
    try {
      newsData = await api.news(lang: langCode);
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingNews = false;
      _notify();
    }
  }

  Future<void> loadAlerts({bool silent = false}) async {
    if (!silent) {
      loadingAlerts = true;
      _notify();
    }
    try {
      final next = await api.alerts();
      alertsData = next;
      lastError = null;
      _detectNewAlert(next);
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingAlerts = false;
      _notify();
    }
  }

  /// كشف التنبيه الأحدث وإطلاق الصوت/الإشعار مرة واحدة فقط.
  Future<void> _detectNewAlert(AlertsPayload payload) async {
    if (payload.items.isEmpty) return;
    AlertItem newest = payload.items.first;
    for (final item in payload.items) {
      if (item.id > newest.id) newest = item;
    }
    // العامل الخلفي قد يكون أرسل التنبيه وحدّث آخر معرّف قبل فتح التطبيق.
    final storedLast = _prefs?.getInt('last_alert_id') ?? 0;
    if (storedLast > _lastAlertId) _lastAlertId = storedLast;
    if (_lastAlertId == 0) {
      _lastAlertId = newest.id;
      await _prefs?.setInt('last_alert_id', _lastAlertId);
      return;
    }
    if (newest.id <= _lastAlertId) return;
    _lastAlertId = newest.id;
    await _prefs?.setInt('last_alert_id', _lastAlertId);
    latestAlert = newest;
    if (alertSound) await Notifier.playAlertSound();
    if (notificationsEnabled) {
      await Notifier.showAlert(
        id: newest.id,
        title: newest.displayTitle(en),
        body: newest.displayBody(en),
        severity: newest.severity,
      );
    }
    _notify();
  }

  Future<void> loadHistory(String range, {bool silent = false}) async {
    historyRange = range;
    if (!silent) {
      loadingHistory = true;
      _notify();
    }
    try {
      historyData = await api.history(range);
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingHistory = false;
      _notify();
    }
  }

  Future<void> loadShops({String q = '', String city = ''}) async {
    loadingShops = true;
    _notify();
    try {
      shops = await api.shops(q: q, city: city);
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingShops = false;
      _notify();
    }
  }

  Future<void> loadShopCities() async {
    try {
      shopCities = await api.shopCities();
      _notify();
    } catch (_) {
      // تجاهل — ليست حرجة
    }
  }

  Future<void> loadAds() async {
    loadingAds = true;
    _notify();
    try {
      ads = await api.ads(limit: 80);
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingAds = false;
      _notify();
    }
  }

  Future<void> loadPackages() async {
    try {
      packages = await api.adPackages();
      _notify();
    } catch (_) {}
  }

  Future<void> loadCurrencies() async {
    loadingCurrencies = true;
    _notify();
    try {
      currencies = await api.currencies();
      lastError = null;
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingCurrencies = false;
      _notify();
    }
  }

  Future<void> sendPresence() async {
    try {
      presence = await api.presence(
        deviceId: deviceId,
        platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
        locale: langCode,
      );
      _notify();
    } catch (_) {}
  }

  Future<void> loadPresenceStats() async {
    loadingPresence = true;
    _notify();
    try {
      presence = await api.presenceStats();
      _notify();
    } catch (e) {
      lastError = _cleanError(e);
    } finally {
      loadingPresence = false;
      _notify();
    }
  }

  /// تفاصيل المستخدمين (منصات/لغات/نسخ) — للمالك فقط.
  Future<void> loadPresenceDetails() async {
    if (adminPin.isEmpty) return;
    try {
      presenceDetails = await api.adminPresence(adminPin);
      _notify();
    } catch (_) {}
  }

  Future<void> loadContact() async {
    try {
      ownerContact = await api.contact();
      _notify();
    } catch (_) {}
  }

  Future<bool> saveOwnerContact(Map<String, dynamic> data) async {
    try {
      ownerContact = await api.saveContact(pin: adminPin, data: data);
      _notify();
      return true;
    } catch (e) {
      adminError = _cleanError(e);
      _notify();
      return false;
    }
  }

  Future<void> markAllAlertsRead() async {
    try {
      await api.markAllAlertsRead();
      await loadAlerts(silent: true);
    } catch (e) {
      lastError = _cleanError(e);
      _notify();
    }
  }

  Future<void> markAlertRead(int id) async {
    try {
      await api.markAlertRead(id);
      await loadAlerts(silent: true);
    } catch (_) {}
  }

  Future<void> adClick(int id) async {
    try {
      await api.adClick(id);
    } catch (_) {}
  }

  Future<void> refreshAll({bool silent = true}) async {
    await Future.wait([
      loadMarket(silent: silent),
      loadAnalysis(silent: silent),
      loadNews(silent: silent),
      loadAlerts(silent: silent),
      loadShops(),
      loadAds(),
      loadCurrencies(),
      loadPresenceStats(),
    ]);
  }

  // ── المالك ────────────────────────────────────────────
  Future<bool> adminLogin(String pin) async {
    adminError = null;
    try {
      final ok = await api.adminLogin(pin);
      if (ok) {
        adminPin = pin;
        await _prefs?.setString('admin_pin', pin);
        await loadAdminData();
        return true;
      }
    } catch (e) {
      adminError = _cleanError(e);
    }
    _notify();
    return false;
  }

  Future<void> loadAdminData() async {
    if (adminPin.isEmpty) return;
    loadingAdmin = true;
    adminError = null;
    _notify();
    try {
      final results = await Future.wait([
        api.adminStats(adminPin),
        api.adminShops(adminPin),
        api.adminAds(adminPin),
      ]);
      adminStats = results[0] as AdminStats;
      adminShops = results[1] as List<Shop>;
      adminAds = results[2] as List<AdItem>;
      await loadPresenceDetails();
    } catch (e) {
      adminError = _cleanError(e);
    } finally {
      loadingAdmin = false;
      _notify();
    }
  }

  Future<void> logoutAdmin() async {
    adminPin = '';
    adminStats = null;
    adminShops = [];
    adminAds = [];
    presenceDetails = null;
    await _prefs?.remove('admin_pin');
    _notify();
  }

  Future<String> uploadImage(String filename, List<int> bytes) {
    return api.uploadImage(pin: adminPin, filename: filename, bytes: bytes);
  }

  Future<bool> saveShop(Map<String, dynamic> data, {int? id}) async {
    try {
      await api.saveShop(pin: adminPin, data: data, id: id);
      await Future.wait([loadAdminData(), loadShops(), loadShopCities()]);
      return true;
    } catch (e) {
      adminError = _cleanError(e);
      _notify();
      return false;
    }
  }

  Future<bool> deleteShop(int id) async {
    try {
      await api.deleteShop(pin: adminPin, id: id);
      await Future.wait([loadAdminData(), loadShops(), loadShopCities()]);
      return true;
    } catch (e) {
      adminError = _cleanError(e);
      _notify();
      return false;
    }
  }

  Future<bool> saveAd(Map<String, dynamic> data, {int? id}) async {
    try {
      await api.saveAd(pin: adminPin, data: data, id: id);
      await Future.wait([loadAdminData(), loadAds()]);
      return true;
    } catch (e) {
      adminError = _cleanError(e);
      _notify();
      return false;
    }
  }

  Future<bool> deleteAd(int id) async {
    try {
      await api.deleteAd(pin: adminPin, id: id);
      await Future.wait([loadAdminData(), loadAds()]);
      return true;
    } catch (e) {
      adminError = _cleanError(e);
      _notify();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _marketTimer?.cancel();
    _analysisTimer?.cancel();
    _presenceTimer?.cancel();
    super.dispose();
  }
}
