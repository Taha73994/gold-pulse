import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../widgets/app_header.dart';
import '../widgets/common.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // أجور الصياغة الافتراضية للغرام حسب العيار (دينار عراقي).
  static const Map<int, double> _defaultMaking = {
    24: 5000,
    22: 6000,
    21: 7000,
    18: 9000,
  };

  final _weight = TextEditingController(text: '10');
  final _making = TextEditingController(
    text: _defaultMaking[21]!.toStringAsFixed(0),
  );
  final _commission = TextEditingController(text: '0');
  final _margin = TextEditingController(text: '2');
  final _buyback = TextEditingController(text: '5');
  final _manual24 = TextEditingController();

  int _karat = 21;
  bool _useLive = true;
  bool _advanced = false;

  @override
  void dispose() {
    _weight.dispose();
    _making.dispose();
    _commission.dispose();
    _margin.dispose();
    _buyback.dispose();
    _manual24.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) {
    return double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final market = state.market;

    final live24 = market?.gram(24) ?? 0;
    if (_useLive && market != null) {
      final text = live24.toStringAsFixed(0);
      if (_manual24.text.isEmpty || _manual24.text != text) {
        _manual24.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    final price24 = _useLive ? live24 : _num(_manual24);
    final pricePerGram = price24 * _karat / 24;
    final weight = _num(_weight);
    final goldValue = pricePerGram * weight;
    final making = _num(_making) * weight;
    final commission = goldValue * _num(_commission) / 100;
    final margin = (goldValue + making + commission) * _num(_margin) / 100;
    final total = goldValue + making + commission + margin;
    final perGram = weight > 0 ? total / weight : 0.0;
    final buyback = goldValue * (1 - _num(_buyback) / 100);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            PageHeader(title: l.goldCalculator, subtitle: l.calculatorSubtitle),
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
                          label: l.karat,
                          child: Wrap(
                            spacing: 8,
                            children: [24, 22, 21, 18].map((k) {
                              final active = k == _karat;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _karat = k;
                                  _making.text = _defaultMaking[k]!
                                      .toStringAsFixed(0);
                                }),
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
                                      fontSize: 14,
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
                        const SizedBox(height: 14),
                        _NumberField(
                          controller: _weight,
                          label: l.weight,
                          hint: l.goldWeightHint,
                          icon: Icons.scale_rounded,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.pricePerGram24,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.muted,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _useLive,
                              activeThumbColor: c.gold,
                              onChanged: (v) => setState(() => _useLive = v),
                            ),
                            Text(
                              l.useLivePrice,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                        if (!_useLive)
                          _NumberField(
                            controller: _manual24,
                            label: l.pricePerGram24,
                            hint: '0',
                            icon: Icons.payments_outlined,
                            onChanged: (_) => setState(() {}),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 15,
                                  color: c.gold,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${l.number(price24)} ${l.en ? 'IQD / g (24K)' : 'د.ع / غ (24)'}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  l.live,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: c.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.currency_exchange_rounded,
                              size: 12,
                              color: c.gold,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${l.goldUsesParallel} · ${l.parallelDollarShort}: ${l.number(market?.usdIqd ?? 0, digits: 1)}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 9,
                                  height: 1.5,
                                  color: c.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _advanced = !_advanced),
                          icon: Icon(
                            _advanced
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                          ),
                          label: Text(
                            l.pick(
                              'أجور الصياغة والعمولة والهامش',
                              'Making, commission and margin',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        if (_advanced) ...[
                          _NumberField(
                            controller: _making,
                            label: '${l.makingPerGram} · $_karat',
                            hint: '0',
                            icon: Icons.handyman_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              Expanded(
                                child: _NumberField(
                                  controller: _commission,
                                  label: l.commissionPct,
                                  hint: '0',
                                  icon: Icons.percent_rounded,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: _NumberField(
                                  controller: _margin,
                                  label: l.marginPct,
                                  hint: '0',
                                  icon: Icons.storefront_outlined,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          _NumberField(
                            controller: _buyback,
                            label: l.buybackPct,
                            hint: '0',
                            icon: Icons.replay_rounded,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _weight.text = '10';
                                _making.text = _defaultMaking[21]!
                                    .toStringAsFixed(0);
                                _commission.text = '0';
                                _margin.text = '2';
                                _buyback.text = '5';
                                _karat = 21;
                                _useLive = true;
                              });
                            },
                            icon: const Icon(
                              Icons.restart_alt_rounded,
                              size: 17,
                            ),
                            label: Text(l.reset),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.gold.withValues(alpha: 0.35)),
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
                          l.totalPrice,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.iqd(total),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.usd(
                            total / (state.market?.usdIqd ?? 1517),
                            digits: 2,
                          ),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: c.border, height: 1),
                        const SizedBox(height: 10),
                        _ResultRow(
                          label: '${l.goldValue} ($_karat ${l.karat})',
                          value: l.iqd(goldValue),
                        ),
                        if (making > 0)
                          _ResultRow(label: l.makingCost, value: l.iqd(making)),
                        if (commission > 0)
                          _ResultRow(
                            label: l.commissionCost,
                            value: l.iqd(commission),
                          ),
                        if (margin > 0)
                          _ResultRow(label: l.marginCost, value: l.iqd(margin)),
                        _ResultRow(
                          label: l.finalPerGram,
                          value: l.iqd(perGram),
                          color: c.gold,
                        ),
                        const SizedBox(height: 4),
                        Divider(color: c.border, height: 1),
                        const SizedBox(height: 8),
                        _ResultRow(
                          label: l.buybackValue,
                          value: l.iqd(buyback),
                          color: c.blue,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.pick(
                            'الفرق بين الشراء وإعادة البيع يمثل تكلفة التملك — كلما قلّ كان أفضل.',
                            'The gap between buy and buyback is your cost of ownership — keep it small.',
                          ),
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
                  const SizedBox(height: 14),
                  DisclaimerBox(
                    label: l.pick('ملاحظة', 'Note'),
                    text: l.calculatorNote,
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

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ResultRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11.5,
                color: c.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color ?? c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
