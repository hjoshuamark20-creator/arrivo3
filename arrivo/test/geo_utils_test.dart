import 'package:arrivo/models/app_settings.dart';
import 'package:arrivo/services/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('distanceMeters', () {
    test('same point is zero', () {
      expect(distanceMeters(10, 120, 10, 120), 0);
    });

    test('one degree of latitude is about 111 km', () {
      expect(distanceMeters(0, 0, 1, 0), closeTo(111195, 100));
    });

    test('is symmetric', () {
      final a = distanceMeters(14.5995, 120.9842, 14.6760, 121.0437);
      final b = distanceMeters(14.6760, 121.0437, 14.5995, 120.9842);
      expect(a, closeTo(b, 0.001));
    });
  });

  group('formatDistance', () {
    test('kilometers', () {
      expect(formatDistance(800, DistanceUnit.km), '800 m');
      expect(formatDistance(1234, DistanceUnit.km), '1.2 km');
    });

    test('miles and feet', () {
      expect(formatDistance(800, DistanceUnit.mi), '0.5 mi');
      expect(formatDistance(50, DistanceUnit.mi), '164 ft');
    });
  });

  group('estimateEta', () {
    test('null when barely moving', () {
      expect(estimateEta(1000, 0.5), isNull);
    });

    test('distance divided by speed', () {
      expect(estimateEta(1000, 10), const Duration(seconds: 100));
    });
  });
}
