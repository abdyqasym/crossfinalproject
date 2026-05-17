import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:car_buying_app/main.dart';
import 'package:car_buying_app/features/auth/providers/car_providers.dart';
import 'package:car_buying_app/widgets/car_card.dart';
import 'package:car_buying_app/domain/models/car_model.dart';
import 'package:car_buying_app/features/auth/providers/auth_providers.dart';

class CarListingPage extends ConsumerStatefulWidget {
  const CarListingPage({super.key});

  @override
  ConsumerState<CarListingPage> createState() => _CarListingPageState();
}

class _CarListingPageState extends ConsumerState<CarListingPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    ref.read(carFilterProvider.notifier).update(
          (f) => f.copyWith(query: q),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    // GoRouter redirect handles navigation back to /auth
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final carsAsync = ref.watch(filteredCarsProvider);
    final filter    = ref.watch(carFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Collapsing SliverAppBar (requirement: Slivers) ──────
          _buildAppBar(filter),

          // ── Search bar ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSearchBar()),

          // ── Filter chips ───────────────────────────────────────
          SliverToBoxAdapter(child: _buildFilterChips(filter)),

          // ── Result count ───────────────────────────────────────
          SliverToBoxAdapter(child: _buildResultsHeader(carsAsync)),

          // ── Main grid (requirement: GridView for responsive layout)
          carsAsync.when(
            loading: () => _buildShimmerGrid(),
            error:   (e, _) => _buildError(e),
            data:    (cars) => cars.isEmpty
                ? _buildEmpty()
                : _buildGrid(cars),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ── SliverAppBar ───────────────────────────────────────────────
  SliverAppBar _buildAppBar(CarFilter filter) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppTheme.bg,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.gold,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  color: Colors.black, size: 15),
            ),
            const SizedBox(width: 10),
            const Text(
              'AutoVault',
              style: TextStyle(
                color: AppTheme.textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.bg),
            // Subtle top-right glow
            Positioned(
              top: -40, right: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.gold.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.go('/favorites'),
          icon: const Icon(Icons.favorite_border_rounded, color: AppTheme.textMed),
          tooltip: 'Favorites',
        ),
        IconButton(
          onPressed: () => context.go('/cart'),
          icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textMed),
          tooltip: 'Cart',
        ),
        IconButton(
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person_outline_rounded, color: AppTheme.textMed),
          tooltip: 'Profile',
        ),
        // Sort button
        IconButton(
          onPressed: () => _showSortSheet(filter),
          icon: const Icon(Icons.sort_rounded, color: AppTheme.textMed),
          tooltip: 'Sort',
        ),
        // Sign-out
        IconButton(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded, color: AppTheme.textMed),
          tooltip: 'Sign out',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppTheme.textHigh, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search make, model, year…',
          prefixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.search_rounded, color: AppTheme.textMed, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchCtrl,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
              icon: const Icon(Icons.clear_rounded,
                  color: AppTheme.textMed, size: 18),
              onPressed: () {
                _searchCtrl.clear();
                _onSearchChanged('');
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────
  Widget _buildFilterChips(CarFilter filter) {
    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        scrollDirection: Axis.horizontal,
        children: [
          // Condition filters
          for (final cond in ['New', 'Used', 'Certified Pre-Owned'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: cond,
                selected: filter.condition == cond,
                onTap: () => ref.read(carFilterProvider.notifier).update(
                      (f) => filter.condition == cond
                      ? f.copyWith(clearCondition: true)
                      : f.copyWith(condition: cond),
                ),
              ),
            ),
          // Fuel type filter
          for (final fuel in ['Electric', 'Hybrid'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: fuel,
                selected: filter.fuelType == fuel,
                icon: fuel == 'Electric'
                    ? Icons.bolt_rounded
                    : Icons.eco_outlined,
                onTap: () => ref.read(carFilterProvider.notifier).update(
                      (f) => filter.fuelType == fuel
                      ? f.copyWith(clearFuelType: true)
                      : f.copyWith(fuelType: fuel),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Results count header ───────────────────────────────────────
  Widget _buildResultsHeader(AsyncValue<List<CarModel>> carsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          carsAsync.when(
            loading: () => const Text('Loading…',
                style: TextStyle(color: AppTheme.textMed, fontSize: 13)),
            error: (_, __) => const SizedBox.shrink(),
            data: (cars) => Text(
              '${cars.length} vehicle${cars.length == 1 ? '' : 's'} found',
              style: const TextStyle(
                  color: AppTheme.textMed,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
          // Active filter count badge
          Consumer(
            builder: (_, ref, __) {
              final f = ref.watch(carFilterProvider);
              final count = [f.condition, f.fuelType, f.maxPrice]
                  .where((v) => v != null)
                  .length;
              if (count == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => ref
                    .read(carFilterProvider.notifier)
                    .update((_) => const CarFilter()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.gold.withOpacity(0.35)),
                  ),
                  child: Text(
                    'Clear $count filter${count > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Car grid (requirement: SliverGrid for responsive design) ───
  Widget _buildGrid(List<CarModel> cars) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (context, i) => CarCard(car: cars[i]),
          childCount: cars.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,       // 2 columns
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72, // tall enough for image + info
        ),
      ),
    );
  }

  // ── Shimmer loading grid ───────────────────────────────────────
  Widget _buildShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
              (_, __) => const _ShimmerCard(),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────
  Widget _buildError(Object error) {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.red, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load cars',
                  style: TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textMed, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(allCarsProvider),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────
  Widget _buildEmpty() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppTheme.textLow, size: 56),
            const SizedBox(height: 16),
            const Text('No cars match your search',
                style: TextStyle(
                    color: AppTheme.textMed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                ref.read(carFilterProvider.notifier)
                    .update((_) => const CarFilter());
              },
              child: const Text('Clear all filters'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────
  void _showSortSheet(CarFilter filter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final options = {
          CarSort.priceAsc:  'Price: Low to High',
          CarSort.priceDesc: 'Price: High to Low',
          CarSort.yearDesc:  'Newest First',
          CarSort.mileageAsc:'Lowest Mileage',
        };
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort by',
                  style: TextStyle(
                      color: AppTheme.textHigh,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...options.entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.value,
                    style: TextStyle(
                      color: filter.sort == e.key
                          ? AppTheme.gold
                          : AppTheme.textHigh,
                      fontWeight: filter.sort == e.key
                          ? FontWeight.w700
                          : FontWeight.w400,
                    )),
                trailing: filter.sort == e.key
                    ? const Icon(Icons.check_rounded,
                    color: AppTheme.gold, size: 18)
                    : null,
                onTap: () {
                  ref
                      .read(carFilterProvider.notifier)
                      .update((f) => f.copyWith(sort: e.key));
                  Navigator.of(context).pop();
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Filter chip widget
// ─────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String    label;
  final bool      selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.gold.withOpacity(0.18)
              : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.gold : AppTheme.divider,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? AppTheme.gold : AppTheme.textMed),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.gold : AppTheme.textMed,
                fontSize: 12,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shimmer placeholder card (shown while loading)
// ─────────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shade = Color.lerp(
          AppTheme.card,
          AppTheme.surface,
          _anim.value,
        )!;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(color: shade),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 9,
                        width: 70,
                        decoration: BoxDecoration(
                            color: shade,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 7),
                    Container(
                        height: 13,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: shade,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                          height: 22,
                          width: 65,
                          decoration: BoxDecoration(
                              color: shade,
                              borderRadius: BorderRadius.circular(6))),
                      const SizedBox(width: 6),
                      Container(
                          height: 22,
                          width: 55,
                          decoration: BoxDecoration(
                              color: shade,
                              borderRadius: BorderRadius.circular(6))),
                    ]),
                    const SizedBox(height: 14),
                    Container(
                        height: 1, color: AppTheme.divider),
                    const SizedBox(height: 12),
                    Container(
                        height: 18,
                        width: 100,
                        decoration: BoxDecoration(
                            color: shade,
                            borderRadius: BorderRadius.circular(4))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}