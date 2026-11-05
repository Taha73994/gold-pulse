import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import 'common.dart';

/// نافذة تقييم التطبيق (نجوم 1-5 + ملاحظة اختيارية).
Future<void> showRateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const RateSheet(),
  );
}

class RateSheet extends StatefulWidget {
  const RateSheet({super.key});

  @override
  State<RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<RateSheet> {
  final TextEditingController _comment = TextEditingController();
  int _rating = 0;
  bool _sending = false;
  bool _done = false;
  bool _initialized = false;
  String? _error;
  double? _average;
  int? _count;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _rating = AppScope.of(context).myRating;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _sending) return;
    final state = AppScope.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    final res = await state.rateApp(_rating, _comment.text.trim());
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (res == null) {
        _error = state.l.rateError;
      } else {
        _done = true;
        _average = (res['average'] as num?)?.toDouble();
        _count = res['count'] as int?;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: c.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (_done) _success(c, l) else _form(c, l),
          ],
        ),
      ),
    );
  }

  Widget _success(AppColors c, L10n l) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.green.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 30, color: c.green),
        ),
        const SizedBox(height: 12),
        Text(
          l.rateThanks,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Icon(
              i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: c.gold,
            ),
          ),
        ),
        if (_average != null) ...[
          const SizedBox(height: 6),
          Text(
            l.en
                ? 'Average rating: ${_average!.toStringAsFixed(1)} / 5'
                : 'متوسط التقييم: ${_average!.toStringAsFixed(1)} / 5',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10.5,
              color: c.muted,
            ),
          ),
        ],
        if (_count != null) ...[
          const SizedBox(height: 2),
          Text(
            l.en
                ? 'Based on $_count rating${_count == 1 ? '' : 's'}'
                : 'بناءً على $_count تقييم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 9.5,
              color: c.muted,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.close),
          ),
        ),
      ],
    );
  }

  Widget _form(AppColors c, L10n l) {
    return Column(
      children: [
        Text(
          l.ratingTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.ratingSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: c.muted),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final value = i + 1;
            return IconButton(
              onPressed: () => setState(() => _rating = value),
              icon: Icon(
                value <= _rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 34,
                color: c.gold,
              ),
              tooltip: '$value / 5',
            );
          }),
        ),
        if (_rating > 0)
          Text(
            _rating == 5
                ? (l.en ? 'Excellent' : 'ممتاز')
                : _rating == 4
                ? (l.en ? 'Very good' : 'جيد جداً')
                : _rating == 3
                ? (l.en ? 'Good' : 'جيد')
                : _rating == 2
                ? (l.en ? 'Fair' : 'مقبول')
                : (l.en ? 'Poor' : 'ضعيف'),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.muted,
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
          decoration: InputDecoration(
            hintText: l.rateCommentHint,
            counterStyle: TextStyle(fontSize: 9, color: c.muted),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 10.5, color: c.red),
          ),
        ],
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _rating > 0 && !_sending ? _submit : null,
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l.rateSend),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
