import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/features/local/providers/local_database_provider.dart';
import 'package:car_buying_app/domain/models/cart_item_model.dart';
import 'package:car_buying_app/domain/models/car_model.dart';

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItemModel>>(
  () => CartNotifier(),
);

final cartCountProvider = Provider<int>((ref) {
  final cartState = ref.watch(cartProvider);
  return cartState.maybeWhen(
    data: (items) => items.fold(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

class CartNotifier extends AsyncNotifier<List<CartItemModel>> {
  late final AppDatabase _db;

  @override
  Future<List<CartItemModel>> build() async {
    _db = ref.watch(appDatabaseProvider);
    return await _db.getCartItems();
  }

  Future<void> addToCart(CarModel car) async {
    state = const AsyncValue.loading();
    await _db.addToCart(car);
    state = AsyncValue.data(await _db.getCartItems());
  }

  Future<void> removeFromCart(String carId) async {
    state = const AsyncValue.loading();
    await _db.removeFromCart(carId);
    state = AsyncValue.data(await _db.getCartItems());
  }

  Future<void> clearCart() async {
    state = const AsyncValue.loading();
    await _db.clearCart();
    state = const AsyncValue.data([]);
  }

  Future<bool> isInCart(String carId) async {
    return _db.isInCart(carId);
  }
}
