import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

class ApiClient {
  String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  static const String _envBase = String.fromEnvironment('API_BASE');

  static String get defaultBaseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    if (kIsWeb) {
      final base = Uri.base;
      final host = base.host;
      final isLocal =
          host.isEmpty ||
          host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '10.0.2.2';
      if (!isLocal) {
        // عند تقديم الويب من الخادم نفسه (استضافة سحابية) نستخدم نفس الأصل.
        return base.origin;
      }
      if (base.port == 8020) return 'http://${base.host}:8010';
      if (base.port == 8010) return base.origin;
      return 'http://127.0.0.1:8010';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8010';
    }
    return 'http://127.0.0.1:8010';
  }

  String get normalizedBase {
    var value = baseUrl.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    return value;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$normalizedBase$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }

  Future<Map<String, dynamic>> _decode(http.Response res) async {
    final text = utf8.decode(res.bodyBytes);
    dynamic data;
    try {
      data = jsonDecode(text);
    } catch (_) {
      throw ApiException(
        'استجابة غير صالحة من الخادم (${res.statusCode})',
        res.statusCode,
      );
    }
    if (res.statusCode >= 400) {
      final detail = data is Map ? data['detail'] : null;
      throw ApiException(
        detail?.toString() ?? 'خطأ في الخادم (${res.statusCode})',
        res.statusCode,
      );
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw ApiException('استجابة غير متوقعة من الخادم', res.statusCode);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
    int timeout = 70,
    Map<String, String>? headers,
    int retries = 2,
  }) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final res = await http
            .get(
              _uri(path, query),
              headers: {'Accept': 'application/json', ...?headers},
            )
            .timeout(Duration(seconds: timeout));
        return await _decode(res);
      } on TimeoutException {
        throw const ApiException(
          'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة أو أوقف الـ VPN.',
        );
      } on ApiException {
        rethrow;
      } catch (e) {
        if (attempt < retries) {
          await Future<void>.delayed(
            Duration(milliseconds: 600 * (attempt + 1)),
          );
        }
      }
    }
    throw const ApiException(
      'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مرة أخرى.',
    );
  }

  /// اختبار سريع للخادم قبل الاعتماد عليه.
  Future<bool> ping({int timeout = 6}) async {
    try {
      await _get('/health', timeout: timeout, retries: 0);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int timeout = 70,
  }) async {
    try {
      final request = http.Request(method, _uri(path));
      request.headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      });
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(Duration(seconds: timeout));
      final res = await http.Response.fromStream(streamed);
      return await _decode(res);
    } on TimeoutException {
      throw const ApiException('انتهت مهلة الاتصال بالخادم. تحقق من الشبكة.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw const ApiException(
        'تعذر إرسال الطلب للخادم. تحقق من الإنترنت وحاول مرة أخرى.',
      );
    }
  }

  Map<String, String> _admin(String pin) => {'X-Admin-Pin': pin};

  String mediaUrl(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '$normalizedBase$value';
    if (value.startsWith('media/')) return '$normalizedBase/$value';
    return '$normalizedBase/media/$value';
  }

  Future<AppConfig> config({String lang = 'ar'}) async {
    final json = await _get('/api/config', query: {'lang': lang});
    return AppConfig.fromJson(json);
  }

  Future<MarketSnapshot> market({String lang = 'ar'}) async {
    final json = await _get('/api/market', query: {'lang': lang});
    return MarketSnapshot.fromJson(json);
  }

  Future<HistoryPayload> history(String range) async {
    final json = await _get('/api/history', query: {'range': range});
    return HistoryPayload.fromJson(json);
  }

  Future<Analysis> analysis({String lang = 'ar'}) async {
    final json = await _get(
      '/api/analysis',
      query: {'lang': lang},
      timeout: 90,
    );
    return Analysis.fromJson(json);
  }

  Future<NewsPayload> news({
    String lang = 'ar',
    String category = 'all',
  }) async {
    final json = await _get(
      '/api/news',
      query: {'lang': lang, 'category': category, 'limit': '70'},
      timeout: 60,
    );
    return NewsPayload.fromJson(json);
  }

  Future<AlertsPayload> alerts() async {
    final json = await _get('/api/alerts');
    return AlertsPayload.fromJson(json);
  }

  Future<void> markAllAlertsRead() async {
    await _send('POST', '/api/alerts/read-all');
  }

  Future<void> markAlertRead(int id) async {
    await _send('POST', '/api/alerts/$id/read');
  }

  Future<PresenceStats> presence({
    required String deviceId,
    required String platform,
    required String locale,
  }) async {
    final json = await _send(
      'POST',
      '/api/presence',
      body: {
        'device_id': deviceId,
        'platform': platform,
        'locale': locale,
        'app_version': '1.1.1',
      },
    );
    return PresenceStats.fromJson(json);
  }

  Future<PresenceStats> presenceStats() async {
    final json = await _get('/api/presence/stats');
    return PresenceStats.fromJson(json);
  }

  /// تفاصيل المستخدمين — تتطلب رمز المالك.
  Future<PresenceStats> adminPresence(String pin) async {
    final json = await _get('/api/admin/presence', headers: _admin(pin));
    return PresenceStats.fromJson(json);
  }

  Future<OwnerContact> contact() async {
    final json = await _get('/api/contact');
    return OwnerContact.fromJson(json);
  }

  /// إرسال تقييم التطبيق (نجوم 1-5 + ملاحظة اختيارية).
  Future<Map<String, dynamic>> sendFeedback({
    required String deviceId,
    required int rating,
    String comment = '',
    String lang = 'ar',
    String appVersion = '',
  }) {
    return _send(
      'POST',
      '/api/feedback',
      body: {
        'device_id': deviceId,
        'rating': rating,
        'comment': comment,
        'lang': lang,
        'app_version': appVersion,
      },
    );
  }

  Future<OwnerContact> saveContact({
    required String pin,
    required Map<String, dynamic> data,
  }) async {
    final json = await _send(
      'PUT',
      '/api/admin/contact',
      headers: _admin(pin),
      body: data,
    );
    return OwnerContact.fromJson(
      (json['item'] as Map?)?.cast<String, dynamic>() ?? json,
    );
  }

  Future<List<Shop>> shops({
    String q = '',
    String city = '',
    bool featured = false,
  }) async {
    final json = await _get(
      '/api/shops',
      query: {
        if (q.isNotEmpty) 'q': q,
        if (city.isNotEmpty) 'city': city,
        if (featured) 'featured': 'true',
      },
    );
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => Shop.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<ShopCity>> shopCities() async {
    final json = await _get('/api/shops/cities');
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => ShopCity.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<Shop> shop(int id) async {
    final json = await _get('/api/shops/$id');
    return Shop.fromJson(
      (json['item'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  Future<List<AdItem>> ads({
    String placement = '',
    String category = '',
    bool featured = false,
    int limit = 40,
  }) async {
    final json = await _get(
      '/api/ads',
      query: {
        if (placement.isNotEmpty) 'placement': placement,
        if (category.isNotEmpty) 'category': category,
        if (featured) 'featured': 'true',
        'limit': '$limit',
      },
    );
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => AdItem.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<AdPackage>> adPackages() async {
    final json = await _get('/api/ads/packages');
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => AdPackage.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<void> adClick(int id) async {
    await _send('POST', '/api/ads/$id/click');
  }

  Future<CurrenciesPayload> currencies() async {
    final json = await _get('/api/currencies');
    return CurrenciesPayload.fromJson(json);
  }

  Future<bool> adminLogin(String pin) async {
    final json = await _send('POST', '/api/admin/login', body: {'pin': pin});
    return json['ok'] == true;
  }

  Future<AdminStats> adminStats(String pin) async {
    final json = await _get('/api/admin/stats', headers: _admin(pin));
    return AdminStats.fromJson(json);
  }

  Future<List<Shop>> adminShops(String pin) async {
    final json = await _send('GET', '/api/admin/shops', headers: _admin(pin));
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => Shop.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<List<AdItem>> adminAds(String pin) async {
    final json = await _send('GET', '/api/admin/ads', headers: _admin(pin));
    return (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => AdItem.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<String> uploadImage({
    required String pin,
    required String filename,
    required List<int> bytes,
  }) async {
    final json = await _send(
      'POST',
      '/api/admin/upload',
      headers: _admin(pin),
      body: {'filename': filename, 'data': base64Encode(bytes)},
      timeout: 90,
    );
    return json['url']?.toString() ?? '';
  }

  Future<Shop> saveShop({
    required String pin,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    final json = await _send(
      id == null ? 'POST' : 'PUT',
      id == null ? '/api/admin/shops' : '/api/admin/shops/$id',
      headers: _admin(pin),
      body: data ?? const {},
    );
    return Shop.fromJson(
      (json['item'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  Future<void> deleteShop({required String pin, required int id}) async {
    await _send('DELETE', '/api/admin/shops/$id', headers: _admin(pin));
  }

  Future<AdItem> saveAd({
    required String pin,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    final json = await _send(
      id == null ? 'POST' : 'PUT',
      id == null ? '/api/admin/ads' : '/api/admin/ads/$id',
      headers: _admin(pin),
      body: data ?? const {},
    );
    return AdItem.fromJson(
      (json['item'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  Future<void> deleteAd({required String pin, required int id}) async {
    await _send('DELETE', '/api/admin/ads/$id', headers: _admin(pin));
  }
}
