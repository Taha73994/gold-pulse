import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

/// سياسة الخصوصية — نص واضح يطابق ما يجمعه التطبيق فعلاً.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final en = state.en;

    final sections = <(IconData, String, String)>[
      (
        Icons.fingerprint_rounded,
        en ? 'What we collect' : 'ما نجمعه',
        en
            ? '• A random device identifier (device ID) used only to count active users and show the public user counter.\n'
                  '• Anonymous technical data: platform (Android/iOS/Web), app language and app version.\n'
                  '• Your rating and optional note, only if you choose to send them.\n'
                  '• Shop and ad content added by the owner (names, phones, images).'
            : '• معرّف جهاز عشوائي (Device ID) يُستخدم فقط لعدّ المستخدمين النشطين وإظهار عدّاد المستخدمين العام.\n'
                  '• بيانات تقنية مجهولة: المنصة (أندرويد/آيفون/ويب)، لغة التطبيق، وإصدار التطبيق.\n'
                  '• تقييمك وملاحظتك الاختيارية، فقط إذا اخترت إرسالها.\n'
                  '• محتوى المحلات والإعلانات الذي يضيفه المالك (أسماء، هواتف، صور).',
      ),
      (
        Icons.block_rounded,
        en ? 'What we never collect' : 'ما لا نجمعه إطلاقاً',
        en
            ? '• No account, name, email or password.\n'
                  '• No GPS location, contacts, photos, camera or microphone.\n'
                  '• No advertising ID and no cross-app tracking.\n'
                  '• No selling or renting of any data to third parties.'
            : '• لا حساب، لا اسم، لا بريد إلكتروني، لا كلمة مرور.\n'
                  '• لا موقع GPS، لا جهات اتصال، لا صور، لا كاميرا، لا مايكروفون.\n'
                  '• لا معرّف إعلاني ولا تتبّع بين التطبيقات.\n'
                  '• لا بيع أو تأجير أي بيانات لأي طرف ثالث.',
      ),
      (
        Icons.insights_rounded,
        en ? 'How we use the data' : 'كيف نستخدم البيانات',
        en
            ? '• The device ID powers the live user counter and anonymous usage statistics.\n'
                  '• Ratings help the developer improve features and fix problems.\n'
                  '• Shop and ad data is displayed inside the app only.'
            : '• معرّف الجهاز يشغّل عدّاد المستخدمين والإحصاءات المجهولة.\n'
                  '• التقييمات تساعد المطوّر على تحسين الميزات وإصلاح المشاكل.\n'
                  '• بيانات المحلات والإعلانات تُعرض داخل التطبيق فقط.',
      ),
      (
        Icons.cloud_outlined,
        en ? 'Storage and sharing' : 'التخزين والمشاركة',
        en
            ? '• Data is stored on Neon PostgreSQL and the app runs on Vercel.\n'
                  '• Uploaded images are stored in the database and served from /api/media.\n'
                  '• Market prices come from Yahoo Finance, currencies from open.er-api.com and news from Google News RSS. These requests do not include your identity.\n'
                  '• No data is shared with advertisers or brokers.'
            : '• البيانات محفوظة على Neon PostgreSQL والتطبيق يعمل على Vercel.\n'
                  '• الصور المرفوعة تُحفظ في قاعدة البيانات وتُعرض عبر /api/media.\n'
                  '• الأسعار من Yahoo Finance، والعملات من open.er-api.com، والأخبار من Google News RSS. هذه الطلبات لا تحمل هويتك.\n'
                  '• لا تُشارك أي بيانات مع المعلنين أو الوسطاء.',
      ),
      (
        Icons.campaign_outlined,
        en ? 'Ads and shops' : 'الإعلانات والمحلات',
        en
            ? '• Ad views and clicks are counted anonymously to show the owner basic performance.\n'
                  '• Contact buttons (call, WhatsApp, Telegram, email, map) open only when the owner has filled that field.'
            : '• مشاهدات الإعلانات والنقرات تُحصى بشكل مجهول لعرض أداء أساسي للمالك.\n'
                  '• أزرار التواصل (هاتف، واتساب، تلكرام، بريد، خريطة) تظهر فقط إذا عبّأ المالك ذلك الحقل.',
      ),
      (
        Icons.delete_outline_rounded,
        en ? 'Retention and deletion' : 'الاحتفاظ والحذف',
        en
            ? '• The device ID stays until you reset the app settings or uninstall the app.\n'
                  '• Settings → Reset settings removes the local ID and preferences.\n'
                  '• To delete a rating, contact the owner and mention your device ID shown in Settings.'
            : '• معرّف الجهاز يبقى حتى تعيد ضبط إعدادات التطبيق أو تحذف التطبيق.\n'
                  '• الإعدادات ← إعادة ضبط الإعدادات تحذف المعرّف المحلي والتفضيلات.\n'
                  '• لحذف تقييم، تواصل مع المالك واذكر معرّف الجهاز الظاهر في الإعدادات.',
      ),
      (
        Icons.gavel_rounded,
        en ? 'Financial disclaimer' : 'إخلاء المسؤولية المالية',
        en
            ? 'Gold Pulse is a decision-support tool, not investment advice. Prices and forecasts are estimates; always verify with a trusted dealer before buying or selling.'
            : 'نبض الذهب أداة دعم قرار وليست نصيحة استثمارية. الأسعار والتوقعات تقديرية؛ تحقّق دائماً من تاجر موثوق قبل الشراء أو البيع.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.privacyPolicy),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.gold.withValues(alpha: 0.3)),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.surface, c.gold.withValues(alpha: 0.08)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: c.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                en
                                    ? 'Your privacy, in plain language'
                                    : 'خصوصيتك بلغة واضحة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          en
                              ? 'Gold Pulse works without an account. You can use every feature without giving your name or phone number.'
                              : 'نبض الذهب يعمل بدون حساب. يمكنك استخدام كل الميزات دون إعطاء اسمك أو رقم هاتفك.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            height: 1.7,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Pill(
                          text: l.privacyUpdated,
                          color: c.gold,
                          fontSize: 8.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final s in sections) ...[
                    _PrivacyCard(icon: s.$1, title: s.$2, body: s.$3),
                    const SizedBox(height: 9),
                  ],
                  const SizedBox(height: 3),
                  SurfaceCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          en ? 'Contact' : 'التواصل',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          en
                              ? 'For any privacy question or deletion request, use the contact details in the More tab or open an issue on the project page.'
                              : 'لأي سؤال عن الخصوصية أو طلب حذف، استخدم بيانات التواصل في تبويب «المزيد» أو افتح ملاحظة في صفحة المشروع.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            height: 1.7,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l.copyright,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: c.muted,
                      ),
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

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: c.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: c.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    height: 1.75,
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
