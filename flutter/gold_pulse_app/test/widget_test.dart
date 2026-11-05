import 'package:flutter_test/flutter_test.dart';
import 'package:gold_pulse_app/core/l10n.dart';
import 'package:gold_pulse_app/core/models.dart';

void main() {
  group('L10n', () {
    test('Arabic is the default language', () {
      const l = L10n(false);
      expect(l.appName, 'نبض الذهب');
      expect(l.copyright, contains('Taha Ali'));
    });

    test('English translation is complete for key labels', () {
      const l = L10n(true);
      expect(l.appName, 'Gold Pulse');
      expect(l.navMentor, 'Mentor');
      expect(l.calculator, 'Calculator');
      expect(l.copyright, contains('All rights reserved'));
    });

    test('numbers are grouped with Latin digits', () {
      const l = L10n(false);
      expect(l.number(1234567), '1,234,567');
      expect(l.usd(4039.5, digits: 2), '\$4,039.50');
    });
  });

  group('Forecast model', () {
    test('parses horizons and summary safely', () {
      final forecast = Forecast.fromJson({
        'ok': true,
        'horizons': [
          {
            'days': 5,
            'up_probability': 61.5,
            'down_probability': 38.5,
            'expected': 4100,
            'low': 3980,
            'high': 4230,
            'direction': 'up',
            'prepare': 'prepare_buy',
          }
        ],
        'summary': {
          'days': 5,
          'direction': 'up',
          'up_probability': 61.5,
          'down_probability': 38.5,
          'range_low': 3980,
          'range_high': 4230,
          'expected': 4100,
          'confidence': 63,
          'prepare': 'prepare_buy',
        },
        'basis': {'daily_volatility_pct': 1.2, 'method': 'Monte Carlo'},
      });
      expect(forecast.ok, isTrue);
      expect(forecast.horizons, hasLength(1));
      expect(forecast.summary.prepare, 'prepare_buy');
      expect(forecast.summary.confidence, 63);
    });

    test('empty payload does not throw', () {
      final forecast = Forecast.fromJson(const {});
      expect(forecast.summary.days, 5);
      expect(forecast.horizons, isEmpty);
    });
  });

  group('Alerts', () {
    test('falls back to Arabic text when English is missing', () {
      final alert = AlertItem.fromJson({
        'id': 7,
        'title': 'استعد للشراء',
        'body': 'احتمال صعود 60%',
        'action': 'BUY',
      });
      expect(alert.displayTitle(true), 'استعد للشراء');
      expect(alert.displayBody(false), 'احتمال صعود 60%');
      expect(alert.action, 'BUY');
    });
  });
}
