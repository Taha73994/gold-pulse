import 'dart:math' as math;

double _d(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

int _i(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

String _s(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

bool _b(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  return fallback;
}

class MacroPoint {
  final String symbol;
  final double value;
  final double change5d;
  final double change20d;
  final bool ok;

  const MacroPoint({
    required this.symbol,
    required this.value,
    required this.change5d,
    required this.change20d,
    required this.ok,
  });

  factory MacroPoint.fromJson(Map<String, dynamic> j) => MacroPoint(
    symbol: _s(j['symbol']),
    value: _d(j['value']),
    change5d: _d(j['change_5d_pct']),
    change20d: _d(j['change_20d_pct']),
    ok: _b(j['ok'], true),
  );
}

/// سعر الصرف: السوق الموازي (السوداء) مقابل السعر الرسمي.
class MarketFx {
  final double parallelBuy;
  final double parallelSell;
  final double official;
  final double gapPct;
  final double shopBuy;
  final double shopSell;
  final double? previous;
  final double? change;
  final double? changePct;
  final double? changeToday;
  final double? changeTodayPct;
  final bool available;
  final bool estimated;
  final bool stale;
  final String publishedAt;
  final String asOf;
  final String source;
  final String sourceUrl;

  const MarketFx({
    required this.parallelBuy,
    required this.parallelSell,
    required this.official,
    required this.gapPct,
    required this.shopBuy,
    required this.shopSell,
    required this.available,
    required this.estimated,
    required this.stale,
    required this.publishedAt,
    required this.asOf,
    required this.source,
    required this.sourceUrl,
    this.previous,
    this.change,
    this.changePct,
    this.changeToday,
    this.changeTodayPct,
  });

  double get mid => parallelSell > 0 && parallelBuy > 0
      ? (parallelSell + parallelBuy) / 2
      : parallelSell;

  factory MarketFx.fromJson(Map<String, dynamic> j) {
    double? opt(String key) => j[key] == null ? null : _d(j[key]);
    return MarketFx(
      parallelBuy: _d(j['parallel_buy']),
      parallelSell: _d(j['parallel_sell']),
      official: _d(j['official']),
      gapPct: _d(j['gap_pct']),
      shopBuy: _d(j['shop_buy']),
      shopSell: _d(j['shop_sell']),
      previous: opt('previous'),
      change: opt('change'),
      changePct: opt('change_pct'),
      changeToday: opt('change_today'),
      changeTodayPct: opt('change_today_pct'),
      available: _b(j['available'], true),
      estimated: _b(j['estimated'], false),
      stale: _b(j['stale'], false),
      publishedAt: _s(j['published_at']),
      asOf: _s(j['as_of']),
      source: _s(j['source']),
      sourceUrl: _s(j['source_url']),
    );
  }
}

/// سعر عيار واحد في السوق العراقي: سعر الشاشة، البيع للزبون، الشراء من الزبون، والفرق.
class LocalKaratQuote {
  final double screen;
  final double bid;
  final double ask;
  final double spread;
  final double spreadPct;

  const LocalKaratQuote({
    required this.screen,
    required this.bid,
    required this.ask,
    required this.spread,
    required this.spreadPct,
  });

  factory LocalKaratQuote.fromJson(Map<String, dynamic> j) => LocalKaratQuote(
    screen: _d(j['screen']),
    bid: _d(j['bid']),
    ask: _d(j['ask']),
    spread: _d(j['spread']),
    spreadPct: _d(j['spread_pct']),
  );
}

/// أسعار السوق العراقي المحلي (بيع/شراء) مقابل سعر الشاشة العالمي.
class LocalQuote {
  final double buyMarginPct;
  final double sellMarginPct;
  final Map<int, LocalKaratQuote> byKarat;
  final String noteAr;
  final String noteEn;

  const LocalQuote({
    required this.buyMarginPct,
    required this.sellMarginPct,
    required this.byKarat,
    required this.noteAr,
    required this.noteEn,
  });

  bool get isEmpty => byKarat.isEmpty;

  LocalKaratQuote? quote(int karat) => byKarat[karat];

  factory LocalQuote.fromJson(Map<String, dynamic> j) {
    final byKarat = <int, LocalKaratQuote>{};
    final raw = j['by_karat'];
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is Map) {
          byKarat[_i(k)] = LocalKaratQuote.fromJson(
            v.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      });
    }
    return LocalQuote(
      buyMarginPct: _d(j['buy_margin_pct']),
      sellMarginPct: _d(j['sell_margin_pct']),
      byKarat: byKarat,
      noteAr: _s(j['note_ar']),
      noteEn: _s(j['note_en']),
    );
  }
}

class MarketSnapshot {
  final double usdOz;
  final double changeUsd;
  final double changePct;
  final double open;
  final double high;
  final double low;
  final double prevClose;
  final double usdIqd;
  final Map<int, double> iqdGram;
  final List<double> spark;
  final double volatility20d;
  final Map<String, MacroPoint> macro;
  final String asOf;
  final String source;
  final String fxSource;
  final String disclaimer;
  final LocalQuote? local;
  final MarketFx? fx;
  final double officialRate;
  final Map<int, double> iqdGramOfficial;

  const MarketSnapshot({
    required this.usdOz,
    required this.changeUsd,
    required this.changePct,
    required this.open,
    required this.high,
    required this.low,
    required this.prevClose,
    required this.usdIqd,
    required this.iqdGram,
    required this.spark,
    required this.volatility20d,
    required this.macro,
    required this.asOf,
    required this.source,
    required this.fxSource,
    required this.disclaimer,
    this.local,
    this.fx,
    this.officialRate = 0,
    this.iqdGramOfficial = const {},
  });

  double gram(int karat) => iqdGram[karat] ?? 0;

  /// سعر الصرف الموازي المستخدم فعلياً في تسعير الذهب (بيع السوق).
  double get parallelRate {
    final sell = fx?.parallelSell ?? 0;
    if (sell > 0) return sell;
    if (usdIqd > 0) return usdIqd;
    return officialRate > 0 ? officialRate : 1500;
  }

  /// سعر الأونصة بالدينار العراقي على سعر السوق الموازي.
  double get ounceIqd => usdOz * parallelRate;

  /// المثقال العراقي = 5 غرام.
  double get mithqal24 => gram(24) * 5;
  double get mithqal21 =>
      gram(21) > 0 ? gram(21) * 5 : (gram(24) > 0 ? gram(24) * 5 * 21 / 24 : 0);

  double ounceIn(bool iqd) => iqd ? ounceIqd : usdOz;

  double gramIn(int karat, bool iqd) {
    final value = gram(karat);
    if (iqd) return value;
    return parallelRate > 0 ? value / parallelRate : 0;
  }

  double mithqalIn(int karat, bool iqd) {
    final value = gramIn(karat, iqd);
    return value * 5;
  }

  double get changeIqd => changeUsd * parallelRate;
  double get highIqd => high * parallelRate;
  double get lowIqd => low * parallelRate;

  /// التغيّر اليومي بالدينار للأونصة.
  double ounceChangeIn(bool iqd) => iqd ? changeIqd : changeUsd;

  factory MarketSnapshot.fromJson(Map<String, dynamic> j) {
    final grams = <int, double>{};
    final rawGrams = j['iqd_gram'];
    if (rawGrams is Map) {
      rawGrams.forEach((k, v) => grams[_i(k)] = _d(v));
    }
    final gramsOfficial = <int, double>{};
    final rawGramsOfficial = j['iqd_gram_official'];
    if (rawGramsOfficial is Map) {
      rawGramsOfficial.forEach((k, v) => gramsOfficial[_i(k)] = _d(v));
    }
    final fx = j['fx'] is Map
        ? MarketFx.fromJson(
            (j['fx'] as Map).map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          )
        : null;
    final macro = <String, MacroPoint>{};
    final rawMacro = j['macro'];
    if (rawMacro is Map) {
      rawMacro.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          macro[k.toString()] = MacroPoint.fromJson(v);
        } else if (v is Map) {
          macro[k.toString()] = MacroPoint.fromJson(
            v.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      });
    }
    return MarketSnapshot(
      usdOz: _d(j['usd_oz']),
      changeUsd: _d(j['change_usd']),
      changePct: _d(j['change_pct']),
      open: _d(j['open']),
      high: _d(j['high']),
      low: _d(j['low']),
      prevClose: _d(j['prev_close']),
      usdIqd: _d(j['usd_iqd'], 1517),
      iqdGram: grams,
      spark: (j['spark'] as List? ?? const [])
          .map((e) => _d(e))
          .where((e) => e > 0)
          .toList(),
      volatility20d: _d(j['volatility_20d']),
      macro: macro,
      asOf: _s(j['as_of']),
      source: _s(j['source']),
      fxSource: _s(j['fx_source']),
      disclaimer: _s(j['disclaimer']),
      local: j['local'] is Map
          ? LocalQuote.fromJson(
              (j['local'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
          : null,
      fx: fx,
      officialRate: _d(j['usd_iqd_official'], fx?.official ?? 0),
      iqdGramOfficial: gramsOfficial,
    );
  }
}

class Candle {
  final String time;
  final double open;
  final double high;
  final double low;
  final double close;

  const Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory Candle.fromJson(Map<String, dynamic> j) => Candle(
    time: _s(j['time']),
    open: _d(j['open']),
    high: _d(j['high']),
    low: _d(j['low']),
    close: _d(j['close']),
  );

  DateTime? get date => DateTime.tryParse(time);
}

class HistoryPayload {
  final String range;
  final List<Candle> candles;

  const HistoryPayload({required this.range, required this.candles});

  factory HistoryPayload.fromJson(Map<String, dynamic> j) => HistoryPayload(
    range: _s(j['range'], '1y'),
    candles: (j['candles'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => Candle.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
  );

  double get first => candles.isEmpty ? 0 : candles.first.close;
  double get last => candles.isEmpty ? 0 : candles.last.close;
  double get changePct => first == 0 ? 0 : (last - first) / first * 100;
  double get high =>
      candles.isEmpty ? 0 : candles.map((c) => c.high).reduce(math.max);
  double get low =>
      candles.isEmpty ? 0 : candles.map((c) => c.low).reduce(math.min);
}

class SignalComponent {
  final String key;
  final String label;
  final String detail;
  final double score;
  final double weight;
  final String impact;

  const SignalComponent({
    required this.key,
    required this.label,
    required this.detail,
    required this.score,
    required this.weight,
    required this.impact,
  });

  factory SignalComponent.fromJson(Map<String, dynamic> j) => SignalComponent(
    key: _s(j['key']),
    label: _s(j['label']),
    detail: _s(j['detail']),
    score: _d(j['score']),
    weight: _d(j['weight']),
    impact: _s(j['impact'], 'neutral'),
  );
}

class Signal {
  final String action;
  final String actionLabel;
  final String bias;
  final String tone;
  final String horizon;
  final double score;
  final int confidence;
  final List<SignalComponent> components;
  final List<SignalComponent> reasons;
  final String summary;

  const Signal({
    required this.action,
    required this.actionLabel,
    required this.bias,
    required this.tone,
    required this.horizon,
    required this.score,
    required this.confidence,
    required this.components,
    required this.reasons,
    required this.summary,
  });

  factory Signal.fromJson(Map<String, dynamic> j) => Signal(
    action: _s(j['action'], 'WAIT'),
    actionLabel: _s(j['action_label'], 'انتظار'),
    bias: _s(j['bias']),
    tone: _s(j['tone'], 'amber'),
    horizon: _s(j['horizon']),
    score: _d(j['score']),
    confidence: _i(j['confidence']),
    components: (j['components'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => SignalComponent.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    reasons: (j['reasons'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => SignalComponent.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    summary: _s(j['summary']),
  );
}

class Levels {
  final double entryLow;
  final double entryHigh;
  final double target1;
  final double target2;
  final double stop;
  final double support;
  final double resistance;
  final double atr;
  final double? riskReward;

  const Levels({
    required this.entryLow,
    required this.entryHigh,
    required this.target1,
    required this.target2,
    required this.stop,
    required this.support,
    required this.resistance,
    required this.atr,
    required this.riskReward,
  });

  factory Levels.fromJson(Map<String, dynamic> j) => Levels(
    entryLow: _d(j['entry_low']),
    entryHigh: _d(j['entry_high']),
    target1: _d(j['target1']),
    target2: _d(j['target2']),
    stop: _d(j['stop']),
    support: _d(j['support']),
    resistance: _d(j['resistance']),
    atr: _d(j['atr']),
    riskReward: j['risk_reward'] == null ? null : _d(j['risk_reward']),
  );
}

class Plan {
  final String decision;
  final String decisionLabel;
  final String tone;
  final String verdict;
  final List<String> steps;
  final String riskNote;
  final double entryLow;
  final double entryHigh;
  final double target1;
  final double target2;
  final double invalidation;
  final double? riskReward;
  final List<Catalyst> watch;

  const Plan({
    required this.decision,
    required this.decisionLabel,
    required this.tone,
    required this.verdict,
    required this.steps,
    required this.riskNote,
    required this.entryLow,
    required this.entryHigh,
    required this.target1,
    required this.target2,
    required this.invalidation,
    required this.riskReward,
    required this.watch,
  });

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
    decision: _s(j['decision'], 'WAIT'),
    decisionLabel: _s(j['decision_label']),
    tone: _s(j['tone'], 'amber'),
    verdict: _s(j['verdict']),
    steps: (j['steps'] as List? ?? const []).map((e) => e.toString()).toList(),
    riskNote: _s(j['risk_note']),
    entryLow: _d(j['entry_low']),
    entryHigh: _d(j['entry_high']),
    target1: _d(j['target1']),
    target2: _d(j['target2']),
    invalidation: _d(j['invalidation']),
    riskReward: j['risk_reward'] == null ? null : _d(j['risk_reward']),
    watch: (j['watch'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => Catalyst.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
  );
}

class Catalyst {
  final String title;
  final String source;
  final String category;
  final String categoryLabel;
  final String impact;
  final String sentimentLabel;
  final String publishedAt;

  const Catalyst({
    required this.title,
    required this.source,
    required this.category,
    required this.categoryLabel,
    required this.impact,
    required this.sentimentLabel,
    required this.publishedAt,
  });

  factory Catalyst.fromJson(Map<String, dynamic> j) => Catalyst(
    title: _s(j['title']),
    source: _s(j['source']),
    category: _s(j['category']),
    categoryLabel: _s(j['category_label']),
    impact: _s(j['impact']),
    sentimentLabel: _s(j['sentiment_label']),
    publishedAt: _s(j['published_at']),
  );
}

class Indicators {
  final double close;
  final double? sma20;
  final double? sma50;
  final double? sma200;
  final double? rsi14;
  final double? macd;
  final double? macdSignal;
  final double? macdHist;
  final double? atr14;
  final double return1d;
  final double return5d;
  final double return20d;
  final double support20;
  final double resistance20;
  final double volatility20;

  const Indicators({
    required this.close,
    required this.sma20,
    required this.sma50,
    required this.sma200,
    required this.rsi14,
    required this.macd,
    required this.macdSignal,
    required this.macdHist,
    required this.atr14,
    required this.return1d,
    required this.return5d,
    required this.return20d,
    required this.support20,
    required this.resistance20,
    required this.volatility20,
  });

  factory Indicators.fromJson(Map<String, dynamic> j) => Indicators(
    close: _d(j['close']),
    sma20: j['sma20'] == null ? null : _d(j['sma20']),
    sma50: j['sma50'] == null ? null : _d(j['sma50']),
    sma200: j['sma200'] == null ? null : _d(j['sma200']),
    rsi14: j['rsi14'] == null ? null : _d(j['rsi14']),
    macd: j['macd'] == null ? null : _d(j['macd']),
    macdSignal: j['macd_signal'] == null ? null : _d(j['macd_signal']),
    macdHist: j['macd_hist'] == null ? null : _d(j['macd_hist']),
    atr14: j['atr14'] == null ? null : _d(j['atr14']),
    return1d: _d(j['return_1d']),
    return5d: _d(j['return_5d']),
    return20d: _d(j['return_20d']),
    support20: _d(j['support20']),
    resistance20: _d(j['resistance20']),
    volatility20: _d(j['volatility20']),
  );
}

class NewsSummary {
  final double score;
  final String label;
  final int positive;
  final int negative;
  final int neutral;
  final int count;
  final int sources;

  const NewsSummary({
    required this.score,
    required this.label,
    required this.positive,
    required this.negative,
    required this.neutral,
    required this.count,
    required this.sources,
  });

  factory NewsSummary.fromJson(Map<String, dynamic> j) => NewsSummary(
    score: _d(j['score']),
    label: _s(j['label'], 'غير متاح'),
    positive: _i(j['positive']),
    negative: _i(j['negative']),
    neutral: _i(j['neutral']),
    count: _i(j['count']),
    sources: _i(j['sources']),
  );
}

class MentorLevel {
  final String type;
  final String label;
  final double price;
  final double? priceHigh;
  final String note;

  const MentorLevel({
    required this.type,
    required this.label,
    required this.price,
    required this.priceHigh,
    required this.note,
  });

  factory MentorLevel.fromJson(Map<String, dynamic> j) => MentorLevel(
    type: _s(j['type']),
    label: _s(j['label']),
    price: _d(j['price']),
    priceHigh: j['price_high'] == null ? null : _d(j['price_high']),
    note: _s(j['note']),
  );
}

class MentorScenario {
  final String title;
  final String trigger;
  final String action;
  final String target;
  final String risk;

  const MentorScenario({
    required this.title,
    required this.trigger,
    required this.action,
    required this.target,
    required this.risk,
  });

  factory MentorScenario.fromJson(Map<String, dynamic> j) => MentorScenario(
    title: _s(j['title']),
    trigger: _s(j['trigger']),
    action: _s(j['action']),
    target: _s(j['target']),
    risk: _s(j['risk']),
  );
}

class MentorCheck {
  final bool ok;
  final String text;

  const MentorCheck({required this.ok, required this.text});

  factory MentorCheck.fromJson(Map<String, dynamic> j) =>
      MentorCheck(ok: _b(j['ok']), text: _s(j['text']));
}

class Mentor {
  final String headline;
  final String conviction;
  final String note;
  final List<MentorLevel> keyLevels;
  final List<MentorScenario> scenarios;
  final List<String> rules;
  final List<MentorCheck> checklist;
  final List<String> mistakes;
  final List<String> weekly;
  final String timingNote;
  final String disclaimer;

  const Mentor({
    required this.headline,
    required this.conviction,
    required this.note,
    required this.keyLevels,
    required this.scenarios,
    required this.rules,
    required this.checklist,
    required this.mistakes,
    required this.weekly,
    required this.timingNote,
    required this.disclaimer,
  });

  static const empty = Mentor(
    headline: '',
    conviction: '',
    note: '',
    keyLevels: [],
    scenarios: [],
    rules: [],
    checklist: [],
    mistakes: [],
    weekly: [],
    timingNote: '',
    disclaimer: '',
  );

  factory Mentor.fromJson(Map<String, dynamic> j) => Mentor(
    headline: _s(j['headline']),
    conviction: _s(j['conviction']),
    note: _s(j['note']),
    keyLevels: (j['key_levels'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => MentorLevel.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    scenarios: (j['scenarios'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => MentorScenario.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    rules: (j['rules'] as List? ?? const []).map((e) => e.toString()).toList(),
    checklist: (j['checklist'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => MentorCheck.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    mistakes: (j['mistakes'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    weekly: (j['weekly'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    timingNote: _s(j['timing_note']),
    disclaimer: _s(j['disclaimer']),
  );
}

class ForecastHorizon {
  final int days;
  final double upProbability;
  final double downProbability;
  final double expected;
  final double low;
  final double high;
  final double expectedChangePct;
  final String direction;
  final String label;
  final String prepare;
  final String prepareText;
  final String narrative;

  const ForecastHorizon({
    required this.days,
    required this.upProbability,
    required this.downProbability,
    required this.expected,
    required this.low,
    required this.high,
    required this.expectedChangePct,
    required this.direction,
    required this.label,
    required this.prepare,
    required this.prepareText,
    required this.narrative,
  });

  factory ForecastHorizon.fromJson(Map<String, dynamic> j) => ForecastHorizon(
    days: _i(j['days']),
    upProbability: _d(j['up_probability']),
    downProbability: _d(j['down_probability']),
    expected: _d(j['expected']),
    low: _d(j['low']),
    high: _d(j['high']),
    expectedChangePct: _d(j['expected_change_pct']),
    direction: _s(j['direction'], 'neutral'),
    label: _s(j['label']),
    prepare: _s(j['prepare']),
    prepareText: _s(j['prepare_text']),
    narrative: _s(j['narrative']),
  );
}

class ForecastSummary {
  final int days;
  final String direction;
  final double upProbability;
  final double downProbability;
  final String headline;
  final String prepare;
  final String prepareText;
  final double rangeLow;
  final double rangeHigh;
  final double expected;
  final int confidence;

  const ForecastSummary({
    required this.days,
    required this.direction,
    required this.upProbability,
    required this.downProbability,
    required this.headline,
    required this.prepare,
    required this.prepareText,
    required this.rangeLow,
    required this.rangeHigh,
    required this.expected,
    required this.confidence,
  });

  static const empty = ForecastSummary(
    days: 5,
    direction: 'neutral',
    upProbability: 50,
    downProbability: 50,
    headline: '',
    prepare: 'wait',
    prepareText: '',
    rangeLow: 0,
    rangeHigh: 0,
    expected: 0,
    confidence: 0,
  );

  factory ForecastSummary.fromJson(Map<String, dynamic> j) => ForecastSummary(
    days: _i(j['days'], 5),
    direction: _s(j['direction'], 'neutral'),
    upProbability: _d(j['up_probability'], 50),
    downProbability: _d(j['down_probability'], 50),
    headline: _s(j['headline']),
    prepare: _s(j['prepare'], 'wait'),
    prepareText: _s(j['prepare_text']),
    rangeLow: _d(j['range_low']),
    rangeHigh: _d(j['range_high']),
    expected: _d(j['expected']),
    confidence: _i(j['confidence']),
  );
}

class Forecast {
  final bool ok;
  final List<ForecastHorizon> horizons;
  final ForecastSummary summary;
  final String method;
  final double dailyVolatilityPct;
  final String disclaimer;

  const Forecast({
    required this.ok,
    required this.horizons,
    required this.summary,
    required this.method,
    required this.dailyVolatilityPct,
    required this.disclaimer,
  });

  static const empty = Forecast(
    ok: false,
    horizons: [],
    summary: ForecastSummary.empty,
    method: '',
    dailyVolatilityPct: 0,
    disclaimer: '',
  );

  factory Forecast.fromJson(Map<String, dynamic> j) {
    final basis = (j['basis'] as Map? ?? const {});
    return Forecast(
      ok: _b(j['ok'], true),
      horizons: (j['horizons'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => ForecastHorizon.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      summary: ForecastSummary.fromJson(
        (j['summary'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      method: _s(basis['method']),
      dailyVolatilityPct: _d(basis['daily_volatility_pct']),
      disclaimer: _s(j['disclaimer']),
    );
  }
}

class Analysis {
  final double price;
  final double usdIqd;
  final String action;
  final String actionLabel;
  final String bias;
  final String tone;
  final String horizon;
  final double score;
  final int confidence;
  final String summary;
  final String regime;
  final String? overextension;
  final Signal shortTerm;
  final Signal swing;
  final Levels levels;
  final Indicators indicators;
  final Map<String, MacroPoint> macro;
  final NewsSummary news;
  final List<SignalComponent> topReasons;
  final Plan plan;
  final Forecast forecast;
  final Mentor mentor;
  final String generatedAt;
  final String disclaimer;
  final String methodology;

  const Analysis({
    required this.price,
    required this.usdIqd,
    required this.action,
    required this.actionLabel,
    required this.bias,
    required this.tone,
    required this.horizon,
    required this.score,
    required this.confidence,
    required this.summary,
    required this.regime,
    required this.overextension,
    required this.shortTerm,
    required this.swing,
    required this.levels,
    required this.indicators,
    required this.macro,
    required this.news,
    required this.topReasons,
    required this.plan,
    required this.forecast,
    required this.mentor,
    required this.generatedAt,
    required this.disclaimer,
    required this.methodology,
  });

  factory Analysis.fromJson(Map<String, dynamic> j) {
    final macro = <String, MacroPoint>{};
    final rawMacro = j['macro'];
    if (rawMacro is Map) {
      rawMacro.forEach((k, v) {
        if (v is Map) {
          macro[k.toString()] = MacroPoint.fromJson(
            v.map((key, value) => MapEntry(key.toString(), value)),
          );
        }
      });
    }
    return Analysis(
      price: _d(j['price']),
      usdIqd: _d(j['usd_iqd'], 1517),
      action: _s(j['action'], 'WAIT'),
      actionLabel: _s(j['action_label'], 'انتظار'),
      bias: _s(j['bias']),
      tone: _s(j['tone'], 'amber'),
      horizon: _s(j['horizon']),
      score: _d(j['score']),
      confidence: _i(j['confidence']),
      summary: _s(j['summary']),
      regime: _s(j['regime']),
      overextension: j['overextension'] == null ? null : _s(j['overextension']),
      shortTerm: Signal.fromJson(
        (j['short_term'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      swing: Signal.fromJson(
        (j['swing'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      levels: Levels.fromJson(
        (j['levels'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      indicators: Indicators.fromJson(
        (j['indicators'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      macro: macro,
      news: NewsSummary.fromJson(
        (j['news'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      topReasons: (j['top_reasons'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => SignalComponent.fromJson(
              e.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      plan: Plan.fromJson(
        (j['plan'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      mentor: Mentor.fromJson(
        (j['mentor'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      forecast: Forecast.fromJson(
        (j['forecast'] as Map? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      ),
      generatedAt: _s(j['generated_at']),
      disclaimer: _s(j['disclaimer']),
      methodology: _s(j['methodology']),
    );
  }
}

class NewsItem {
  final String title;
  final String link;
  final String source;
  final String publishedAt;
  final double ageHours;
  final double sentiment;
  final String sentimentLabel;
  final String impact;
  final String category;
  final String categoryLabel;
  final String why;

  const NewsItem({
    required this.title,
    required this.link,
    required this.source,
    required this.publishedAt,
    required this.ageHours,
    required this.sentiment,
    required this.sentimentLabel,
    required this.impact,
    required this.category,
    required this.categoryLabel,
    required this.why,
  });

  bool get positive => sentiment > 0.12;
  bool get negative => sentiment < -0.12;

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
    title: _s(j['title']),
    link: _s(j['link']),
    source: _s(j['source']),
    publishedAt: _s(j['published_at']),
    ageHours: _d(j['age_hours'], 999),
    sentiment: _d(j['sentiment']),
    sentimentLabel: _s(j['sentiment_label']),
    impact: _s(j['impact'], 'low'),
    category: _s(j['category'], 'other'),
    categoryLabel: _s(j['category_label'], 'سوق عام'),
    why: _s(j['why']),
  );
}

class NewsPayload {
  final List<NewsItem> items;
  final NewsSummary summary;
  final List<NewsItem> catalysts;
  final bool ok;
  final String? error;

  const NewsPayload({
    required this.items,
    required this.summary,
    required this.catalysts,
    required this.ok,
    this.error,
  });

  factory NewsPayload.fromJson(Map<String, dynamic> j) => NewsPayload(
    items: (j['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => NewsItem.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    summary: NewsSummary.fromJson(
      (j['summary'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    ),
    catalysts: (j['catalysts'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => NewsItem.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    ok: _b(j['ok'], true),
    error: j['error'] == null ? null : _s(j['error']),
  );
}

class AlertItem {
  final int id;
  final String createdAt;
  final String kind;
  final String severity;
  final String title;
  final String titleEn;
  final String body;
  final String bodyEn;
  final String action;
  final double price;
  final bool isRead;

  const AlertItem({
    required this.id,
    required this.createdAt,
    required this.kind,
    required this.severity,
    required this.title,
    required this.titleEn,
    required this.body,
    required this.bodyEn,
    required this.action,
    required this.price,
    required this.isRead,
  });

  String displayTitle(bool en) => en && titleEn.isNotEmpty ? titleEn : title;
  String displayBody(bool en) => en && bodyEn.isNotEmpty ? bodyEn : body;

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
    id: _i(j['id']),
    createdAt: _s(j['created_at']),
    kind: _s(j['kind']),
    severity: _s(j['severity'], 'info'),
    title: _s(j['title']),
    titleEn: _s(j['title_en'], _s(j['title'])),
    body: _s(j['body']),
    bodyEn: _s(j['body_en'], _s(j['body'])),
    action: _s(j['action']),
    price: _d(j['price']),
    isRead: _b(j['is_read']),
  );
}

class SignalHistoryPoint {
  final String createdAt;
  final String action;
  final String actionLabel;
  final double score;
  final int confidence;
  final double price;

  const SignalHistoryPoint({
    required this.createdAt,
    required this.action,
    required this.actionLabel,
    required this.score,
    required this.confidence,
    required this.price,
  });

  factory SignalHistoryPoint.fromJson(Map<String, dynamic> j) =>
      SignalHistoryPoint(
        createdAt: _s(j['created_at']),
        action: _s(j['action']),
        actionLabel: _s(j['action_label']),
        score: _d(j['score']),
        confidence: _i(j['confidence']),
        price: _d(j['price']),
      );
}

class AlertsPayload {
  final int unread;
  final List<AlertItem> items;
  final List<SignalHistoryPoint> signalHistory;
  final String disclaimer;

  const AlertsPayload({
    required this.unread,
    required this.items,
    required this.signalHistory,
    required this.disclaimer,
  });

  factory AlertsPayload.fromJson(Map<String, dynamic> j) => AlertsPayload(
    unread: _i(j['unread']),
    items: (j['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => AlertItem.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    signalHistory: (j['signal_history'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (e) => SignalHistoryPoint.fromJson(
            e.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(),
    disclaimer: _s(j['disclaimer']),
  );
}

class Shop {
  final int id;
  final String name;
  final String nameEn;
  final String city;
  final String cityEn;
  final String address;
  final String addressEn;
  final String phone;
  final String whatsapp;
  final double latitude;
  final double longitude;
  final String mapUrl;
  final String imageUrl;
  final String description;
  final String descriptionEn;
  final String workingHours;
  final bool isVerified;
  final bool isFeatured;
  final bool isActive;
  final int views;

  const Shop({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.city,
    required this.cityEn,
    required this.address,
    required this.addressEn,
    required this.phone,
    required this.whatsapp,
    required this.latitude,
    required this.longitude,
    required this.mapUrl,
    required this.imageUrl,
    required this.description,
    required this.descriptionEn,
    required this.workingHours,
    required this.isVerified,
    required this.isFeatured,
    required this.isActive,
    required this.views,
  });

  String displayName(bool en) => en && nameEn.isNotEmpty ? nameEn : name;
  String displayCity(bool en) => en && cityEn.isNotEmpty ? cityEn : city;
  String displayAddress(bool en) =>
      en && addressEn.isNotEmpty ? addressEn : address;
  String displayDescription(bool en) =>
      en && descriptionEn.isNotEmpty ? descriptionEn : description;

  factory Shop.fromJson(Map<String, dynamic> j) => Shop(
    id: _i(j['id']),
    name: _s(j['name']),
    nameEn: _s(j['name_en']),
    city: _s(j['city']),
    cityEn: _s(j['city_en']),
    address: _s(j['address']),
    addressEn: _s(j['address_en']),
    phone: _s(j['phone']),
    whatsapp: _s(j['whatsapp']),
    latitude: _d(j['latitude']),
    longitude: _d(j['longitude']),
    mapUrl: _s(j['map_url']),
    imageUrl: _s(j['image_url']),
    description: _s(j['description']),
    descriptionEn: _s(j['description_en']),
    workingHours: _s(j['working_hours']),
    isVerified: _b(j['is_verified']),
    isFeatured: _b(j['is_featured']),
    isActive: _b(j['is_active'], true),
    views: _i(j['views']),
  );
}

class AdItem {
  final int id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final double price;
  final String currency;
  final String imageUrl;
  final String phone;
  final String whatsapp;
  final String link;
  final String city;
  final String category;
  final String categoryAr;
  final String categoryEn;
  final int? shopId;
  final String placement;
  final String package;
  final bool isFeatured;
  final bool isActive;
  final int views;
  final int clicks;
  final String createdAt;
  final String? expiresAt;
  final int? daysLeft;

  const AdItem({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.phone,
    required this.whatsapp,
    required this.link,
    required this.city,
    required this.category,
    required this.categoryAr,
    required this.categoryEn,
    required this.shopId,
    required this.placement,
    required this.package,
    required this.isFeatured,
    required this.isActive,
    required this.views,
    required this.clicks,
    required this.createdAt,
    required this.expiresAt,
    required this.daysLeft,
  });

  String displayTitle(bool en) => en && titleEn.isNotEmpty ? titleEn : title;
  String displayDescription(bool en) =>
      en && descriptionEn.isNotEmpty ? descriptionEn : description;
  String displayCategory(bool en) => en ? categoryEn : categoryAr;

  factory AdItem.fromJson(Map<String, dynamic> j) => AdItem(
    id: _i(j['id']),
    title: _s(j['title']),
    titleEn: _s(j['title_en']),
    description: _s(j['description']),
    descriptionEn: _s(j['description_en']),
    price: _d(j['price']),
    currency: _s(j['currency'], 'IQD'),
    imageUrl: _s(j['image_url']),
    phone: _s(j['phone']),
    whatsapp: _s(j['whatsapp']),
    link: _s(j['link']),
    city: _s(j['city']),
    category: _s(j['category'], 'general'),
    categoryAr: _s(j['category_ar'], 'عام'),
    categoryEn: _s(j['category_en'], 'General'),
    shopId: j['shop_id'] == null ? null : _i(j['shop_id']),
    placement: _s(j['placement'], 'home'),
    package: _s(j['package'], 'basic'),
    isFeatured: _b(j['is_featured']),
    isActive: _b(j['is_active'], true),
    views: _i(j['views']),
    clicks: _i(j['clicks']),
    createdAt: _s(j['created_at']),
    expiresAt: j['expires_at'] == null ? null : _s(j['expires_at']),
    daysLeft: j['days_left'] == null ? null : _i(j['days_left']),
  );
}

class AdPackage {
  final String code;
  final String nameAr;
  final String nameEn;
  final int days;
  final double priceIqd;
  final String placement;
  final bool featured;
  final List<String> perksAr;
  final List<String> perksEn;

  const AdPackage({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.days,
    required this.priceIqd,
    required this.placement,
    required this.featured,
    required this.perksAr,
    required this.perksEn,
  });

  String displayName(bool en) => en ? nameEn : nameAr;
  List<String> perks(bool en) => en ? perksEn : perksAr;

  factory AdPackage.fromJson(Map<String, dynamic> j) => AdPackage(
    code: _s(j['code']),
    nameAr: _s(j['name_ar']),
    nameEn: _s(j['name_en']),
    days: _i(j['days']),
    priceIqd: _d(j['price_iqd']),
    placement: _s(j['placement']),
    featured: _b(j['featured']),
    perksAr: (j['perks_ar'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
    perksEn: (j['perks_en'] as List? ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class CurrencyRate {
  final String code;
  final String nameAr;
  final String nameEn;
  final String symbol;
  final String flag;
  final int decimals;
  final double perUsd;
  final double perIqd;
  final double usdRate;

  const CurrencyRate({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.symbol,
    required this.flag,
    required this.decimals,
    required this.perUsd,
    required this.perIqd,
    required this.usdRate,
  });

  String displayName(bool en) => en ? nameEn : nameAr;

  factory CurrencyRate.fromJson(Map<String, dynamic> j) => CurrencyRate(
    code: _s(j['code']),
    nameAr: _s(j['name_ar']),
    nameEn: _s(j['name_en']),
    symbol: _s(j['symbol']),
    flag: _s(j['flag']),
    decimals: _i(j['decimals'], 2),
    perUsd: _d(j['per_usd']),
    perIqd: _d(j['per_iqd']),
    usdRate: _d(j['usd_rate']),
  );
}

class CurrenciesPayload {
  final List<CurrencyRate> items;
  final String updated;
  final double usdIqd;
  final String noteAr;
  final String noteEn;

  const CurrenciesPayload({
    required this.items,
    required this.updated,
    required this.usdIqd,
    required this.noteAr,
    required this.noteEn,
  });

  String note(bool en) => en ? noteEn : noteAr;
  CurrencyRate? byCode(String code) {
    for (final c in items) {
      if (c.code == code) return c;
    }
    return null;
  }

  factory CurrenciesPayload.fromJson(Map<String, dynamic> j) =>
      CurrenciesPayload(
        items: (j['items'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) => CurrencyRate.fromJson(
                e.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList(),
        updated: _s(j['updated']),
        usdIqd: _d(j['usd_iqd'], 1517),
        noteAr: _s(j['note_ar']),
        noteEn: _s(j['note_en']),
      );
}

class PresenceStats {
  final int onlineNow;
  final int activeToday;
  final int activeWeek;
  final int activeMonth;
  final int totalUsers;
  final Map<String, int> platforms;
  final Map<String, int> locales;

  const PresenceStats({
    required this.onlineNow,
    required this.activeToday,
    required this.activeWeek,
    required this.activeMonth,
    required this.totalUsers,
    required this.platforms,
    required this.locales,
  });

  static const empty = PresenceStats(
    onlineNow: 0,
    activeToday: 0,
    activeWeek: 0,
    activeMonth: 0,
    totalUsers: 0,
    platforms: {},
    locales: {},
  );

  factory PresenceStats.fromJson(Map<String, dynamic> j) {
    Map<String, int> mapOf(dynamic value) {
      final out = <String, int>{};
      if (value is Map) {
        value.forEach((k, v) => out[k.toString()] = _i(v));
      }
      return out;
    }

    return PresenceStats(
      onlineNow: _i(j['online_now']),
      activeToday: _i(j['active_today']),
      activeWeek: _i(j['active_week']),
      activeMonth: _i(j['active_month']),
      totalUsers: _i(j['total_users']),
      platforms: mapOf(j['platforms']),
      locales: mapOf(j['locales']),
    );
  }
}

class AppConfig {
  final String appNameAr;
  final String appNameEn;
  final String owner;
  final String copyright;
  final String disclaimer;
  final String adsContactPhone;
  final String adsContactWhatsapp;
  final String version;

  const AppConfig({
    required this.appNameAr,
    required this.appNameEn,
    required this.owner,
    required this.copyright,
    required this.disclaimer,
    required this.adsContactPhone,
    required this.adsContactWhatsapp,
    required this.version,
  });

  static const fallback = AppConfig(
    appNameAr: 'نبض الذهب',
    appNameEn: 'Gold Pulse',
    owner: 'Taha Ali',
    copyright: '© 2026 Taha Ali — جميع الحقوق محفوظة',
    disclaimer: '',
    adsContactPhone: '',
    adsContactWhatsapp: '',
    version: '1.1.1',
  );

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
    appNameAr: _s(j['app_name_ar'], 'نبض الذهب'),
    appNameEn: _s(j['app_name_en'], 'Gold Pulse'),
    owner: _s(j['owner'], 'Taha Ali'),
    copyright: _s(j['copyright']),
    disclaimer: _s(j['disclaimer']),
    adsContactPhone: _s(j['ads_contact_phone']),
    adsContactWhatsapp: _s(j['ads_contact_whatsapp']),
    version: _s(j['version'], '1.1.0'),
  );
}

class OwnerContact {
  final String name;
  final String nameEn;
  final String phone;
  final String whatsapp;
  final String telegram;
  final String email;

  const OwnerContact({
    required this.name,
    required this.nameEn,
    required this.phone,
    required this.whatsapp,
    required this.telegram,
    required this.email,
  });

  static const empty = OwnerContact(
    name: '',
    nameEn: '',
    phone: '',
    whatsapp: '',
    telegram: '',
    email: '',
  );

  bool get hasAny =>
      phone.isNotEmpty ||
      whatsapp.isNotEmpty ||
      telegram.isNotEmpty ||
      email.isNotEmpty;

  String displayName(bool en) =>
      (en && nameEn.isNotEmpty) ? nameEn : (name.isNotEmpty ? name : '');

  factory OwnerContact.fromJson(Map<String, dynamic> j) => OwnerContact(
    name: _s(j['name']),
    nameEn: _s(j['name_en']),
    phone: _s(j['phone']),
    whatsapp: _s(j['whatsapp']),
    telegram: _s(j['telegram']),
    email: _s(j['email']),
  );
}

class ShopCity {
  final String city;
  final String cityEn;
  const ShopCity({required this.city, required this.cityEn});
  String display(bool en) => en && cityEn.isNotEmpty ? cityEn : city;

  factory ShopCity.fromJson(Map<String, dynamic> j) =>
      ShopCity(city: _s(j['city']), cityEn: _s(j['city_en']));
}

class AdminStats {
  final int totalUsers;
  final int usersToday;
  final int online;
  final int shopsTotal;
  final int shopsActive;
  final int adsTotal;
  final int adsActive;
  final int adViews;
  final int adClicks;
  final double revenueIqd;
  final int alertsTotal;
  final int alertsUnread;
  final int signals;
  final double goldUsdOz;

  const AdminStats({
    required this.totalUsers,
    required this.usersToday,
    required this.online,
    required this.shopsTotal,
    required this.shopsActive,
    required this.adsTotal,
    required this.adsActive,
    required this.adViews,
    required this.adClicks,
    required this.revenueIqd,
    required this.alertsTotal,
    required this.alertsUnread,
    required this.signals,
    required this.goldUsdOz,
  });

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    final users = j['users'] as Map? ?? const {};
    final shops = j['shops'] as Map? ?? const {};
    final ads = j['ads'] as Map? ?? const {};
    final alerts = j['alerts'] as Map? ?? const {};
    return AdminStats(
      totalUsers: _i(users['total']),
      usersToday: _i(users['today']),
      online: _i(users['online_15m']),
      shopsTotal: _i(shops['total']),
      shopsActive: _i(shops['active']),
      adsTotal: _i(ads['total']),
      adsActive: _i(ads['active']),
      adViews: _i(ads['views']),
      adClicks: _i(ads['clicks']),
      revenueIqd: _d(ads['estimated_revenue_iqd']),
      alertsTotal: _i(alerts['total']),
      alertsUnread: _i(alerts['unread']),
      signals: _i(j['signals']),
      goldUsdOz: _d(j['gold_usd_oz']),
    );
  }
}
