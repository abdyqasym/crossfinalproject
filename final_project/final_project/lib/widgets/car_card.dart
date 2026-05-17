import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:car_buying_app/main.dart';
import 'package:car_buying_app/domain/models/car_model.dart';

class CarCard extends StatefulWidget {
  const CarCard({super.key, required this.car});
  final CarModel car;

  @override
  State<CarCard> createState() => _CarCardState();
}

class _CarCardState extends State<CarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _scale = Tween(begin: 1.0, end: 0.965)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final car = widget.car;
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) => _ctrl.reverse(),
      onTapCancel: ()  => _ctrl.reverse(),
      onTap:       ()  => context.go('/cars/detail/${car.id}'),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CarImage(car: car),
              _CarInfo(car: car),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image section with overlay badges ────────────────────────────
class _CarImage extends StatelessWidget {
  const _CarImage({required this.car});
  final CarModel car;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
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
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppTheme.surface,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.gold),
                  ),
                ),
              );
            },
          ),
        ),
        // Gradient fade at the bottom for text contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.card.withOpacity(0.9),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        // Condition badge — top left
        Positioned(
          top: 10, left: 10,
          child: _ConditionBadge(condition: car.condition),
        ),
        // Fuel badge — top right
        Positioned(
          top: 10, right: 10,
          child: _FuelBadge(fuelType: car.fuelType),
        ),
      ],
    );
  }
}

// ── Text/info section ─────────────────────────────────────────────
class _CarInfo extends StatelessWidget {
  const _CarInfo({required this.car});
  final CarModel car;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year · Make
          Text(
            '${car.year}  ·  ${car.make}',
            style: const TextStyle(
              color: AppTheme.gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 3),

          // Model
          Text(
            car.model,
            style: const TextStyle(
              color: AppTheme.textHigh,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Stat chips
          Row(children: [
            _Chip(icon: Icons.speed_rounded, label: car.formattedMileage),
            const SizedBox(width: 6),
            _Chip(
              icon: Icons.settings_outlined,
              label: car.transmission.split('-').last.trim(),
            ),
          ]),
          const SizedBox(height: 10),

          const Divider(height: 1),
          const SizedBox(height: 10),

          // Price + rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ASKING PRICE',
                    style: TextStyle(
                      color: AppTheme.textLow,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    car.formattedPrice,
                    style: const TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Rating
              if (car.rating != null)
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const Icon(Icons.star_rounded,
                      color: AppTheme.gold, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    car.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                        color: AppTheme.textMed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  if (car.reviewCount != null) ...[
                    const SizedBox(width: 3),
                    Text('(${car.reviewCount})',
                        style: const TextStyle(
                            color: AppTheme.textLow, fontSize: 11)),
                  ],
                ]),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String   label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppTheme.divider, width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppTheme.textLow),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(
              color: AppTheme.textMed,
              fontSize: 11,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Condition badge ───────────────────────────────────────────────
class _ConditionBadge extends StatelessWidget {
  const _ConditionBadge({required this.condition});
  final String condition;

  Color get _color => switch (condition) {
    'New'                 => AppTheme.green,
    'Certified Pre-Owned' => AppTheme.gold,
    _                     => AppTheme.textMed,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _color.withOpacity(0.4), width: 0.8),
    ),
    child: Text(
      condition.toUpperCase(),
      style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9),
    ),
  );
}

// ── Fuel type badge ───────────────────────────────────────────────
class _FuelBadge extends StatelessWidget {
  const _FuelBadge({required this.fuelType});
  final String fuelType;

  bool get _isElectric => fuelType == 'Electric';

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: _isElectric
            ? Colors.greenAccent.withOpacity(0.5)
            : Colors.white12,
        width: 0.8,
      ),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        _isElectric
            ? Icons.bolt_rounded
            : Icons.local_gas_station_outlined,
        size: 10,
        color: _isElectric ? Colors.greenAccent : AppTheme.textMed,
      ),
      const SizedBox(width: 4),
      Text(
        fuelType.toUpperCase(),
        style: TextStyle(
          color: _isElectric ? Colors.greenAccent : AppTheme.textMed,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    ]),
  );
}