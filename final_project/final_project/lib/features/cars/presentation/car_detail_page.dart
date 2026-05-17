import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';
import '../../../domain/models/car_model.dart';
import '../../cart/providers/cart_providers.dart';
import '../../favorites/providers/favorites_providers.dart';
import '../providers/car_detail_providers.dart';

class CarDetailPage extends ConsumerStatefulWidget {
  const CarDetailPage({super.key, required this.carId});

  final String carId;

  @override
  ConsumerState<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends ConsumerState<CarDetailPage> {
  late final CarModel? _car;

  @override
  void initState() {
    super.initState();
    _car = _findCar(widget.carId);
    if (_car != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(lastViewedCarProvider.notifier).saveLastViewedCar(_car);
      });
    }
  }

  CarModel? _findCar(String carId) {
    try {
      return kSeedCars.firstWhere((car) => car.id == carId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveNow() async {
    final car = _car;
    if (car == null) return;
    await ref.read(lastViewedCarProvider.notifier).saveLastViewedCar(car);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Car details saved locally')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteState = ref.watch(favoritesProvider);
    final cartState = ref.watch(cartProvider);
    final lastViewed = ref.watch(lastViewedCarProvider);

    final isSaved = lastViewed.when(
      data: (car) => car?.id == _car?.id,
      loading: () => false,
      error: (_, __) => false,
    );

    final isFavorite = favoriteState.when(
      data: (cars) => cars.any((item) => item.id == _car?.id),
      loading: () => false,
      error: (_, __) => false,
    );

    final isInCart = cartState.when(
      data: (items) => items.any((item) => item.car.id == _car?.id),
      loading: () => false,
      error: (_, __) => false,
    );

    final car = _car;
    if (car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Detail')),
        body: const Center(
          child: Text('Car not found', style: TextStyle(color: AppTheme.textMed)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Car Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                car.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surface,
                  child: const Center(
                    child: Icon(Icons.directions_car_outlined,
                        color: AppTheme.textLow, size: 42),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.displayName,
                      style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(car.formattedPrice,
                      style: const TextStyle(
                          color: AppTheme.textHigh,
                          fontSize: 28,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DetailChip(label: car.fuelType),
                      _DetailChip(label: car.transmission),
                      _DetailChip(label: car.condition),
                      _DetailChip(label: car.color),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('About this car',
                      style: TextStyle(
                          color: AppTheme.textHigh,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text(
                    car.description ??
                        'This car is a premium example with strong performance and luxurious features.',
                    style: const TextStyle(
                        color: AppTheme.textMed, fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isFavorite) {
                              await ref.read(favoritesProvider.notifier).removeFavorite(car.id);
                            } else {
                              await ref.read(favoritesProvider.notifier).addFavorite(car);
                            }
                          },
                          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border_rounded),
                          label: Text(isFavorite ? 'Remove from favorites' : 'Save to favorites'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isInCart
                              ? null
                              : () async {
                                  await ref.read(cartProvider.notifier).addToCart(car);
                                },
                          icon: Icon(isInCart ? Icons.check : Icons.shopping_cart_outlined),
                          label: Text(isInCart ? 'Added to cart' : 'Add to cart'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSaved ? null : _saveNow,
                    child: Text(isSaved
                        ? 'Already saved locally'
                        : 'Save car details locally'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.textMed, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isSaved
                            ? 'This car is currently stored locally.'
                            : 'Open any car to save its details.',
                        style: const TextStyle(
                            color: AppTheme.textMed, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.textHigh, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
