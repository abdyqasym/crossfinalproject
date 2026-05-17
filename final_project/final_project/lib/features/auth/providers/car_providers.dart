import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/car_model.dart';

// ─────────────────────────────────────────────────────────────────
// Filter / Sort value objects
// ─────────────────────────────────────────────────────────────────
enum CarSort { priceAsc, priceDesc, yearDesc, mileageAsc }

class CarFilter {
  const CarFilter({
    this.condition,
    this.fuelType,
    this.maxPrice,
    this.query = '',
    this.sort = CarSort.priceAsc,
  });

  final String?  condition; // 'New' | 'Used' | 'Certified Pre-Owned'
  final String?  fuelType;  // 'Gasoline' | 'Electric' | 'Hybrid'
  final double?  maxPrice;
  final String   query;
  final CarSort  sort;

  CarFilter copyWith({
    String?  condition,
    String?  fuelType,
    double?  maxPrice,
    String?  query,
    CarSort? sort,
    bool     clearCondition = false,
    bool     clearFuelType  = false,
    bool     clearMaxPrice  = false,
  }) =>
      CarFilter(
        condition: clearCondition ? null : condition ?? this.condition,
        fuelType:  clearFuelType  ? null : fuelType  ?? this.fuelType,
        maxPrice:  clearMaxPrice  ? null : maxPrice  ?? this.maxPrice,
        query:     query     ?? this.query,
        sort:      sort      ?? this.sort,
      );
}

// ─────────────────────────────────────────────────────────────────
// CarsRepository  (Data layer)
//
// fetchAll() currently returns seed data with a simulated delay.
// ── When the Chopper API is ready, swap this body with:
//    return ref.watch(carChopperServiceProvider).getCars();
// ─────────────────────────────────────────────────────────────────
class CarsRepository {
  Future<List<CarModel>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return kSeedCars;
  }
}

final carsRepositoryProvider = Provider<CarsRepository>((_) => CarsRepository());

// ─────────────────────────────────────────────────────────────────
// allCarsProvider — raw unfiltered list, cached by Riverpod
// ─────────────────────────────────────────────────────────────────
final allCarsProvider = FutureProvider<List<CarModel>>(
      (ref) => ref.watch(carsRepositoryProvider).fetchAll(),
);

// ─────────────────────────────────────────────────────────────────
// carFilterProvider — mutable filter / sort state
// ─────────────────────────────────────────────────────────────────
final carFilterProvider = StateProvider<CarFilter>((_) => const CarFilter());

// ─────────────────────────────────────────────────────────────────
// filteredCarsProvider — derived: apply filter + sort on top of raw list
// ─────────────────────────────────────────────────────────────────
final filteredCarsProvider = Provider<AsyncValue<List<CarModel>>>((ref) {
  final allAsync = ref.watch(allCarsProvider);
  final filter   = ref.watch(carFilterProvider);

  return allAsync.whenData((cars) {
    var result = cars.where((c) {
      final q = filter.query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          c.make.toLowerCase().contains(q) ||
          c.model.toLowerCase().contains(q) ||
          c.year.toString().contains(q) ||
          c.color.toLowerCase().contains(q);

      final matchesCondition =
          filter.condition == null || c.condition == filter.condition;
      final matchesFuel =
          filter.fuelType == null || c.fuelType == filter.fuelType;
      final matchesPrice =
          filter.maxPrice == null || c.price <= filter.maxPrice!;

      return matchesQuery && matchesCondition && matchesFuel && matchesPrice;
    }).toList();

    switch (filter.sort) {
      case CarSort.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
      case CarSort.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
      case CarSort.yearDesc:
        result.sort((a, b) => b.year.compareTo(a.year));
      case CarSort.mileageAsc:
        result.sort((a, b) => a.mileage.compareTo(b.mileage));
    }

    return result;
  });
});