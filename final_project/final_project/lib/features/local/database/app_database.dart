import 'package:drift/drift.dart';
import 'package:car_buying_app/domain/models/car_model.dart';
import 'package:car_buying_app/domain/models/cart_item_model.dart';
import 'package:car_buying_app/features/profile/model/profile_model.dart';

import 'database_connection.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get email => text().withLength(min: 1, max: 120)();
  TextColumn get phone => text().withLength(min: 1, max: 40)();
}

class SavedCars extends Table {
  TextColumn get id => text()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  IntColumn get year => integer()();
  RealColumn get price => real()();
  IntColumn get mileage => integer()();
  TextColumn get fuelType => text()();
  TextColumn get transmission => text()();
  TextColumn get condition => text()();
  TextColumn get color => text()();
  TextColumn get imageUrl => text()();
  TextColumn get description => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get reviewCount => integer().nullable()();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Favorites extends Table {
  TextColumn get carId => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {carId};
}

class CartItems extends Table {
  TextColumn get carId => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {carId};
}

@DriftDatabase(tables: [Profiles, SavedCars, Favorites, CartItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;

  Future<ProfileModel?> getProfileModel() async {
    final row = await select(profiles).getSingleOrNull();
    if (row == null) return null;
    return ProfileModel(name: row.name, email: row.email, phone: row.phone);
  }

  Future<void> upsertProfile(ProfileModel profile) async {
    await into(profiles).insert(
      ProfilesCompanion.insert(
        name: profile.name,
        email: profile.email,
        phone: profile.phone,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> clearProfile() async {
    await delete(profiles).go();
  }

  Future<CarModel?> getLastViewedCarModel() async {
    final query = select(savedCars)
      ..orderBy([(t) => OrderingTerm.desc(t.savedAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _carModelFromRow(row);
  }

  Future<void> saveCarModel(CarModel car) async {
    await into(savedCars).insert(
      SavedCarsCompanion.insert(
        id: car.id,
        make: car.make,
        model: car.model,
        year: car.year,
        price: car.price,
        mileage: car.mileage,
        fuelType: car.fuelType,
        transmission: car.transmission,
        condition: car.condition,
        color: car.color,
        imageUrl: car.imageUrl,
        description: Value(car.description),
        rating: Value(car.rating),
        reviewCount: Value(car.reviewCount),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<CarModel>> getFavoriteCars() async {
    final query = select(savedCars).join([
      innerJoin(favorites, favorites.carId.equalsExp(savedCars.id)),
    ]);
    final rows = await query.get();
    return rows.map((r) => _carModelFromRow(r.readTable(savedCars))).toList();
  }

  Future<void> addFavorite(CarModel car) async {
    await saveCarModel(car);
    await into(favorites).insert(
      FavoritesCompanion.insert(carId: car.id),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeFavorite(String carId) async {
    await (delete(favorites)..where((tbl) => tbl.carId.equals(carId))).go();
  }

  Future<bool> isFavorite(String carId) async {
    final row = await (select(favorites)..where((tbl) => tbl.carId.equals(carId))).getSingleOrNull();
    return row != null;
  }

  Future<List<CartItemModel>> getCartItems() async {
    final query = select(savedCars).join([
      innerJoin(cartItems, cartItems.carId.equalsExp(savedCars.id)),
    ]);
    final rows = await query.get();
    return rows.map((row) {
      final car = _carModelFromRow(row.readTable(savedCars));
      final cart = row.readTable(cartItems);
      return CartItemModel(car: car, quantity: cart.quantity);
    }).toList();
  }

  Future<void> addToCart(CarModel car) async {
    await saveCarModel(car);
    final entry = await (select(cartItems)..where((tbl) => tbl.carId.equals(car.id))).getSingleOrNull();
    if (entry == null) {
      await into(cartItems).insert(CartItemsCompanion.insert(carId: car.id));
    } else {
      await (update(cartItems)..where((tbl) => tbl.carId.equals(car.id))).write(
        CartItemsCompanion(quantity: Value(entry.quantity + 1)),
      );
    }
  }

  Future<void> removeFromCart(String carId) async {
    await (delete(cartItems)..where((tbl) => tbl.carId.equals(carId))).go();
  }

  Future<void> clearCart() async {
    await delete(cartItems).go();
  }

  Future<bool> isInCart(String carId) async {
    final row = await (select(cartItems)..where((tbl) => tbl.carId.equals(carId))).getSingleOrNull();
    return row != null;
  }

  Future<void> clearSavedCars() async {
    await delete(savedCars).go();
  }

  CarModel _carModelFromRow(SavedCar row) => CarModel(
        id: row.id,
        make: row.make,
        model: row.model,
        year: row.year,
        price: row.price,
        mileage: row.mileage,
        fuelType: row.fuelType,
        transmission: row.transmission,
        condition: row.condition,
        color: row.color,
        imageUrl: row.imageUrl,
        description: row.description,
        rating: row.rating,
        reviewCount: row.reviewCount,
      );
}
