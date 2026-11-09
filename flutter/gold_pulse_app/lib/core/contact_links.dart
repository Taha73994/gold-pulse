import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// روابط التواصل الخارجية (هاتف / واتساب / تلكرام / بريد).
class ContactLinks {
  static String phone(String value) => 'tel:${_clean(value)}';

  static String whatsapp(String value) {
    var digits = _clean(value);
    if (digits.startsWith('00')) digits = digits.substring(2);
    return 'https://wa.me/$digits';
  }

  static String telegram(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final handle = raw.startsWith('@') ? raw.substring(1) : raw;
    return 'https://t.me/$handle';
  }

  static String email(String value) => 'mailto:${value.trim()}';

  /// يقبل رابطاً كاملاً أو اسم مستخدم/معرّفاً.
  static String facebook(String value) =>
      _social(value, 'https://www.facebook.com/');

  static String instagram(String value) =>
      _social(value, 'https://www.instagram.com/');

  static String tiktok(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final handle = _handle(raw);
    return 'https://www.tiktok.com/@$handle';
  }

  static String _social(String value, String base) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$base${_handle(raw)}';
  }

  static String _handle(String value) {
    var handle = value.trim();
    if (handle.startsWith('@')) handle = handle.substring(1);
    return handle.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  static String _clean(String value) => value.replaceAll(RegExp(r'[^\d+]'), '');
}

Future<void> openExternal(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (_) {
    // تجاهل فشل فتح الرابط على المنصات التي لا تدعمه.
  }
}

/// زر تواصل صغير يعرض أيقونة ونص.
class ContactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const ContactAction({
    super.key,
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openExternal(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
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
