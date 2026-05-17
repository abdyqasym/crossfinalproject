// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarModel _$CarModelFromJson(Map<String, dynamic> json) => CarModel(
      id: json['id'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      mileage: (json['mileage'] as num).toInt(),
      fuelType: json['fuel_type'] as String,
      transmission: json['transmission'] as String,
      condition: json['condition'] as String,
      color: json['color'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CarModelToJson(CarModel instance) => <String, dynamic>{
      'id': instance.id,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'price': instance.price,
      'mileage': instance.mileage,
      'fuel_type': instance.fuelType,
      'transmission': instance.transmission,
      'condition': instance.condition,
      'color': instance.color,
      'image_url': instance.imageUrl,
      'description': instance.description,
      'rating': instance.rating,
      'review_count': instance.reviewCount,
    };
