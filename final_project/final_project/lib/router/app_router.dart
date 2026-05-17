import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:car_buying_app/features/auth/presentation/auth_page.dart';
import 'package:car_buying_app/features/auth/providers/auth_providers.dart';
import 'package:car_buying_app/features/cart/presentation/cart_page.dart';
import 'package:car_buying_app/features/cars/presentation/car_listing_page.dart';
import 'package:car_buying_app/features/cars/presentation/car_detail_page.dart';
import 'package:car_buying_app/features/favorites/presentation/favorites_page.dart';
import 'package:car_buying_app/features/profile/presentation/profile_page.dart';

// ── Route path constants ────────────────────────────────────────
abstract class Routes {
  static const auth      = '/auth';
  static const cars      = '/cars';
  static const carDetail = 'detail/:carId'; // sub-route → /cars/detail/:carId
  static const cart      = '/cart';
  static const favorites = '/favorites';
  static const profile   = '/profile';
}

// ── Router provider ─────────────────────────────────────────────
// Watches AuthChangeNotifier so GoRouter re-runs redirect() on
// every sign-in / sign-out event (requirement: back-stack management).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: Routes.auth,
    refreshListenable: authNotifier, // re-evaluates redirect on auth change
    debugLogDiagnostics: true,

    // ── Auth guard ────────────────────────────────────────────
    redirect: (context, state) {
      final signedIn   = authNotifier.isSignedIn;
      final onAuthPage = state.matchedLocation == Routes.auth;

      if (!signedIn && !onAuthPage) return Routes.auth; // force login
      if (signedIn  &&  onAuthPage) return Routes.cars;  // skip login screen
      return null;
    },

    // ── Route tree ────────────────────────────────────────────
    routes: [
      GoRoute(
        path: Routes.auth,
        name: 'auth',
        pageBuilder: (_, state) => _fade(state, const AuthPage()),
      ),

      GoRoute(
        path: Routes.cars,
        name: 'cars',
        pageBuilder: (_, state) => _fade(state, const CarListingPage()),

        // Sub-routes (requirement: multiple sub-routes + back-stack)
        routes: [
          GoRoute(
            path: Routes.carDetail,
            name: 'carDetail',
            pageBuilder: (_, state) {
              final id = state.pathParameters['carId'] ?? '';
              return _slide(state, CarDetailPage(carId: id));
            },
          ),
        ],
      ),

      // Stub routes for upcoming sprints
      GoRoute(
        path: Routes.cart,
        name: 'cart',
        pageBuilder: (_, state) => _slide(state, const CartPage()),
      ),
      GoRoute(
        path: Routes.favorites,
        name: 'favorites',
        pageBuilder: (_, state) => _slide(state, const FavoritesPage()),
      ),
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        pageBuilder: (_, state) => _slide(state, const ProfilePage()),
      ),
    ],

    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text(
          '404 — Page not found\n${state.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white38),
        ),
      ),
    ),
  );
});

// ── Transition helpers ──────────────────────────────────────────
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

// Заглушечный экран удалён — пока не используется в маршрутах.