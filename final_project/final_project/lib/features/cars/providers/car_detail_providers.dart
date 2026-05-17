import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/features/local/providers/local_database_provider.dart';
import '../../../domain/models/car_model.dart';

final lastViewedCarProvider = AsyncNotifierProvider<LastViewedCarNotifier, CarModel?>(
  () => LastViewedCarNotifier(),
);

class LastViewedCarNotifier extends AsyncNotifier<CarModel?> {
  late final AppDatabase _db;

  @override
  Future<CarModel?> build() async {
    _db = ref.watch(appDatabaseProvider);
    return _db.getLastViewedCarModel();
  }

  Future<void> saveLastViewedCar(CarModel car) async {
    state = const AsyncValue.loading();
    await _db.saveCarModel(car);
    state = AsyncValue.data(car);
  }

  Future<void> clearLastViewedCar() async {
    state = const AsyncValue.loading();
    await _db.clearSavedCars();
    state = const AsyncValue.data(null);
  }
}
