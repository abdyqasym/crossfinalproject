import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/features/local/providers/local_database_provider.dart';
import 'package:car_buying_app/domain/models/car_model.dart';

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<CarModel>>(
  () => FavoritesNotifier(),
);

class FavoritesNotifier extends AsyncNotifier<List<CarModel>> {
  late final AppDatabase _db;

  @override
  Future<List<CarModel>> build() async {
    _db = ref.watch(appDatabaseProvider);
    return _db.getFavoriteCars();
  }

  Future<void> addFavorite(CarModel car) async {
    state = const AsyncValue.loading();
    await _db.addFavorite(car);
    state = AsyncValue.data(await _db.getFavoriteCars());
  }

  Future<void> removeFavorite(String carId) async {
    state = const AsyncValue.loading();
    await _db.removeFavorite(carId);
    state = AsyncValue.data(await _db.getFavoriteCars());
  }

  Future<bool> isFavorite(String carId) async {
    return _db.isFavorite(carId);
  }
}
