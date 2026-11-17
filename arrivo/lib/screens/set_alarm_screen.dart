import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/permission_flow.dart';
import '../core/ui_helpers.dart';
import '../models/app_settings.dart';
import '../models/destination_args.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../widgets/arrivo_map.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_page.dart';
import '../widgets/glass_segmented.dart';
import '../widgets/glass_sheet.dart';
import '../widgets/glass_switch.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/play_button.dart';
import '../widgets/primary_button.dart';

const _ringtoneKinds = {'alarm': 'Alarm', 'ringtone': 'Ringtone', 'notification': 'Notification'};

/// Floating glass sheet over the map: radius, sound, vibration, and Start Trip.
class SetAlarmScreen extends ConsumerStatefulWidget {
  const SetAlarmScreen({super.key, required this.args});
  final DestinationArgs args;

  @override
  ConsumerState<SetAlarmScreen> createState() => _SetAlarmScreenState();
}

class _SetAlarmScreenState extends ConsumerState<SetAlarmScreen> {
  final MapController _map = MapController();
  late final TextEditingController _name = TextEditingController(text: widget.args.name);
  late double _radius =
      widget.args.radiusMeters ?? ref.read(settingsProvider).defaultRadius;
  bool _mapReady = false;
  bool _starting = false;

  LatLng get _destination => LatLng(widget.args.latitude, widget.args.longitude);

  @override
  void dispose() {
    _name.dispose();
    _map.dispose();
    super.dispose();
  }

  void _refit() {
    if (!_mapReady) return;
    _map.move(_destination, zoomForSpan(_radius * 2.4, _destination.latitude, pixels: 170));
  }

  Future<void> _pickFile() async {
    final path = await ref.read(soundFileStoreProvider).pickAndStore();
    if (path == null) return;
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(soundMode: SoundMode.file, soundPath: path));
  }

  Future<void> _savePlace() async {
    await ref.read(placesProvider.notifier).add(
          name: _name.text,
          latitude: widget.args.latitude,
          longitude: widget.args.longitude,
          radiusMeters: _radius,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Place saved.')));
  }

  Future<void> _start() async {
    final allowed = await ensureTripPermissions(context, ref);
    if (!allowed || !mounted) return;
    setState(() => _starting = true);
    try {
      await ref.read(tripControllerProvider.notifier).start(
            name: _name.text,
            latitude: widget.args.latitude,
            longitude: widget.args.longitude,
            radiusMeters: _radius,
          );
      if (mounted) context.go('/trip');
    } catch (_) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start the trip. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final previewing = ref.watch(previewProvider);
    final text = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final kind = _ringtoneKinds.containsKey(settings.soundPath) ? settings.soundPath! : 'alarm';
    final hasFile = settings.soundPath != null && !_ringtoneKinds.containsKey(settings.soundPath);

    Widget soundDetail;
    switch (settings.soundMode) {
      case SoundMode.phoneDefault:
        soundDetail = Text('Your phone’s default alarm tone', style: text.bodyMedium);
      case SoundMode.ringtone:
        soundDetail = GlassSegmented<String>(
          options: _ringtoneKinds,
          value: kind,
          onChanged: (k) => notifier.update((s) => s.copyWith(soundPath: k)),
        );
      case SoundMode.file:
        soundDetail = Row(
          children: [
            Expanded(
              child: Text(
                hasFile
                    ? ref.read(soundFileStoreProvider).displayName(settings.soundPath!)
                    : 'No file chosen',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
            ),
            TextButton(onPressed: _pickFile, child: const Text('Choose file')),
          ],
        );
    }

    return Scaffold(
      backgroundColor: GlassBackground.baseColor(context, GlassBackdrop.theme),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.46,
            child: ArrivoMap(
              controller: _map,
              initialCenter: _destination,
              initialZoom: zoomForSpan(_radius * 2.4, _destination.latitude, pixels: 170),
              destination: _destination,
              radiusMeters: _radius,
              onReady: () => _mapReady = true,
            ),
          ),
          Positioned(
            top: padding.top + 8,
            left: 16,
            child: GlassBackButton(onPressed: () => context.pop()),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12 + padding.bottom,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: size.height * 0.64),
              child: GlassSheet(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Set arrival alarm', style: text.titleLarge),
                      const SizedBox(height: 14),
                      GlassTextField(label: 'Stop name', controller: _name),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Alert me when within',
                                style: text.bodyMedium?.copyWith(color: mutedColor(context))),
                          ),
                          Text(formatDistance(_radius, settings.units), style: text.titleMedium),
                        ],
                      ),
                      Slider(
                        value: _radius,
                        min: AppConstants.minRadiusMeters,
                        max: AppConstants.maxRadiusMeters,
                        divisions: 36,
                        label: formatDistance(_radius, settings.units),
                        onChanged: (v) {
                          setState(() => _radius = v);
                          _refit();
                        },
                      ),
                      const SizedBox(height: 4),
                      Text('Alarm sound',
                          style: text.bodyMedium?.copyWith(color: mutedColor(context))),
                      const SizedBox(height: 8),
                      GlassSegmented<SoundMode>(
                        options: const {
                          SoundMode.phoneDefault: 'Phone default',
                          SoundMode.ringtone: 'Ringtones',
                          SoundMode.file: 'File',
                        },
                        value: settings.soundMode,
                        onChanged: (m) => notifier.update((s) => s.copyWith(soundMode: m)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.only(left: 14, right: 4),
                        decoration: BoxDecoration(
                          color: rowFill(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: soundDetail),
                            PlayButton(
                              playing: previewing,
                              onPressed: () =>
                                  ref.read(previewProvider.notifier).toggle(settings),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('Vibration', style: text.bodyLarge)),
                          GlassSwitch(
                            value: settings.vibration,
                            semanticLabel: 'Vibration',
                            onChanged: (v) => notifier.update((s) => s.copyWith(vibration: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(label: 'Start Trip', busy: _starting, onPressed: _start),
                      const SizedBox(height: 10),
                      GlassButton(label: 'Save place', icon: Icons.bookmark_add_rounded, onPressed: _savePlace),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
