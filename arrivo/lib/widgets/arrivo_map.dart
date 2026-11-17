import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/ui_helpers.dart';
import 'animated_bits.dart';

/// OpenStreetMap map (no API key) with the user's pulsing dot, the destination pin,
/// the alarm radius circle, and an optional line from the user to the stop.
/// In dark mode the tiles are dimmed so the map matches the dark glass theme.
class ArrivoMap extends StatefulWidget {
  const ArrivoMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15,
    this.controller,
    this.user,
    this.destination,
    this.radiusMeters,
    this.showRoute = false,
    this.onTap,
    this.onReady,
    this.interactive = true,
  });

  final LatLng initialCenter;
  final double initialZoom;

  /// Pass a controller to move the camera from the parent screen.
  final MapController? controller;
  final LatLng? user;
  final LatLng? destination;
  final double? radiusMeters;
  final bool showRoute;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onReady;
  final bool interactive;

  @override
  State<ArrivoMap> createState() => _ArrivoMapState();
}

class _ArrivoMapState extends State<ArrivoMap> {
  MapController? _ownController;
  MapController get _controller => widget.controller ?? (_ownController ??= MapController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkTheme(context);
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.arrivo',
    );
    final destination = widget.destination;
    final user = widget.user;
    final radius = widget.radiusMeters;

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 3,
        maxZoom: 19,
        onTap: widget.onTap == null ? null : (tapPosition, point) => widget.onTap!(point),
        onMapReady: widget.onReady,
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        if (dark)
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Color(0x99000000), BlendMode.srcATop),
            child: tiles,
          )
        else
          tiles,
        if (destination != null && radius != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: destination,
                radius: radius,
                useRadiusInMeter: true,
                color: AppColors.teal.withAlpha(64),
                borderColor: AppColors.darkTeal,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        if (widget.showRoute && user != null && destination != null)
          PolylineLayer(
            polylines: [
              Polyline(points: [user, destination], strokeWidth: 4, color: AppColors.darkTeal),
            ],
          ),
        MarkerLayer(
          markers: [
            if (destination != null)
              Marker(
                point: destination,
                width: 40,
                height: 40,
                child: const _DestinationPin(),
              ),
            if (user != null)
              Marker(point: user, width: 48, height: 48, child: const PulsingDot()),
          ],
        ),
      ],
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your stop',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 8)],
        ),
        child: const Icon(Icons.place_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}
