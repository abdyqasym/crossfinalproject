import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/main.dart';
import 'package:car_buying_app/features/favorites/providers/favorites_providers.dart';
import 'package:car_buying_app/widgets/car_card.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (error, _) => Center(
          child: Text('Unable to load favorites', style: const TextStyle(color: AppTheme.textMed)),
        ),
        data: (cars) {
          if (cars.isEmpty) {
            return const Center(
              child: Text('Your favorites list is empty.', style: TextStyle(color: AppTheme.textMed)),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: cars.length,
              itemBuilder: (_, index) {
                final car = cars[index];
                return CarCard(car: car);
              },
            ),
          );
        },
      ),
    );
  }
}
