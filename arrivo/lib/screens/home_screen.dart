import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/ui_helpers.dart';
import '../models/app_settings.dart';
import '../models/destination_args.dart';
import '../models/place.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../services/place_search_service.dart';
import '../widgets/animated_bits.dart';
import '../widgets/arrivo_map.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_sheet.dart';
import '../widgets/place_tile.dart';
import '../widgets/primary_button.dart';

class SearchRequestGuard {
  const SearchRequestGuard._();

  static int nextToken(int current) => current + 1;

  static bool isLatest({
    required int requestToken,
    required int latestRequestToken,
  }) =>
      requestToken == latestRequestToken;
}

/// Home: full-screen map, floating search pill, floating "Saved places" sheet.
/// The tab bar is added by the AppShell.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _fallbackCenter = LatLng(14.5995, 120.9842);

  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  int _latestSearchToken = 0;
  bool _mapReady = false;
  bool _centered = false;

  LatLng? _picked;
  String _pickedName = 'Dropped pin';
  List<PlaceResult> _results = const [];
  bool _searching = false;
  String? _searchError;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _centerOnUser(Position p) {
    if (!_mapReady || _centered) return;
    _centered = true;
    _map.move(LatLng(p.latitude, p.longitude), 16);
  }

  void _pick(LatLng point,
      {String name = 'Dropped pin', bool moveCamera = false}) {
    setState(() {
      _picked = point;
      _pickedName = name;
      _results = const [];
      _searchError = null;
    });
    if (moveCamera && _mapReady) _map.move(point, 16);
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    final normalized = text.trim();
    if (normalized.length < 3) {
      _latestSearchToken = SearchRequestGuard.nextToken(_latestSearchToken);
      setState(() {
        _results = const [];
        _searchError = null;
        _searching = false;
      });
      return;
    }

    final requestToken = SearchRequestGuard.nextToken(_latestSearchToken);
    _latestSearchToken = requestToken;

    // Nominatim allows about one request per second, so wait until typing stops.
    _debounce = Timer(const Duration(milliseconds: 900),
        () => _runSearch(normalized, requestToken));
  }

  Future<void> _runSearch(String text, [int? requestToken]) async {
    final activeRequestToken =
        requestToken ?? SearchRequestGuard.nextToken(_latestSearchToken);
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final found = await ref.read(placeSearchServiceProvider).search(text);
      if (!mounted) return;
      if (!SearchRequestGuard.isLatest(
        requestToken: activeRequestToken,
        latestRequestToken: _latestSearchToken,
      )) {
        return;
      }
      setState(() {
        _results = found;
        _searching = false;
        if (found.isEmpty) _searchError = 'No places found. Try another name.';
      });
    } on SearchException catch (e) {
      if (!mounted) return;
      if (!SearchRequestGuard.isLatest(
        requestToken: activeRequestToken,
        latestRequestToken: _latestSearchToken,
      )) {
        return;
      }
      setState(() {
        _results = const [];
        _searching = false;
        _searchError = e.message;
      });
    }
  }

  void _chooseResult(PlaceResult result) {
    FocusScope.of(context).unfocus();
    final shortName = result.name.split(',').first.trim();
    _search.text = shortName;
    _pick(LatLng(result.latitude, result.longitude),
        name: shortName, moveCamera: true);
  }

  void _setDestination() {
    final point = _picked;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Search for a stop or tap the map first.')),
      );
      return;
    }
    context.push(
      '/set-alarm',
      extra: DestinationArgs(
          name: _pickedName,
          latitude: point.latitude,
          longitude: point.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final position = ref.watch(currentPositionProvider).valueOrNull;
    final user =
        position == null ? null : LatLng(position.latitude, position.longitude);

    ref.listen<AsyncValue<Position>>(currentPositionProvider, (previous, next) {
      final p = next.valueOrNull;
      if (p != null) _centerOnUser(p);
    });

    final padding = MediaQuery.of(context).padding;
    return Stack(
      fit: StackFit.expand,
      children: [
        ArrivoMap(
          controller: _map,
          initialCenter: user ?? _fallbackCenter,
          initialZoom: user == null ? 12 : 16,
          user: user,
          destination: _picked,
          radiusMeters: _picked == null ? null : settings.defaultRadius,
          onTap: (point) => _pick(point),
          onReady: () {
            _mapReady = true;
            final p = ref.read(currentPositionProvider).valueOrNull;
            if (p != null) _centerOnUser(p);
          },
        ),
        Positioned(
          top: padding.top + 8,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                radius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 54,
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: mutedColor(context)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (value) {
                            _debounce?.cancel();
                            final normalized = value.trim();
                            if (normalized.length >= 3) {
                              final requestToken = SearchRequestGuard.nextToken(
                                  _latestSearchToken);
                              _latestSearchToken = requestToken;
                              _runSearch(normalized, requestToken);
                            }
                          },
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Where are you going?',
                          ),
                        ),
                      ),
                      if (_search.text.isNotEmpty)
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: IconButton(
                            tooltip: 'Clear search',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 40,
                              height: 40,
                            ),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              _onSearchChanged('');
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_searching ||
                  _results.isNotEmpty ||
                  _searchError != null) ...[
                const SizedBox(height: 8),
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_searching) ...[
                        const SkeletonBox(height: 48, radius: 16),
                        const SizedBox(height: 6),
                        const SkeletonBox(height: 48, radius: 16),
                      ],
                      if (!_searching && _searchError != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_searchError!),
                        ),
                      if (!_searching)
                        for (final r in _results.take(5))
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_rounded),
                            title: Text(r.name,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => _chooseResult(r),
                          ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: padding.bottom + 24 + 64 + 12,
          child: GlassSheet(
            child: _SavedSheetContent(
              picked: _picked != null,
              pickedName: _pickedName,
              onPickPlace: (place) => _pick(
                LatLng(place.latitude, place.longitude),
                name: place.name,
                moveCamera: true,
              ),
              onSetDestination: _setDestination,
              user: position,
              units: settings.units,
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedSheetContent extends ConsumerWidget {
  const _SavedSheetContent({
    required this.picked,
    required this.pickedName,
    required this.onPickPlace,
    required this.onSetDestination,
    required this.user,
    required this.units,
  });

  final bool picked;
  final String pickedName;
  final void Function(Place place) onPickPlace;
  final VoidCallback onSetDestination;
  final Position? user;
  final DistanceUnit units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider);
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(picked ? 'Selected: $pickedName' : 'Saved places',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge),
        const SizedBox(height: 12),
        places.when(
          loading: () => const Column(
            children: [
              SkeletonBox(height: 64, radius: 22),
              SizedBox(height: 10),
              SkeletonBox(height: 64, radius: 22),
            ],
          ),
          error: (_, __) => const Text('Could not load your saved places.'),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'No saved places yet. Search for a stop or tap the map, then save it on the next screen.',
                  style: text.bodyMedium?.copyWith(color: mutedColor(context)),
                ),
              );
            }
            return Column(
              children: [
                for (final p in list.take(2))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PlaceTile(
                      name: p.name,
                      subtitle: user == null
                          ? 'alarm at ${formatDistance(p.radiusMeters, units)}'
                          : '${formatDistance(distanceMeters(user!.latitude, user!.longitude, p.latitude, p.longitude), units)} away · alarm at ${formatDistance(p.radiusMeters, units)}',
                      onTap: () => onPickPlace(p),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        PrimaryButton(label: 'Set Destination', onPressed: onSetDestination),
      ],
    );
  }
}
