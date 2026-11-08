import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

/// حاسبة زكاة الذهب: الوزن والعيار، النصاب (85 غراماً عيار 24)،
/// وقيمة الزكاة 2.5% بسعر السوق الموازي.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _weight = TextEditingController(text: '100');
  int _karat = 21;

  static const double _nisabPureGrams = 85;
  static const double _zakatRate = 0.025;

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  double _parse(String input) {
    var text = input.trim();
    if (text.isEmpty) return 0;
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      final ai = arabic.indexOf(ch);
      final pi = persian.indexOf(ch);
      if (ai >= 0) {
        buffer.write(ai);
      } else if (pi >= 0) {
        buffer.write(pi);
      } else {
        buffer.write(ch);
      }
    }
    text = buffer.toString().replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final market = state.market;

    final weight = _parse(_weight.text);
    final gram24 = market?.gram(24) ?? 0;
    final pricePerGram = market?.gram(_karat) ?? 0;
    final totalIqd = weight * pricePerGram;
    final pureGrams = weight * _karat / 24;
    final nisabValueIqd = gram24 * _nisabPureGrams;
    final reached = pureGrams >= _nisabPureGrams && gram24 > 0;
    final zakatIqd = reached ? totalIqd * _zakatRate : 0.0;
    final rate = market?.parallelRate ?? 0;
    final totalUsd = rate > 0 ? totalIqd / rate : 0.0;
    final zakatUsd = rate > 0 ? zakatIqd / rate : 0.0;
    final progress = (pureGrams / _nisabPureGrams).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.pick('زكاة الذهب', 'Gold zakat'),
              subtitle: l.pick(
                'احسب زكاة ذهبك على سعر السوق الموازي',
                'Calculate your gold zakat at the parallel rate',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  SurfaceCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledField(
                          label: l.pick(
                            'وزن الذهب (غرام)',
                            'Gold weight (grams)',
                          ),
                          child: TextField(
                            controller: _weight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,\u0660-\u0669\u06F0-\u06F9]'),
                              ),
                            ],
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        LabeledField(
                          label: l.karat,
                          child: Wrap(
                            spacing: 8,
                            children: [24, 22, 21, 18].map((k) {
                              final active = k == _karat;
                              return GestureDetector(
                                onTap: () => setState(() => _karat = k),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active ? c.gold : c.surfaceAlt,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: active ? c.gold : c.border,
                                    ),
                                  ),
                                  child: Text(
                                    '$k',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? const Color(0xFF191305)
                                          : c.ink,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: (reached ? c.gold : c.border).withValues(
                          alpha: reached ? 0.5 : 1,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: reached
                            ? [c.gold.withValues(alpha: 0.20), c.surface]
                            : [c.surfaceAlt, c.surface],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: c.gold.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.volunteer_activism_rounded,
                                size: 20,
                                color: c.gold,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                reached
                                    ? l.pick('الزكاة المستحقة', 'Zakat due')
                                    : l.pick(
                                        'لم يبلغ النصاب',
                                        'Below the nisab',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: reached ? c.gold : c.muted,
                                ),
                              ),
                            ),
                            Pill(
                              text: reached
                                  ? l.pick('بلغ النصاب', 'Nisab met')
                                  : l.pick('دون النصاب', 'Below nisab'),
                              color: reached ? c.green : c.amber,
                              fontSize: 8.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            reached
                                ? l.priceText(zakatIqd, iqd: true)
                                : l.priceText(0, iqd: true),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: reached ? c.ink : c.muted,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        if (rate > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            '≈ ${l.usd(zakatUsd)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              color: c.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.toDouble(),
                            minHeight: 7,
                            backgroundColor: c.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              reached ? c.green : c.amber,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.pick(
                            'الذهب الخالص: ${l.number(pureGrams, digits: 2)} غ من ${l.number(_nisabPureGrams, digits: 0)} غ (النصاب)',
                            'Pure gold: ${l.number(pureGrams, digits: 2)} g of ${l.number(_nisabPureGrams, digits: 0)} g (nisab)',
                          ),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 9.5,
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        _Row(
                          label: l.pick(
                            'قيمة الذهب الإجمالية',
                            'Total gold value',
                          ),
                          value: gram24 > 0
                              ? l.priceText(totalIqd, iqd: true)
                              : '—',
                        ),
                        Divider(color: c.border, height: 1),
                        _Row(
                          label: l.pick(
                            'سعر غرام $_karat اليوم',
                            'Gram $_karat price today',
                          ),
                          value: gram24 > 0
                              ? l.priceText(pricePerGram, iqd: true)
                              : '—',
                        ),
                        Divider(color: c.border, height: 1),
                        _Row(
                          label: l.pick(
                            'قيمة النصاب (85 غ عيار 24)',
                            'Nisab value (85 g of 24K)',
                          ),
                          value: gram24 > 0
                              ? l.priceText(nisabValueIqd, iqd: true)
                              : '—',
                        ),
                        Divider(color: c.border, height: 1),
                        _Row(
                          label: l.pick('مقدار الزكاة', 'Zakat rate'),
                          value: '2.5%',
                        ),
                        if (totalUsd > 0) ...[
                          Divider(color: c.border, height: 1),
                          _Row(
                            label: l.pick(
                              'قيمة الذهب بالدولار',
                              'Gold value in USD',
                            ),
                            value: l.usd(totalUsd),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: c.gold.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.gold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: c.gold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            l.pick(
                              'الزكاة واجبة بعد مرور حول (سنة قمرية) على النصاب، ومقدارها 2.5%. بعض الفقهاء لا يوجبون الزكاة في ذهب الزينة المستعمل. هذه الحاسبة إرشادية — راجع مرجعك الديني.',
                              'Zakat is due after one lunar year passes on the nisab, at 2.5%. Some scholars do not require zakat on gold jewellery in regular use. This calculator is a guide — consult your religious authority.',
                            ),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              height: 1.7,
                              color: c.ink.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DisclaimerBox(
                    label: l.disclaimer,
                    text: l.financialDisclaimer,
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

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: c.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
