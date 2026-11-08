import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'common.dart';

/// مبدّل وحدة العرض: دولار أمريكي أو دينار عراقي.
class PriceUnitToggle extends StatelessWidget {
  final bool compact;
  final bool light;

  const PriceUnitToggle({super.key, this.compact = false, this.light = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final l = state.l;
    final c = AppColors.of(context);
    final background = light
        ? Colors.black.withValues(alpha: 0.18)
        : c.surfaceAlt;
    final activeText = light
        ? const Color(0xFF191305)
        : const Color(0xFF191305);

    Widget item(String label, bool iqd) {
      final active = state.iqdMode == iqd;
      return GestureDetector(
        onTap: () => state.setPriceUnit(iqd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 13,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: active ? c.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: compact ? 9 : 10.5,
              fontWeight: FontWeight.w800,
              color: active ? activeText : (light ? Colors.white70 : c.muted),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: light ? Colors.white.withValues(alpha: 0.18) : c.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [item(l.usdUnit, false), item(l.iqdUnit, true)],
      ),
    );
  }
}
