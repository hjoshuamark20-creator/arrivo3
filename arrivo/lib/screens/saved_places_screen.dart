import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/ui_helpers.dart';
import '../models/destination_args.dart';
import '../models/place.dart';
import '../providers/providers.dart';
import '../services/geo_utils.dart';
import '../widgets/animated_bits.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_page.dart';
import '../widgets/glass_tab_bar.dart';
import '../widgets/place_tile.dart';
import '../widgets/primary_button.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentPositionProvider).valueOrNull;
    final text = Theme.of(context).textTheme;

    String subtitleFor(Place p) {
      final radius = 'alarm at ${formatDistance(p.radiusMeters, settings.units)}';
      if (user == null) return radius;
      final away = distanceMeters(user.latitude, user.longitude, p.latitude, p.longitude);
      return '${formatDistance(away, settings.units)} away · $radius';
    }

    return GlassPage(
      title: 'Saved places',
      child: places.when(
        loading: () => ListView(
          children: const [
            SkeletonBox(height: 64, radius: 22),
            SizedBox(height: 12),
            SkeletonBox(height: 64, radius: 22),
            SizedBox(height: 12),
            SkeletonBox(height: 64, radius: 22),
          ],
        ),
        error: (_, __) => const Center(child: Text('Could not load your saved places.')),
        data: (list) => ListView(
          padding: EdgeInsets.only(bottom: tabBarClearance(context)),
          children: [
            if (list.isEmpty)
              GlassCard(
                radius: 32,
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withAlpha(64),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bookmark_add_rounded,
                          size: 34, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('No saved places yet', style: text.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Save the stops you use often, like Home, School, or the Terminal, and start a trip with one tap.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: mutedColor(context)),
                    ),
                  ],
                ),
              )
            else ...[
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: ValueKey(p.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withAlpha(51),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
                    ),
                    onDismissed: (_) {
                      ref.read(placesProvider.notifier).remove(p.id);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Deleted ${p.name}')));
                    },
                    child: PlaceTile(
                      name: p.name,
                      subtitle: subtitleFor(p),
                      onTap: () => context.push(
                        '/set-alarm',
                        extra: DestinationArgs(
                          name: p.name,
                          latitude: p.latitude,
                          longitude: p.longitude,
                          radiusMeters: p.radiusMeters,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Tap a place to start a trip. Swipe left to delete.',
                  style: text.bodySmall?.copyWith(color: mutedColor(context)),
                ),
              ),
            ],
            const SizedBox(height: 4),
            PrimaryButton(label: 'Add new place', onPressed: () => context.go('/home')),
          ],
        ),
      ),
    );
  }
}
