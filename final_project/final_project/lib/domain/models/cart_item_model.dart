import 'package:car_buying_app/domain/models/car_model.dart';

class CartItemModel {
  CartItemModel({required this.car, required this.quantity});

  final CarModel car;
  final int quantity;
}
