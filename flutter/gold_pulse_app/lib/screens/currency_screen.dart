import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _amount = TextEditingController(text: '100');
  String _from = 'USD';
  String _to = 'IQD';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// تحويل الأرقام العربية/الفارسية وفهم الفاصلة كفاصل آلاف أو عشري.
  double _parseAmount(String input) {
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
    text = buffer
        .toString()
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '')
        .replaceAll('\u066B', '.')
        .replaceAll('\u066C', ',');
    if (text.contains(',') && text.contains('.')) {
      text = text.replaceAll(',', '');
    } else if (text.contains(',')) {
      final parts = text.split(',');
      final thousands =
          parts.length > 1 && parts.skip(1).every((part) => part.length == 3);
      text = thousands ? parts.join() : text.replaceAll(',', '.');
    }
    return double.tryParse(text) ?? 0;
  }

  /// أرقام مناسبة لعرض سعر الصرف حسب حجمه.
  int _rateDigits(double value) {
    final abs = value.abs();
    if (abs >= 1000) return 0;
    if (abs >= 10) return 2;
    if (abs >= 1) return 3;
    if (abs >= 0.01) return 5;
    return 7;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final payload = state.currencies;
    final items = payload?.items ?? const <CurrencyRate>[];

    CurrencyRate? find(String code) {
      for (final item in items) {
        if (item.code == code) return item;
      }
      return null;
    }

    final from = find(_from);
    final to = find(_to);
    final amount = _parseAmount(_amount.text);

    // الدولار العراقي يُحوَّل بسعر السوق الموازي (نفس أساس تسعير الذهب).
    final parallelIqd = state.market?.fx?.parallelSell ?? 0;
    double perUsdOf(CurrencyRate? item) {
      if (item == null) return 0;
      if (item.code == 'IQD' && parallelIqd > 0) return parallelIqd;
      return item.perUsd;
    }

    final fromPerUsd = perUsdOf(from);
    final toPerUsd = perUsdOf(to);
    final result = fromPerUsd <= 0 || toPerUsd <= 0
        ? 0.0
        : amount / fromPerUsd * toPerUsd;
    final unitRate = fromPerUsd <= 0 ? 0.0 : toPerUsd / fromPerUsd;
    final goldUsdOz = state.market?.usdOz ?? state.analysis?.price ?? 0;
    final gram24Usd = goldUsdOz / 31.1035;
    final usingParallel = parallelIqd > 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(
              title: l.currencyConverter,
              subtitle: l.currencySubtitle,
              actions: [
                IconButton(
                  onPressed: state.loadingCurrencies
                      ? null
                      : state.loadCurrencies,
                  icon: state.loadingCurrencies
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.gold,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  tooltip: l.refresh,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                children: [
                  SurfaceCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LabeledField(
                          label: l.amount,
                          child: TextField(
                            controller: _amount,
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
                        Row(
                          children: [
                            Expanded(
                              child: _CurrencyPicker(
                                label: l.from,
                                value: _from,
                                items: items,
                                en: state.en,
                                onChanged: (v) => setState(() => _from = v),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: IconButton(
                                onPressed: () => setState(() {
                                  final tmp = _from;
                                  _from = _to;
                                  _to = tmp;
                                }),
                                icon: const Icon(Icons.swap_horiz_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: c.gold.withValues(
                                    alpha: 0.12,
                                  ),
                                  foregroundColor: c.gold,
                                ),
                                tooltip: l.swap,
                              ),
                            ),
                            Expanded(
                              child: _CurrencyPicker(
                                label: l.to,
                                value: _to,
                                items: items,
                                en: state.en,
                                onChanged: (v) => setState(() => _to = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.gold.withValues(alpha: 0.34)),
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
                          '${l.result} · $_from → $_to',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${l.number(result, digits: to?.decimals ?? 2)} ${to?.symbol ?? _to}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          from == null || to == null
                              ? ''
                              : '1 $_from = ${l.number(unitRate, digits: _rateDigits(unitRate))} $_to',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: c.muted,
                          ),
                        ),
                        if (usingParallel) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.currency_exchange_rounded,
                                size: 11,
                                color: c.gold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l.pick(
                                  'الدينار بسعر السوق الموازي: 1\$ = ${l.number(parallelIqd, digits: 0)} د.ع',
                                  'IQD uses the parallel rate: \$1 = ${l.number(parallelIqd, digits: 0)} IQD',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: c.gold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SurfaceCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              size: 18,
                              color: Color(0xFF1B1505),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${l.goldGramIn} ${to?.code ?? _to}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10.5,
                                    color: c.muted,
                                  ),
                                ),
                                Text(
                                  '${l.number(gram24Usd * toPerUsd, digits: to?.decimals ?? 2)} ${to?.symbol ?? ''}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: c.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l.perUsd,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  color: c.muted,
                                ),
                              ),
                              Text(
                                l.number(toPerUsd, digits: to?.decimals ?? 2),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: l.ratesTable,
                      subtitle: payload?.updated.isNotEmpty == true
                          ? '${l.lastUpdated}: ${payload!.updated}'
                          : null,
                      icon: Icons.table_chart_rounded,
                    ),
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 4,
                      ),
                      child: Column(
                        children: items.map((item) {
                          final isTarget = item.code == _to;
                          return InkWell(
                            onTap: () => setState(() => _to = item.code),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: c.border.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    item.flag,
                                    style: const TextStyle(fontSize: 17),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName(state.en),
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: isTarget ? c.gold : c.ink,
                                          ),
                                        ),
                                        Text(
                                          item.code,
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 9,
                                            color: c.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    l.number(
                                      perUsdOf(item),
                                      digits: item.decimals,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isTarget ? c.gold : c.ink,
                                    ),
                                  ),
                                  if (item.code == 'IQD' && usingParallel) ...[
                                    const SizedBox(width: 4),
                                    Pill(
                                      text: l.pick('سوق', 'market'),
                                      color: c.gold,
                                      fontSize: 7.5,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else if (state.loadingCurrencies)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  const SizedBox(height: 14),
                  DisclaimerBox(
                    label: l.pick('ملاحظة', 'Note'),
                    text: payload?.note(state.en).isNotEmpty == true
                        ? payload!.note(state.en)
                        : l.currencyNote,
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

class _CurrencyPicker extends StatelessWidget {
  final String label;
  final String value;
  final List<CurrencyRate> items;
  final bool en;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({
    required this.label,
    required this.value,
    required this.items,
    required this.en,
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
            value: items.any((i) => i.code == value) ? value : null,
            isExpanded: true,
            dropdownColor: c.surfaceAlt,
            icon: Icon(Icons.expand_more_rounded, color: c.muted, size: 18),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.code,
                    child: Row(
                      children: [
                        Text(item.flag, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.code,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ],
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
