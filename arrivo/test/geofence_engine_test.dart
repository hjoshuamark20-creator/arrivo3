import 'package:arrivo/services/geofence_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Destination at (0, 0). 0.01 degrees of latitude is about 1112 m, 0.002 is about 222 m.
  const radius = 500.0;
  final t0 = DateTime(2026, 1, 1, 8);

  GeofenceEngine engine({double smoothing = 1.0}) => GeofenceEngine(
        destinationLatitude: 0,
        destinationLongitude: 0,
        radiusMeters: radius,
        smoothing: smoothing,
      );

  GeoSample at(double lat, {double accuracy = 5, DateTime? time}) => GeoSample(
        latitude: lat,
        longitude: 0,
        accuracy: accuracy,
        timestamp: time ?? t0,
      );

  test('does not ring while outside the radius', () {
    final result = engine().update(at(0.01));
    expect(result.shouldRing, isFalse);
    expect(result.inside, isFalse);
    expect(result.distanceMeters, closeTo(1112, 5));
  });

  test('rings once when entering the radius', () {
    final e = engine();
    expect(e.update(at(0.01)).shouldRing, isFalse);
    expect(e.update(at(0.002)).shouldRing, isTrue);
    expect(e.update(at(0.001)).shouldRing, isFalse);
  });

  test('ignores readings with poor accuracy', () {
    final result = engine().update(at(0.001, accuracy: 500));
    expect(result.ignored, isTrue);
    expect(result.shouldRing, isFalse);
    expect(result.distanceMeters, isNull);
  });

  test('snooze re-arms the alarm after 2 minutes', () {
    final e = engine();
    expect(e.update(at(0.002, time: t0)).shouldRing, isTrue);

    e.snooze(t0);
    expect(e.update(at(0.002, time: t0.add(const Duration(minutes: 1)))).shouldRing, isFalse);
    expect(e.update(at(0.002, time: t0.add(const Duration(minutes: 2)))).shouldRing, isTrue);
  });

  test('does not ring after snooze if the user left the radius', () {
    final e = engine();
    e.update(at(0.002, time: t0));
    e.snooze(t0);
    final later = t0.add(const Duration(minutes: 3));
    expect(e.update(at(0.01, time: later)).shouldRing, isFalse);
    // Coming back inside rings again.
    expect(e.update(at(0.002, time: later.add(const Duration(minutes: 1)))).shouldRing, isTrue);
  });

  test('dismiss stops all further rings', () {
    final e = engine();
    e.update(at(0.002));
    e.dismiss();
    expect(e.update(at(0.001, time: t0.add(const Duration(minutes: 10)))).shouldRing, isFalse);
  });

  test('smoothing blends the new distance with the previous one', () {
    final e = engine(smoothing: 0.5);
    final first = e.update(at(0.01)).distanceMeters!;
    final second = e.update(at(0)).distanceMeters!;
    expect(second, closeTo(first / 2, 1));
  });

  group('bandFor', () {
    test('far away uses the slowest updates', () {
      expect(bandFor(10000, radius), TrackingBand.far);
    });

    test('mid range', () {
      expect(bandFor(2000, radius), TrackingBand.mid);
    });

    test('close uses the fastest updates', () {
      expect(bandFor(800, radius), TrackingBand.near);
    });
  });
}
