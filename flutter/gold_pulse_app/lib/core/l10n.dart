import 'package:intl/intl.dart';

/// جميع نصوص الواجهة بالعربية والإنجليزية.
class L10n {
  final bool en;
  const L10n(this.en);

  static const supported = ['ar', 'en'];

  String pick(String ar, String english) => en ? english : ar;

  // ── الهوية ─────────────────────────────────────────────
  String get appName => en ? 'Gold Pulse' : 'نبض الذهب';
  String get tagline =>
      en ? 'Your gold market guide in Iraq' : 'مرشدك لسوق الذهب في العراق';
  String get owner => 'Taha Ali';
  String get copyright => en
      ? '© 2026 Taha Ali — All rights reserved'
      : '\u202A© 2026 Taha Ali\u202C — جميع الحقوق محفوظة';

  // ── التنقل ─────────────────────────────────────────────
  String get navHome => en ? 'Home' : 'الرئيسية';
  String get navMarket => en ? 'Market' : 'السوق';
  String get navMentor => en ? 'Mentor' : 'المستشار';
  String get navShops => en ? 'Shops' : 'المحلات';
  String get navMore => en ? 'More' : 'المزيد';
  String get home => en ? 'Home' : 'الرئيسية';
  String get market => en ? 'Market' : 'السوق';
  String get calculator => en ? 'Calculator' : 'الحاسبة';
  String get news => en ? 'News' : 'الأخبار';
  String get alerts => en ? 'Alerts' : 'التنبيهات';
  String get shops => en ? 'Gold shops' : 'محلات الذهب';
  String get ads => en ? 'Marketplace' : 'الإعلانات';
  String get currencies => en ? 'Currencies' : 'تحويل العملات';
  String get settings => en ? 'Settings' : 'الإعدادات';
  String get about => en ? 'About' : 'حول التطبيق';
  String get admin => en ? 'Owner dashboard' : 'لوحة المالك';
  String get mentor => en ? 'Mentor' : 'المستشار';
  String get more => en ? 'More' : 'المزيد';
  String get tools => en ? 'Tools' : 'الأدوات';
  String get community => en ? 'Community' : 'المجتمع';

  // ── عام ────────────────────────────────────────────────
  String get live => en ? 'LIVE' : 'مباشر';
  String get updated => en ? 'Updated' : 'آخر تحديث';
  String get refresh => en ? 'Refresh' : 'تحديث';
  String get retry => en ? 'Retry' : 'إعادة المحاولة';
  String get loading => en ? 'Loading…' : 'جارٍ التحميل…';
  String get close => en ? 'Close' : 'إغلاق';
  String get ok => en ? 'OK' : 'حسناً';
  String get cancel => en ? 'Cancel' : 'إلغاء';
  String get save => en ? 'Save' : 'حفظ';
  String get saved => en ? 'Saved' : 'تم الحفظ';
  String get delete => en ? 'Delete' : 'حذف';
  String get edit => en ? 'Edit' : 'تعديل';
  String get add => en ? 'Add' : 'إضافة';
  String get search => en ? 'Search' : 'بحث';
  String get all => en ? 'All' : 'الكل';
  String get viewAll => en ? 'View all' : 'عرض الكل';
  String get optional => en ? 'Optional' : 'اختياري';
  String get yes => en ? 'Yes' : 'نعم';
  String get no => en ? 'No' : 'لا';
  String get call => en ? 'Call' : 'اتصال';
  String get whatsapp => 'WhatsApp';
  String get map => en ? 'Map' : 'الخريطة';
  String get noData => en ? 'No data available' : 'لا توجد بيانات';
  String get connectionError =>
      en ? 'Could not connect to the server' : 'تعذر الاتصال بالخادم';
  String get offlineHint => en
      ? 'Check the API address in Settings, or try again.'
      : 'تحقق من عنوان الخادم في الإعدادات أو أعد المحاولة.';
  String get showAll => en ? 'Show all' : 'عرض الكل';
  String get less => en ? 'Less' : 'أقل';
  String get copy => en ? 'Copy' : 'نسخ';
  String get copied => en ? 'Copied' : 'تم النسخ';
  String get minutes => en ? 'min' : 'دقيقة';
  String get hours => en ? 'h' : 'ساعة';
  String get days => en ? 'days' : 'يوم';
  String get perDay => en ? '/ day' : '/ يوم';

  // ── الأسعار ────────────────────────────────────────────
  String get usdOz => en ? 'USD / ounce' : 'دولار / أونصة';
  String get iqdGram => en ? 'IQD / gram' : 'دينار / غرام';
  String get goldPrice => en ? 'Gold price' : 'سعر الذهب';
  String get todayChange => en ? 'Today' : 'اليوم';
  String get openLabel => en ? 'Open' : 'الافتتاح';
  String get highLabel => en ? 'High' : 'أعلى';
  String get lowLabel => en ? 'Low' : 'أدنى';
  String get prevClose => en ? 'Prev. close' : 'الإغلاق السابق';
  String get usdIqdLabel => en ? 'USD / IQD' : 'دولار / دينار';
  String get volatility => en ? '20d volatility' : 'تقلب 20 يوم';
  String get karat => en ? 'Karat' : 'العيار';
  String get karat24 => en ? '24K' : '24';
  String get karat22 => en ? '22K' : '22';
  String get karat21 => en ? '21K' : '21';
  String get karat18 => en ? '18K' : '18';
  String get gram => en ? 'gram' : 'غرام';
  String get ounce => en ? 'ounce' : 'أونصة';
  String get priceSource =>
      en ? 'Source: Yahoo Finance' : 'المصدر: Yahoo Finance';
  String get fxSource => en ? 'FX: open.er-api.com' : 'الصرف: open.er-api.com';
  String get priceNote => en
      ? 'Global USD/oz price. The dinar price is an estimate based on the published FX rate and differs from local market prices.'
      : 'السعر العالمي بالدولار للأونصة. سعر الدينار تقديري حسب سعر الصرف المعلن ويختلف عن سوق المحلات.';
  String get changeToday => en ? 'change today' : 'تغير اليوم';
  String get iraqLocalTitle => en ? 'Iraqi market price' : 'سعر السوق العراقي';
  String get iraqLocalSubtitle => en
      ? 'Selling and buying price per gram vs the screen price'
      : 'سعر البيع والشراء للغرام مقابل سعر الشاشة';
  String get localSellPrice => en ? 'Selling price' : 'سعر البيع';
  String get localSellHint =>
      en ? 'You buy at this price' : 'أنت تشتري بهذا السعر';
  String get localBuyPrice => en ? 'Buying price' : 'سعر الشراء';
  String get localBuyHint =>
      en ? 'You sell at this price' : 'أنت تبيع بهذا السعر';
  String get screenPrice => en ? 'Screen price' : 'سعر الشاشة';
  String get screenHint => en ? 'Global reference' : 'السعر العالمي المرجعي';
  String get localSpread => en ? 'Spread' : 'الفرق';
  String get localSpreadHint => en ? 'Ask − bid' : 'بيع − شراء';
  String get localEstimateNote => en
      ? 'Estimate using the local market margin; it differs from one dealer to another.'
      : 'تقدير حسب هامش السوق المحلي، ويختلف من محل لآخر.';

  // ── سعر الصرف (السوق الموازي) ─────────────────────────
  String get rateTitle => en ? 'USD exchange rate' : 'سعر صرف الدولار';
  String get rateSubtitle => en
      ? 'Parallel market (Kifah) vs the official rate'
      : 'السوق الموازي (الكفاح) مقابل السعر الرسمي';
  String get parallelMarket => en ? 'Parallel market' : 'السوق الموازي';
  String get blackMarketHint => en
      ? 'The black market rate Iraq actually trades at'
      : 'سعر السوق السوداء الذي يتعامل به السوق العراقي';
  String get officialCbi =>
      en ? 'Official (Central Bank)' : 'السعر الرسمي (البنك المركزي)';
  String get perDollar => en ? 'IQD / USD' : 'د.ع / دولار';
  String get rateGap => en ? 'Gap vs official' : 'الفارق عن الرسمي';
  String get rateToday => en ? 'Today' : 'تغير اليوم';
  String get rateSellShort => en ? 'Sell' : 'بيع';
  String get rateBuyShort => en ? 'Buy' : 'شراء';
  String get goldUsesParallel => en
      ? 'Gold prices in Iraq are calculated at the parallel market rate.'
      : 'سعر الذهب في العراق محسوب بسعر صرف السوق الموازي.';
  String get rateEstimated => en
      ? 'Temporary estimate: the market feed is unavailable, so the official rate plus a margin is used.'
      : 'تقدير مؤقت: تعذر جلب سعر السوق، لذا استُخدم السعر الرسمي مضافاً إليه هامش.';
  String get rateUpdated => en ? 'Updated' : 'آخر تحديث';
  String get rateSource => en ? 'Source' : 'المصدر';
  String get parallelDollarShort => en ? 'Market USD' : 'دولار السوق';
  String get officialGram24 => en ? 'Official 24K gram' : 'غرام 24 رسمي';

  // ── وحدة العرض (دولار / دينار) ────────────────────────
  String get displayUnit => en ? 'Display currency' : 'عملة العرض';
  String get usdUnit => en ? 'USD' : 'دولار';
  String get iqdUnit => en ? 'IQD' : 'دينار';
  String get ouncePrice => en ? 'Gold ounce' : 'سعر الأونصة';
  String get mithqal => en ? 'Mithqal' : 'المثقال';
  String get mithqal21 => en ? 'Mithqal 21K (5 g)' : 'المثقال 21 (5 غرام)';
  String get mithqal24 => en ? 'Mithqal 24K (5 g)' : 'المثقال 24 (5 غرام)';
  String get mithqalNote =>
      en ? 'The Iraqi mithqal is 5 grams.' : 'المثقال العراقي يساوي 5 غرامات.';
  String get priceInParallel => en
      ? 'Calculated at the parallel market rate'
      : 'محسوب بسعر السوق الموازي';
  String get ounceIqdNote => en
      ? 'Ounce in dinars at the parallel rate'
      : 'الأونصة بالدينار على سعر السوق الموازي';
  String get autoRefreshEvery =>
      en ? 'Auto-refresh every 20s' : 'تحديث تلقائي كل 20 ثانية';
  String get nextUpdate => en ? 'Next update' : 'التحديث القادم';
  String get inSeconds => en ? 's' : 'ث';
  String get goldNow => en ? 'Gold now' : 'الذهب الآن';
  String get rateNow => en ? 'Market dollar' : 'دولار السوق';
  String get dailyRange => en ? 'Daily range' : 'نطاق اليوم';
  String get priceAtAlert => en ? 'Price at alert' : 'السعر وقت التنبيه';

  // ── الإشارة ────────────────────────────────────────────
  String get signal => en ? 'Signal' : 'الإشارة';
  String get todaySignal => en ? "Today's signal" : 'إشارة اليوم';
  String get confidence => en ? 'Confidence' : 'الثقة';
  String get score => en ? 'Score' : 'الدرجة';
  String get horizon => en ? 'Horizon' : 'الأفق';
  String get verdict => en ? 'Should I buy?' : 'هل أشتري؟';
  String get plan => en ? 'The plan' : 'الخطة';
  String get weeklyPlan => en ? 'Weekly plan' : 'خطة الأسبوع';
  String get entryZone => en ? 'Entry zone' : 'منطقة الدخول';
  String get target1 => en ? 'Target 1' : 'الهدف الأول';
  String get target2 => en ? 'Target 2' : 'الهدف الثاني';
  String get stopLoss => en ? 'Stop / invalidation' : 'وقف الخسارة';
  String get support => en ? 'Support' : 'الدعم';
  String get resistance => en ? 'Resistance' : 'المقاومة';
  String get riskReward => en ? 'Risk / reward' : 'المخاطرة / العائد';
  String get reasons => en ? 'Why this signal?' : 'لماذا هذه الإشارة؟';
  String get technical => en ? 'Technical' : 'فني';
  String get macro => en ? 'Macro' : 'اقتصاد كلي';
  String get methodology => en ? 'Methodology' : 'المنهجية';
  String get disclaimer => en ? 'Disclaimer' : 'إخلاء المسؤولية';
  String get regime => en ? 'Market regime' : 'حالة السوق';
  String get overextension => en ? 'Stretch warning' : 'تحذير التمدد';
  String get shortTerm =>
      en ? 'Short term (1–3 days)' : 'قصير المدى (1–3 أيام)';
  String get swingTerm => en ? 'Swing (1–3 weeks)' : 'متوسط المدى (1–3 أسابيع)';
  String get overall => en ? 'Overall' : 'الإجمالي';
  String get levels => en ? 'Key levels' : 'المستويات المهمة';
  String get catalysts => en ? 'Catalysts to watch' : 'محفزات للمراقبة';
  String get noSignal => en ? 'Signal unavailable' : 'الإشارة غير متاحة';
  String get whatNow => en ? 'What do I do now?' : 'ماذا أفعل الآن؟';
  String get clearNotes => en ? 'Clear notes' : 'ملاحظات واضحة';
  String get changeDecision => en ? 'Reconsider if' : 'أعد النظر إذا';
  String get avoidNow => en ? 'Avoid now' : 'تجنّب الآن';

  String action(String code) {
    switch (code) {
      case 'BUY':
        return en ? 'Buy' : 'شراء';
      case 'ACCUMULATE':
        return en ? 'Accumulate' : 'تجميع تدريجي';
      case 'SELL':
        return en ? 'Sell' : 'بيع';
      case 'REDUCE':
        return en ? 'Reduce' : 'تخفيف';
      default:
        return en ? 'Wait & watch' : 'انتظار ومراقبة';
    }
  }

  String bias(String key) {
    switch (key) {
      case 'BUY':
      case 'ACCUMULATE':
        return en ? 'Bullish bias' : 'تحيز صاعد';
      case 'SELL':
      case 'REDUCE':
        return en ? 'Bearish bias' : 'تحيز هابط';
      default:
        return en ? 'Neutral bias' : 'تحيز محايد';
    }
  }

  // ── المستشار ───────────────────────────────────────────
  String get mentorTitle =>
      en ? 'Your gold trading mentor' : 'مرشدك في تداول الذهب';
  String get mentorSubtitle => en
      ? 'A rules-based mentor: scenarios, risk limits and discipline — not fortune telling.'
      : 'مرشد يعمل بقواعد التداول: سيناريوهات وحدود مخاطرة وانضباط — وليس ضرباً بالغيب.';
  String get mentorIntro => en
      ? 'Think like a professional: protect capital first, then look for profit.'
      : 'فكّر كمضارب محترف: احمِ رأس المال أولاً، ثم ابحث عن الربح.';
  String get todayStance => en ? "Today's stance" : 'موقف اليوم';
  String get conviction => en ? 'Conviction' : 'قوة القناعة';
  String get keyLevels => en ? 'Levels that matter' : 'المستويات التي تهم';
  String get scenarios => en ? 'If / then scenarios' : 'سيناريوهات إذا / فإن';
  String get rules => en ? 'Risk rules' : 'قواعد إدارة المخاطرة';
  String get checklist =>
      en ? 'Pre-trade checklist' : 'قائمة التحقق قبل الدخول';
  String get mistakes => en ? 'Mistakes to avoid now' : 'أخطاء يجب تجنبها الآن';
  String get timing => en ? 'Execution timing' : 'توقيت التنفيذ';
  String get mentorNote =>
      en ? 'How a pro would play it' : 'كيف يلعبها المحترف';
  String get trigger => en ? 'Trigger' : 'المحفز';
  String get actionLabel => en ? 'Action' : 'الإجراء';
  String get targetLabel => en ? 'Target' : 'الهدف';
  String get riskLabel => en ? 'Risk' : 'الخطر';
  String get passed => en ? 'Passed' : 'متحقق';
  String get needsAttention => en ? 'Needs attention' : 'يحتاج انتباه';
  String get readMentor => en ? 'Open the mentor' : 'افتح المستشار';
  String get mentorShort => en ? "Trader's note" : 'نصيحة المضارب';

  // ── الأخبار ────────────────────────────────────────────
  String get newsCenter => en ? 'News center' : 'مركز الأخبار';
  String get newsSummary => en ? 'News sentiment' : 'معنويات الأخبار';
  String get positive => en ? 'Positive' : 'إيجابي';
  String get negative => en ? 'Negative' : 'سلبي';
  String get neutral => en ? 'Neutral' : 'محايد';
  String get articles => en ? 'articles' : 'خبراً';
  String get sources => en ? 'sources' : 'مصدراً';
  String get openArticle => en ? 'Open article' : 'فتح الخبر';
  String get noNews => en ? 'No news right now' : 'لا توجد أخبار حالياً';
  String get whyItMatters => en ? 'Why it matters' : 'لماذا يهم';
  String get sentiment => en ? 'Sentiment' : 'المعنويات';
  String get bullishForGold => en ? 'Bullish for gold' : 'إيجابي للذهب';
  String get bearishForGold => en ? 'Bearish for gold' : 'سلبي للذهب';
  String get neutralForGold => en ? 'Neutral' : 'محايد';
  String get newsLangNote => en
      ? 'Headlines keep their original language; labels and analysis are translated.'
      : 'عناوين الأخبار تبقى بلغتها الأصلية، أما التصنيفات والتحليل فمترجمة.';

  String category(String code) {
    switch (code) {
      case 'fed':
        return en ? 'Fed & rates' : 'الفيدرالي والفائدة';
      case 'inflation':
        return en ? 'Inflation' : 'التضخم';
      case 'jobs':
        return en ? 'Jobs' : 'الوظائف';
      case 'election':
        return en ? 'Elections' : 'الانتخابات';
      case 'geopolitics':
        return en ? 'Geopolitics' : 'الجيوسياسة';
      case 'dollar':
        return en ? 'Dollar' : 'الدولار';
      case 'technical':
        return en ? 'Technical' : 'تحليل فني';
      default:
        return en ? 'General' : 'سوق عام';
    }
  }

  String impact(String code) {
    switch (code) {
      case 'high':
        return en ? 'High impact' : 'تأثير عالٍ';
      case 'medium':
        return en ? 'Medium impact' : 'تأثير متوسط';
      default:
        return en ? 'Low impact' : 'تأثير منخفض';
    }
  }

  // ── الحاسبة ────────────────────────────────────────────
  String get goldCalculator => en ? 'Gold calculator' : 'حاسبة الذهب';
  String get calculatorSubtitle => en
      ? 'Work out the real cost including making charges, commission and dealer margin.'
      : 'احسب التكلفة الحقيقية مع أجور الصياغة والعمولة وهامش التاجر.';
  String get weight => en ? 'Weight (grams)' : 'الوزن (غرام)';
  String get makingPerGram =>
      en ? 'Making charge / gram' : 'أجرة الصياغة / غرام';
  String get commissionPct => en ? 'Commission %' : 'العمولة %';
  String get marginPct => en ? 'Dealer margin %' : 'هامش التاجر %';
  String get buybackPct => en ? 'Buyback discount %' : 'خصم إعادة البيع %';
  String get calculate => en ? 'Calculate' : 'احسب';
  String get reset => en ? 'Reset' : 'تصفير';
  String get goldValue => en ? 'Gold value' : 'قيمة الذهب';
  String get makingCost => en ? 'Making charges' : 'أجور الصياغة';
  String get commissionCost => en ? 'Commission' : 'العمولة';
  String get marginCost => en ? 'Dealer margin' : 'هامش التاجر';
  String get totalPrice => en ? 'Total price' : 'السعر الإجمالي';
  String get finalPerGram => en ? 'Final price / gram' : 'السعر النهائي / غرام';
  String get buybackValue =>
      en ? 'Estimated buyback' : 'قيمة إعادة البيع التقديرية';
  String get calculatorNote => en
      ? 'Estimates only. Iraqi shops quote 21K most often; always confirm the day rate and the making charge in person.'
      : 'تقديرات فقط. أغلب المحلات العراقية تسعّر عيار 21، تأكد من سعر اليوم وأجرة الصياغة في المحل.';
  String get pricePerGram24 => en ? '24K price / gram' : 'سعر الغرام عيار 24';
  String get useLivePrice => en ? 'Use live price' : 'استخدم السعر الحي';
  String get quantity => en ? 'Quantity' : 'الكمية';
  String get unitPrice => en ? 'Unit price' : 'سعر الوحدة';
  String get goldWeightHint => en ? 'e.g. 10.5' : 'مثال 10.5';

  // ── المحلات ────────────────────────────────────────────
  String get shopsDirectory => en ? 'Gold shops directory' : 'دليل محلات الذهب';
  String get shopsSubtitle => en
      ? 'Verified addresses, phones and map locations.'
      : 'عناوين وأرقام هواتف ومواقع على الخريطة.';
  String get searchShops =>
      en ? 'Search shop or city…' : 'ابحث عن محل أو مدينة…';
  String get allCities => en ? 'All cities' : 'كل المدن';
  String get featured => en ? 'Featured' : 'مميز';
  String get verified => en ? 'Verified' : 'موثّق';
  String get workingHours => en ? 'Working hours' : 'أوقات العمل';
  String get address => en ? 'Address' : 'العنوان';
  String get phone => en ? 'Phone' : 'الهاتف';
  String get openMap => en ? 'Open in Maps' : 'افتح الخريطة';
  String get noShops => en ? 'No shops listed yet' : 'لا توجد محلات مضافة بعد';
  String get noShopsHint => en
      ? 'The owner can add the first shop from the dashboard.'
      : 'يمكن للمالك إضافة أول محل من لوحة التحكم.';
  String get addYourShop => en ? 'Add your shop' : 'أضف محلك';
  String get shopDetails => en ? 'Shop details' : 'تفاصيل المحل';
  String get views => en ? 'views' : 'مشاهدة';
  String get nearby => en ? 'Nearby' : 'قريب مني';
  String get cities => en ? 'Cities' : 'المدن';
  String get noPhone => en ? 'No phone number' : 'لا يوجد رقم هاتف';

  // ── الإعلانات ──────────────────────────────────────────
  String get marketplace => en ? 'Gold marketplace' : 'سوق الذهب والإعلانات';
  String get marketplaceSubtitle => en
      ? 'Products, services and offers from gold shops.'
      : 'منتجات وخدمات وعروض من محلات الذهب.';
  String get featuredAds => en ? 'Featured offers' : 'عروض مميزة';
  String get adPackages => en ? 'Ad packages' : 'باقات الإعلان';
  String get advertiseHere => en ? 'Advertise here' : 'أعلن هنا';
  String get advertiseSubtitle => en
      ? 'Put your shop or product in front of gold buyers in Iraq.'
      : 'ضع محلك أو منتجك أمام مشتري الذهب في العراق.';
  String get postAd => en ? 'Post an ad' : 'أضف إعلاناً';
  String get noAds => en ? 'No ads yet' : 'لا توجد إعلانات بعد';
  String get noAdsHint => en
      ? 'Featured offers will appear here once the owner adds them.'
      : 'ستظهر العروض المميزة هنا بعد إضافتها من لوحة المالك.';
  String get price => en ? 'Price' : 'السعر';
  String get priceOnRequest => en ? 'Price on request' : 'السعر عند الطلب';
  String get daysLeft => en ? 'days left' : 'يوم متبقٍ';
  String get viewsCount => en ? 'views' : 'مشاهدة';
  String get clicksCount => en ? 'clicks' : 'نقرة';
  String get callNow => en ? 'Call now' : 'اتصل الآن';
  String get visitLink => en ? 'Open link' : 'فتح الرابط';
  String get adDetails => en ? 'Ad details' : 'تفاصيل الإعلان';
  String get sponsored => en ? 'Sponsored' : 'إعلان ممول';
  String get adNote => en
      ? 'Ads are paid placements. Verify the seller and the product before paying.'
      : 'الإعلانات مدفوعة. تحقق من البائع والمنتج قبل الدفع.';
  String get choosePackage => en ? 'Choose a package' : 'اختر الباقة';
  String get contactAds => en ? 'Contact the owner' : 'تواصل مع الإدارة';
  String get contactNotSet => en
      ? 'Contact details are not configured yet.'
      : 'لم تُضف بيانات التواصل بعد.';
  String get categoryLabel => en ? 'Category' : 'التصنيف';
  String get placement => en ? 'Placement' : 'مكان الظهور';
  String get packageLabel => en ? 'Package' : 'الباقة';
  String get active => en ? 'Active' : 'مفعّل';
  String get inactive => en ? 'Inactive' : 'موقوف';
  String get expires => en ? 'Expires' : 'ينتهي';
  String get stats => en ? 'Statistics' : 'الإحصائيات';

  // ── العملات ────────────────────────────────────────────
  String get currencyConverter => en ? 'Currency converter' : 'تحويل العملات';
  String get currencySubtitle => en
      ? 'USD, Iraqi dinar, Iranian toman, Turkish lira and more.'
      : 'دولار، دينار عراقي، تومان إيراني، ليرة تركية وأكثر.';
  String get amount => en ? 'Amount' : 'المبلغ';
  String get from => en ? 'From' : 'من';
  String get to => en ? 'To' : 'إلى';
  String get swap => en ? 'Swap' : 'تبديل';
  String get result => en ? 'Result' : 'النتيجة';
  String get exchangeRate => en ? 'Exchange rate' : 'سعر الصرف';
  String get ratesTable => en ? 'Rates per 1 USD' : 'الأسعار مقابل 1 دولار';
  String get currency => en ? 'Currency' : 'العملة';
  String get perUsd => en ? 'Per USD' : 'لكل دولار';
  String get goldGramIn => en ? '24K gold gram in' : 'غرام الذهب 24 بـ';
  String get currencyNote => en
      ? 'Indicative global rates. Local Iraqi market rates may differ slightly.'
      : 'أسعار عالمية استرشادية. سعر السوق العراقي المحلي قد يختلف قليلاً.';
  String get lastUpdated => en ? 'Last updated' : 'آخر تحديث';
  String get toman => en ? 'Toman' : 'تومان';
  String get lira => en ? 'Lira' : 'ليرة';

  // ── التنبيهات ──────────────────────────────────────────
  String get alertCenter => en ? 'Alert center' : 'مركز التنبيهات';
  String get unread => en ? 'unread' : 'غير مقروء';
  String get markAllRead => en ? 'Mark all read' : 'تعليم الكل كمقروء';
  String get noAlerts => en ? 'No alerts yet' : 'لا توجد تنبيهات بعد';
  String get noAlertsHint => en
      ? 'You will be alerted when the signal changes or gold moves materially.'
      : 'ستصلك تنبيهات عند تغيّر الإشارة أو تحرك الذهب بشكل مؤثر.';
  String get alertGuide => en ? 'How to use alerts' : 'كيف تستخدم التنبيهات';
  String get alertGuide1 => en
      ? 'When the signal changes to BUY, prepare a staged entry — do not buy everything at once.'
      : 'عند تحول الإشارة إلى شراء، جهّز دخولاً على دفعات — لا تشترِ كل المبلغ مرة واحدة.';
  String get alertGuide2 => en
      ? 'When the signal changes to SELL or REDUCE, review your stop and trim risk.'
      : 'عند تحول الإشارة إلى بيع أو تخفيف، راجع وقف الخسارة وقلّل المخاطرة.';
  String get alertGuide3 => en
      ? 'Price alerts above 1.5% tell you to check the reason before acting.'
      : 'تنبيهات الحركة فوق 1.5% تطلب منك معرفة السبب قبل التصرف.';
  String get alertGuide4 => en
      ? 'Exchange-rate alerts fire when the parallel dollar moves enough to change gold prices.'
      : 'تنبيهات سعر الصرف تصل عند تحرك دولار السوق الموازي بما يؤثر على سعر الذهب.';
  String get signalHistory => en ? 'Signal history' : 'سجل الإشارات';
  String get markRead => en ? 'Mark read' : 'تعليم كمقروء';
  String get priceAlert => en ? 'Price move' : 'حركة سعر';
  String get signalAlert => en ? 'Signal change' : 'تغير إشارة';
  String get momentumAlert => en ? 'Momentum' : 'زخم';
  String get rateAlert => en ? 'Exchange rate' : 'سعر الصرف';
  String get systemAlert => en ? 'System' : 'النظام';

  // ── مركز التنبيهات الذهبي ─────────────────────────────
  String get alertsHeroTitle =>
      en ? 'Clear gold alerts' : 'تنبيهات ذهبية واضحة';
  String get alertsHeroHint => en
      ? 'Gold and the parallel dollar are checked automatically every 20 seconds.'
      : 'الذهب ودولار السوق يُفحصان تلقائياً كل 20 ثانية.';
  String get alertsLive => en ? 'Alerts active' : 'التنبيهات تعمل';
  String get latestAlert => en ? 'Latest alert' : 'أحدث تنبيه';
  String get alertSound => en ? 'Alert sound' : 'صوت التنبيه';
  String get alertSoundNote => en
      ? 'A short gold chime plays inside the app when a new alert arrives.'
      : 'تُشغّل نغمة ذهبية قصيرة داخل التطبيق عند وصول تنبيه جديد.';
  String get notifications => en ? 'System notifications' : 'إشعارات النظام';
  String get notificationsNote => en
      ? 'Shows the alert as a phone notification with sound while the app is running in the background.'
      : 'تظهر التنبيه كإشعار على الهاتف مع الصوت أثناء عمل التطبيق في الخلفية.';
  String get notificationsBlocked => en
      ? 'Allow notifications from the phone settings to receive them.'
      : 'اسمح بالإشعارات من إعدادات الهاتف لتصلك التنبيهات.';
  String get alertSettings => en ? 'Alert settings' : 'إعدادات التنبيهات';
  String get testAlert => en ? 'Test alert' : 'تجربة التنبيه';
  String get details => en ? 'Details' : 'التفاصيل';
  String get whatToDo => en ? 'What should I do?' : 'ماذا أفعل؟';
  String get understood => en ? 'Got it' : 'فهمت';
  String get targetPrice => en ? 'My target price' : 'هدفي السعري';
  String get targetPriceNote => en
      ? 'Alert me when the gold ounce reaches this price (in dinars at the parallel rate).'
      : 'نبّهني عندما تصل الأونصة إلى هذا السعر (بالدينار على سعر السوق الموازي).';
  String get clearTarget => en ? 'Clear target' : 'مسح الهدف';
  String get setTarget => en ? 'Set target' : 'تحديد الهدف';
  String get targetReached => en ? 'Target reached' : 'تم الوصول للهدف';
  String get noTarget => en ? 'No target set' : 'لا يوجد هدف محدد';
  String get severityHigh => en ? 'High priority' : 'أولوية عالية';
  String get severityMedium => en ? 'Medium' : 'متوسط';
  String get severityInfo => en ? 'Info' : 'معلومة';
  String get unreadOnly => en ? 'Unread' : 'غير مقروء';
  String get allKinds => en ? 'All' : 'الكل';
  String get noFilterResults =>
      en ? 'No alerts match this filter.' : 'لا توجد تنبيهات تطابق هذا الفلتر.';
  String get alertTipGold => en
      ? 'Gold alerts are generated from real market moves, not promotional messages.'
      : 'تنبيهات الذهب مبنية على حركة سوق حقيقية وليست رسائل دعائية.';
  String get alertTipRate => en
      ? 'When the parallel dollar moves, gold prices in Iraq move with it.'
      : 'عندما يتحرك دولار السوق الموازي يتحرك معه سعر الذهب في العراق.';
  String get openAlertCenter => en ? 'Open alert center' : 'فتح مركز التنبيهات';

  String kind(String code) {
    switch (code) {
      case 'signal':
        return signalAlert;
      case 'price':
        return priceAlert;
      case 'momentum':
        return momentumAlert;
      case 'rate':
        return rateAlert;
      default:
        return systemAlert;
    }
  }

  // ── المستخدمون ────────────────────────────────────────
  String get activeUsers => en ? 'Active users' : 'المستخدمون الفعليون';
  String get onlineNow => en ? 'Online now' : 'متصل الآن';
  String get activeToday => en ? 'Active today' : 'نشط اليوم';
  String get activeWeek => en ? 'Active this week' : 'نشط هذا الأسبوع';
  String get activeMonth => en ? 'Active this month' : 'نشط هذا الشهر';
  String get totalUsers => en ? 'Total users' : 'إجمالي المستخدمين';
  String get usersNote => en
      ? 'Counted from anonymous app heartbeats. No names or personal data.'
      : 'تُحسب من نبضات التطبيق المجهولة، دون أسماء أو بيانات شخصية.';
  String get usersLiveHint => en
      ? 'Updates automatically while the app is open.'
      : 'تتحدث تلقائياً أثناء فتح التطبيق.';
  String get ownerOnly => en ? 'Owner only' : 'للمالك فقط';
  String get userDetails => en ? 'User details' : 'تفاصيل المستخدمين';
  String get platformsLabel => en ? 'Platforms' : 'المنصات';
  String get languagesLabel => en ? 'Languages' : 'اللغات';
  String get versionsLabel => en ? 'App versions' : 'نسخ التطبيق';
  String get newToday => en ? 'New today' : 'جديد اليوم';
  String get publicStatsNote => en
      ? 'The total user count is public. Detailed breakdowns are visible to the owner only.'
      : 'العدد الكلي للمستخدمين ظاهر للجميع، أما التفاصيل فتُعرض للمالك فقط.';

  // ── الخصوصية والتقييم ──────────────────────────────────
  String get privacyPolicy => en ? 'Privacy policy' : 'سياسة الخصوصية';
  String get privacyUpdated =>
      en ? 'Last updated: November 2026' : 'آخر تحديث: تشرين الثاني 2026';
  String get rateApp => en ? 'Rate the app' : 'قيّم التطبيق';
  String get ratingTitle =>
      en ? 'How is your experience?' : 'كيف تجربتك مع التطبيق؟';
  String get ratingSubtitle => en
      ? 'Your rating helps us improve the app.'
      : 'تقييمك يساعدنا على تحسين التطبيق.';
  String get rateCommentHint =>
      en ? 'A note for the developer (optional)' : 'ملاحظة للمطوّر (اختياري)';
  String get rateSend => en ? 'Send rating' : 'إرسال التقييم';
  String get rateThanks =>
      en ? 'Thank you! Your rating was saved.' : 'شكراً لك! تم حفظ تقييمك.';
  String get rateError => en
      ? 'Could not send the rating. Try again.'
      : 'تعذر إرسال التقييم. حاول مرة أخرى.';
  String get rateChange => en ? 'Change my rating' : 'تغيير تقييمي';
  String get valuesTitle => en ? 'Our values' : 'قيم التطبيق';

  // ── الإعدادات ──────────────────────────────────────────
  String get language => en ? 'Language' : 'اللغة';
  String get arabic => 'العربية';
  String get english => 'English';
  String get theme => en ? 'Appearance' : 'المظهر';
  String get systemTheme => en ? 'System' : 'النظام';
  String get lightTheme => en ? 'Light' : 'نهاري';
  String get darkTheme => en ? 'Dark' : 'ليلي';
  String get resetSettings => en ? 'Reset settings' : 'إعادة ضبط الإعدادات';
  String get connectionFailed => en ? 'Connection failed' : 'فشل الاتصال';
  String get resetConfirm => en
      ? 'Reset language, theme and display settings?'
      : 'إعادة ضبط اللغة والمظهر وإعدادات العرض؟';
  String get autoRefresh => en ? 'Auto refresh' : 'التحديث التلقائي';
  String get autoRefreshNote => en
      ? 'Prices every 2 minutes, analysis every 10 minutes.'
      : 'الأسعار كل دقيقتين، والتحليل كل 10 دقائق.';
  String get privacy => en ? 'Privacy' : 'الخصوصية';
  String get privacyNote => en
      ? 'A random device identifier is used only to count active users.'
      : 'يُستخدم معرّف جهاز عشوائي فقط لعدّ المستخدمين النشطين.';
  String get developer => en ? 'Developer' : 'المطوّر';

  // ── لوحة المالك ────────────────────────────────────────
  String get ownerLogin => en ? 'Owner login' : 'دخول المالك';
  String get enterPin => en ? 'Enter owner PIN' : 'أدخل رمز المالك';
  String get pinHint => en
      ? 'Enter the private owner PIN. Only the app owner can open this dashboard.'
      : 'أدخل رمز المالك الخاص. هذه اللوحة مخصّصة لمالك التطبيق فقط.';
  String get login => en ? 'Login' : 'دخول';
  String get logout => en ? 'Logout' : 'خروج';
  String get wrongPin => en ? 'Wrong PIN' : 'الرمز غير صحيح';
  String get dashboard => en ? 'Dashboard' : 'لوحة التحكم';
  String get overview => en ? 'Overview' : 'نظرة عامة';
  String get manageShops => en ? 'Manage shops' : 'إدارة المحلات';
  String get manageAds => en ? 'Manage ads' : 'إدارة الإعلانات';
  String get addNew => en ? 'Add new' : 'إضافة جديد';
  String get deleteConfirm =>
      en ? 'Are you sure you want to delete?' : 'هل أنت متأكد من الحذف؟';
  String get revenue =>
      en ? 'Estimated ad revenue' : 'إيرادات الإعلانات التقديرية';
  String get totalShops => en ? 'Shops' : 'المحلات';
  String get totalAds => en ? 'Ads' : 'الإعلانات';
  String get totalAlerts => en ? 'Alerts' : 'التنبيهات';
  String get signals => en ? 'Signals' : 'الإشارات';
  String get shopName => en ? 'Shop name (Arabic)' : 'اسم المحل (عربي)';
  String get shopNameEn => en ? 'Shop name (English)' : 'اسم المحل (إنجليزي)';
  String get cityLabel => en ? 'City (Arabic)' : 'المدينة (عربي)';
  String get cityEnLabel => en ? 'City (English)' : 'المدينة (إنجليزي)';
  String get addressLabel => en ? 'Address (Arabic)' : 'العنوان (عربي)';
  String get addressEnLabel => en ? 'Address (English)' : 'العنوان (إنجليزي)';
  String get latitude => en ? 'Latitude' : 'خط العرض';
  String get longitude => en ? 'Longitude' : 'خط الطول';
  String get image => en ? 'Image' : 'الصورة';
  String get pickImage => en ? 'Pick image' : 'اختر صورة';
  String get imageUrl => en ? 'Image URL' : 'رابط الصورة';
  String get orImageUrl => en ? 'Or paste an image URL' : 'أو الصق رابط صورة';
  String get description => en ? 'Description (Arabic)' : 'الوصف (عربي)';
  String get descriptionEn => en ? 'Description (English)' : 'الوصف (إنجليزي)';
  String get adTitle => en ? 'Ad title (Arabic)' : 'عنوان الإعلان (عربي)';
  String get adTitleEn => en ? 'Ad title (English)' : 'عنوان الإعلان (إنجليزي)';
  String get contactPhone => en ? 'Phone' : 'الهاتف';
  String get contactWhatsapp => en ? 'WhatsApp' : 'واتساب';
  String get contactTelegram => en ? 'Telegram' : 'تلكرام';
  String get contactEmail => en ? 'Email' : 'البريد الإلكتروني';
  String get contactOwner => en ? 'Contact the owner' : 'تواصل مع المالك';
  String get contactSubtitle => en
      ? 'Only the channels the owner filled in are shown.'
      : 'تظهر فقط وسائل التواصل التي أضافها المالك.';
  String get contactSaved =>
      en ? 'Contact details saved' : 'تم حفظ بيانات التواصل';
  String get contactTab => en ? 'Contact' : 'التواصل';
  String get contactName => en ? 'Display name' : 'الاسم الظاهر';
  String get contactPlaceholderPhone =>
      en ? '+964 7XX XXX XXXX' : '+964 7XX XXX XXXX';
  String get contactPlaceholderTelegram => en ? '@username' : '@username';
  String get websiteLink => en ? 'Link' : 'الرابط';
  String get verifiedLabel => en ? 'Verified shop' : 'محل موثّق';
  String get featuredLabel => en ? 'Featured' : 'مميز';
  String get activeLabel => en ? 'Active' : 'مفعّل';
  String get uploadImage => en ? 'Upload image' : 'رفع صورة';
  String get uploading => en ? 'Uploading…' : 'جارٍ الرفع…';
  String get pinStored => en
      ? 'The PIN is stored on this device to manage your content.'
      : 'يُحفظ الرمز على هذا الجهاز لإدارة المحتوى.';
  String get adminPinSettings => en ? 'Owner PIN' : 'رمز المالك';
  String get savePin => en ? 'Save PIN' : 'حفظ الرمز';
  String get openAdmin => en ? 'Open dashboard' : 'فتح لوحة التحكم';
  String get noShopsAdmin =>
      en ? 'No shops yet — add the first one.' : 'لا توجد محلات — أضف الأول.';
  String get noAdsAdmin =>
      en ? 'No ads yet — add the first one.' : 'لا توجد إعلانات — أضف الأول.';
  String get requiredField => en ? 'Required' : 'مطلوب';
  String get invalidNumber => en ? 'Enter a valid number' : 'أدخل رقماً صحيحاً';
  String get pinned => en ? 'Pinned' : 'مثبّت';
  String get unpinned => en ? 'Unpinned' : 'غير مثبّت';

  // ── حول ────────────────────────────────────────────────
  String get aboutApp => en ? 'About' : 'حول التطبيق';
  String get aboutText => en
      ? 'Gold Pulse analyses live gold prices, the dollar, bond yields, volatility and news sentiment to give Iraqi investors a clear, honest decision-support tool. It is not a broker and does not execute trades.'
      : 'نبض الذهب يحلل سعر الذهب الحي والدولار وعوائد السندات والتقلب ومعنويات الأخبار ليمنح المستثمر العراقي أداة دعم قرار واضحة وصادقة. التطبيق ليس وسيطاً ولا ينفذ صفقات.';
  String get dataSources => en ? 'Data sources' : 'مصادر البيانات';
  String get dataSourcesText => en
      ? 'Yahoo Finance (GC=F, DXY, US10Y, S&P 500, VIX), open.er-api.com for FX, and Google News RSS for headlines.'
      : 'Yahoo Finance (GC=F, DXY, US10Y, S&P 500, VIX)، وopen.er-api.com لأسعار الصرف، وGoogle News RSS للأخبار.';
  String get version => en ? 'Version' : 'الإصدار';
  String get financialDisclaimer => en
      ? 'This app is a decision-support tool, not guaranteed investment advice. Gold is volatile and you may lose capital. Always verify prices with a trusted dealer before buying or selling.'
      : 'هذا التطبيق أداة دعم قرار وليست نصيحة استثمارية مضمونة. الذهب متقلب وقد تخسر جزءاً من رأس مالك. تحقق دائماً من الأسعار لدى تاجر موثوق قبل الشراء أو البيع.';
  String get madeBy => en ? 'Built by' : 'تطوير';

  // ── الوقت ──────────────────────────────────────────────
  String timeAgo(String iso) {
    if (iso.isEmpty) return '';
    DateTime? dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return en ? 'now' : 'الآن';
    if (diff.inMinutes < 60) {
      return en ? '${diff.inMinutes}m ago' : 'منذ ${diff.inMinutes} دقيقة';
    }
    if (diff.inHours < 24) {
      return en ? '${diff.inHours}h ago' : 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays < 30) {
      return en ? '${diff.inDays}d ago' : 'منذ ${diff.inDays} يوم';
    }
    final d = dt;
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$month/$day';
  }

  String dateShort(String iso) {
    if (iso.isEmpty) return '';
    DateTime? dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return '';
    }
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}/$month/$day $hour:$minute';
  }

  // ── الأرقام ────────────────────────────────────────────
  static final NumberFormat _int = NumberFormat('#,##0', 'en');
  static final NumberFormat _dec = NumberFormat('#,##0.00', 'en');
  static final NumberFormat _one = NumberFormat('#,##0.0', 'en');

  String number(num value, {int digits = 0}) {
    if (digits == 2) return _dec.format(value);
    if (digits == 1) return _one.format(value);
    return _int.format(value);
  }

  String money(num value, {int digits = 0}) => moneyIqd(value, digits: digits);

  String moneyIqd(num value, {int digits = 0}) =>
      '${number(value, digits: digits)} ${en ? 'IQD' : 'د.ع'}';

  String moneyUsd(num value, {int digits = 2}) =>
      '\$${number(value, digits: digits)}';

  String usd(num value, {int digits = 2}) =>
      '\$${number(value, digits: digits)}';
  String iqd(num value) => '${number(value)} ${en ? 'IQD' : 'د.ع'}';

  /// سعر بوحدة العرض المختارة (دولار أو دينار).
  String priceText(num value, {required bool iqd, int? digits}) {
    final d = digits ?? (iqd ? 0 : 2);
    return iqd
        ? '${number(value, digits: d)} ${en ? 'IQD' : 'د.ع'}'
        : '\$${number(value, digits: d)}';
  }

  String priceCompact(num value, {required bool iqd}) {
    if (!iqd) return '\$${number(value, digits: 2)}';
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${number(value / 1000000, digits: 2)} ${en ? 'M IQD' : 'مليون د.ع'}';
    }
    return '${number(value)} ${en ? 'IQD' : 'د.ع'}';
  }

  /// نطاق سعري بالدولار يبقى مقروءاً من اليسار لليمين داخل النص العربي.
  String usdRange(num low, num high, {int digits = 0}) =>
      '\u202A\$${number(low, digits: digits)}–\$${number(high, digits: digits)}\u202C';

  /// نطاق رقمي باتجاه موحّد.
  String range(num low, num high, {int digits = 0, String suffix = ''}) =>
      '\u202A${number(low, digits: digits)}$suffix–${number(high, digits: digits)}$suffix\u202C';
  String percent(num value, {int digits = 2, bool sign = false}) {
    final prefix = sign && value > 0 ? '+' : '';
    return '$prefix${number(value, digits: digits)}%';
  }
}
