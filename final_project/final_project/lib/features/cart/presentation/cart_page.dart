import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_buying_app/main.dart';
import 'package:car_buying_app/features/cart/providers/cart_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: cartState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (_, __) => const Center(
          child: Text('Unable to load cart', style: TextStyle(color: AppTheme.textMed)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Your cart is empty.', style: TextStyle(color: AppTheme.textMed)),
            );
          }

          final total = items.fold<double>(0, (sum, item) => sum + item.car.price * item.quantity);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.car.displayName,
                                    style: const TextStyle(
                                        color: AppTheme.gold,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(item.car.formattedPrice,
                                    style: const TextStyle(
                                        color: AppTheme.textHigh,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Text('Qty: ${item.quantity}',
                                    style: const TextStyle(
                                        color: AppTheme.textMed, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).removeFromCart(item.car.id);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMed),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(top: BorderSide(color: AppTheme.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Total: \$${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.textHigh,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clearCart();
                      },
                      child: const Text('Clear cart'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
