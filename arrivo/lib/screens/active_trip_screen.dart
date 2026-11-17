import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/ui_helpers.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../widgets/animated_bits.dart';
import '../widgets/arrivo_map.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_chip.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/glass_page.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  final MapController _map = MapController();
  bool _mapReady = false;
  double? _startDistance;

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  /// Keep both you and the stop on the mini map.
  void _fit(TripState s) {
    final u = s.update;
    final t = s.trip;
    if (!_mapReady || u == null || t == null || !u.hasDistance) return;
    final mid = LatLng((u.latitude + t.latitude) / 2, (u.longitude + t.longitude) / 2);
    final span = math.max(u.distanceMeters * 1.6, t.radiusMeters * 2.4);
    _map.move(mid, zoomForSpan(span, mid.latitude, pixels: 280));
  }

  Future<void> _cancel() async {
    final ok = await showGlassConfirm(
      context,
      title: 'Cancel this trip?',
      message: 'The alarm will not ring for this stop.',
      confirmLabel: 'Cancel trip',
      cancelLabel: 'Keep going',
      destructive: true,
    );
    if (ok) await ref.read(tripControllerProvider.notifier).cancel();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripControllerProvider);
    final settings = ref.watch(settingsProvider);
    ref.listen<TripState>(tripControllerProvider, (previous, next) => _fit(next));

    final trip = state.trip;
    if (trip == null) {
      // The router leaves this screen as soon as the trip is gone.
      return const GlassBackground(child: SizedBox.shrink());
    }

    final update = state.update;
    final distance = (update != null && update.hasDistance) ? update.distanceMeters : null;
    if (distance != null) _startDistance ??= distance;

    var progress = 0.0;
    final start = _startDistance;
    if (distance != null && start != null) {
      final span = start - trip.radiusMeters;
      progress = span > 0 ? ((start - distance) / span).clamp(0.0, 1.0) : 1.0;
    }

    final eta = (distance == null || update == null) ? null : estimateEta(distance, update.speed);
    final arrival = eta == null
        ? '--'
        : TimeOfDay.fromDateTime(DateTime.now().add(eta)).format(context);

    String status;
    if (state.error != null) {
      status = state.error!;
    } else if (update == null) {
      status = 'Waiting for GPS...';
    } else if (update.ignored) {
      status = 'Weak GPS signal (about ${update.accuracy.round()} m). Waiting for a better fix...';
    } else if (distance != null && distance <= trip.radiusMeters) {
      status = 'You’re inside the alarm area.';
    } else {
      status = 'The alarm rings ${formatDistance(trip.radiusMeters, settings.units)} from your stop.';
    }

    final text = Theme.of(context).textTheme;
    final user = (update != null && update.hasDistance)
        ? LatLng(update.latitude, update.longitude)
        : null;
    final dest = LatLng(trip.latitude, trip.longitude);

    return GlassScaffold(
      child: ListView(
        padding: EdgeInsets.only(bottom: 24 + MediaQuery.of(context).padding.bottom),
        children: [
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: GlassChip(label: 'Trip in progress', showDot: true),
          ),
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            label: distance == null
                ? 'Waiting for distance'
                : '${formatDistance(distance, settings.units)} to ${trip.destinationName}',
            child: ExcludeSemantics(
              child: SizedBox(
                height: 76,
                child: distance == null
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SkeletonBox(height: 60, width: 220, radius: 20),
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(end: distance),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, _) => Text(
                            formatDistance(value, settings.units),
                            style: text.headlineLarge?.copyWith(fontSize: 68, height: 1),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('to ${trip.destinationName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(color: mutedColor(context))),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _InfoCard(label: 'Arrival', value: arrival)),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  label: 'Alarm radius',
                  value: formatDistance(trip.radiusMeters, settings.units),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: rowFill(context),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(status, style: text.bodySmall?.copyWith(color: mutedColor(context))),
          ),
          const SizedBox(height: 16),
          GlassCard(
            radius: 32,
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SizedBox(
                height: 280,
                child: ArrivoMap(
                  controller: _map,
                  initialCenter: dest,
                  initialZoom: zoomForSpan(trip.radiusMeters * 2.4, dest.latitude, pixels: 280),
                  user: user,
                  destination: dest,
                  radiusMeters: trip.radiusMeters,
                  showRoute: true,
                  interactive: false,
                  onReady: () {
                    _mapReady = true;
                    _fit(ref.read(tripControllerProvider));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlassButton(label: 'Cancel Trip', onPressed: _cancel),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall?.copyWith(color: mutedColor(context))),
          const SizedBox(height: 2),
          Text(value, style: text.titleLarge),
        ],
      ),
    );
  }
}
