import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../core/theme.dart';

class PriceChart extends StatefulWidget {
  final List<Candle> candles;
  final L10n l;
  final Color lineColor;

  const PriceChart({
    super.key,
    required this.candles,
    required this.l,
    required this.lineColor,
  });

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles.length != widget.candles.length) {
      _selected = null;
    }
  }

  void _pick(double dx, double width) {
    final list = widget.candles;
    if (list.isEmpty) return;
    const left = 52.0;
    const right = 10.0;
    final usable = math.max(1.0, width - left - right);
    final fraction = ((dx - left) / usable).clamp(0.0, 1.0);
    final index = (fraction * (list.length - 1)).round();
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = widget.l;
    final list = widget.candles;
    if (list.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            l.noData,
            style: TextStyle(fontFamily: 'Cairo', color: c.muted),
          ),
        ),
      );
    }

    final selected = _selected == null
        ? null
        : list[_selected!.clamp(0, list.length - 1)];
    final reference = selected ?? list.last;
    final referenceIndex =
        selected == null ? list.length - 1 : _selected!.clamp(0, list.length - 1);
    final previous = referenceIndex > 0 ? list[referenceIndex - 1] : null;
    final change = previous == null || previous.close == 0
        ? 0.0
        : (reference.close - previous.close) / previous.close * 100;
    final up = change >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.usd(reference.close, digits: 2),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dateLabel(reference.time),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (up ? c.green : c.red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l.percent(change, sign: true),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: up ? c.green : c.red,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pick(d.localPosition.dx, width),
              onHorizontalDragUpdate: (d) =>
                  _pick(d.localPosition.dx, width),
              onHorizontalDragEnd: (_) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _selected = null);
                });
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) {
                  return CustomPaint(
                    size: Size(width, 230),
                    painter: _ChartPainter(
                      candles: list,
                      progress: progress,
                      selected: _selected,
                      line: widget.lineColor,
                      grid: c.border,
                      muted: c.muted,
                      surface: c.surface,
                      ink: c.ink,
                      formatPrice: (v) => l.number(v, digits: 0),
                      formatDate: _dateLabel,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _dateLabel(String time) {
    if (time.length >= 10) {
      final y = time.substring(2, 4);
      final m = time.substring(5, 7);
      final d = time.substring(8, 10);
      return '$d/$m/$y';
    }
    return time;
  }
}

class _ChartPainter extends CustomPainter {
  final List<Candle> candles;
  final double progress;
  final int? selected;
  final Color line;
  final Color grid;
  final Color muted;
  final Color surface;
  final Color ink;
  final String Function(double) formatPrice;
  final String Function(String) formatDate;

  _ChartPainter({
    required this.candles,
    required this.progress,
    required this.selected,
    required this.line,
    required this.grid,
    required this.muted,
    required this.surface,
    required this.ink,
    required this.formatPrice,
    required this.formatDate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    const left = 52.0;
    const right = 10.0;
    const top = 10.0;
    const bottom = 26.0;
    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);

    final values = candles.map((c) => c.close).toList();
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    if ((maxValue - minValue).abs() < 0.001) {
      minValue -= 1;
      maxValue += 1;
    }
    final padding = (maxValue - minValue) * 0.12;
    minValue -= padding;
    maxValue += padding;
    final range = maxValue - minValue;

    double x(int index) {
      if (candles.length == 1) return left + chartWidth / 2;
      return left + index / (candles.length - 1) * chartWidth;
    }

    double y(double value) {
      return top + (maxValue - value) / range * chartHeight;
    }

    // شبكة أفقية + أسعار
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final value = minValue + range * (i / 3);
      final yy = y(value);
      canvas.drawLine(Offset(left, yy), Offset(size.width - right, yy), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: formatPrice(value),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 9.5,
            color: muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, yy - tp.height / 2));
    }

    final count = ((candles.length - 1) * progress).floor().clamp(0, candles.length - 1);
    if (count < 1) return;

    // منطقة التعبئة
    final fillPath = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i <= count; i++) {
      fillPath.lineTo(x(i), y(values[i]));
    }
    fillPath.lineTo(x(count), top + chartHeight);
    fillPath.lineTo(x(0), top + chartHeight);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          line.withValues(alpha: 0.28),
          line.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    // خط السعر
    final linePath = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i <= count; i++) {
      linePath.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // آخر نقطة
    final lastX = x(count);
    final lastY = y(values[count]);
    canvas.drawCircle(
      Offset(lastX, lastY),
      7,
      Paint()..color = line.withValues(alpha: 0.16),
    );
    canvas.drawCircle(Offset(lastX, lastY), 3.4, Paint()..color = line);

    // التواريخ
    final positions = [0, candles.length ~/ 2, candles.length - 1];
    for (final index in positions) {
      final label = formatDate(candles[index].time);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 9,
            color: muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      var dx = x(index) - tp.width / 2;
      dx = dx.clamp(left, size.width - right - tp.width);
      tp.paint(canvas, Offset(dx, size.height - bottom + 7));
    }

    // مؤشر الاختيار
    if (selected != null && selected! <= count) {
      final sx = x(selected!);
      final sy = y(values[selected!]);
      final dashPaint = Paint()
        ..color = line.withValues(alpha: 0.45)
        ..strokeWidth = 1;
      var dashY = top;
      while (dashY < top + chartHeight) {
        canvas.drawLine(
          Offset(sx, dashY),
          Offset(sx, math.min(dashY + 4, top + chartHeight)),
          dashPaint,
        );
        dashY += 8;
      }
      canvas.drawCircle(Offset(sx, sy), 9, Paint()..color = surface);
      canvas.drawCircle(Offset(sx, sy), 6, Paint()..color = line);
      canvas.drawCircle(Offset(sx, sy), 2.4, Paint()..color = surface);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) {
    return old.progress != progress ||
        old.selected != selected ||
        old.candles.length != candles.length ||
        old.line != line;
  }
}

class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = math.max(0.001, maxV - minV);
    double x(int i) => i / (values.length - 1) * size.width;
    double y(double v) => size.height - 3 - (v - minV) / range * (size.height - 6);

    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(x(values.length - 1), y(values.last)),
      2.8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.values.length != values.length || old.color != color;
}

class ScoreBar extends StatelessWidget {
  final double score;
  final L10n l;

  const ScoreBar({super.key, required this.score, required this.l});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fraction = ((score + 100) / 200).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return SizedBox(
              height: 12,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFF59E0B),
                          Color(0xFF84CC16),
                          Color(0xFF22C55E),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (fraction * width - 7).clamp(0.0, width - 14),
                    top: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.ink, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('-100', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: c.muted)),
            Text('0', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: c.muted)),
            Text('+100', style: TextStyle(fontFamily: 'Cairo', fontSize: 9, color: c.muted)),
          ],
        ),
      ],
    );
  }
}
