import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/address_card.dart';
import '../../logic/providers.dart';
import '../../ui/screens/splash_screen.dart';
import '../../ui/screens/onboarding_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/signup_screen.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/compass_screen.dart';
import '../../ui/screens/route_screen.dart';
import '../../ui/screens/scan_screen.dart';
import '../../ui/screens/create_card_screen.dart';
import '../../ui/screens/card_detail_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/shell/app_shell.dart';

/// Slide-from-right + fade, with a subtle parallax on the outgoing page.
CustomTransitionPage<T> _slidePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final out =
          CurvedAnimation(parent: secondary, curve: Curves.easeOutCubic);
      return SlideTransition(
        position:
            Tween(begin: Offset.zero, end: const Offset(-0.25, 0)).animate(out),
        child: SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(curved),
          child: FadeTransition(
              opacity: Tween<double>(begin: 0.4, end: 1).animate(curved),
              child: child),
        ),
      );
    },
  );
}

/// Cross-fade with a gentle scale — for auth / onboarding hops.
CustomTransitionPage<T> _fadePage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // No redirect on splash/onboarding/auth screens
      final path = state.matchedLocation;
      final isAuthPath = path == '/login' || path == '/signup';
      final isPublicPath = path.startsWith('/card/') ||
          path.startsWith('/c/') ||
          path.startsWith('/digipin/') ||
          path == '/splash' ||
          path == '/onboarding';
      if (isPublicPath || isAuthPath) return null;

      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      if (authState.user == null) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          pageBuilder: (_, st) => _fadePage(st, const OnboardingScreen())),
      GoRoute(
          path: '/login',
          pageBuilder: (_, st) => _fadePage(st, const LoginScreen())),
      GoRoute(
          path: '/signup',
          pageBuilder: (_, st) => _slidePage(st, const SignupScreen())),

      // Persistent bottom-nav shell — Home & Cards each keep their own stack.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/compass', builder: (_, __) => const CompassScreen()),
          ]),
        ],
      ),

      // Web alias — https://…/digipin/<pin> shows the same screen as /card/<pin>.
      GoRoute(
        path: '/digipin/:digipin',
        redirect: (_, state) =>
            '/card/${state.pathParameters['digipin']!.toUpperCase()}',
      ),
      GoRoute(
        path: '/route',
        pageBuilder: (_, st) => _slidePage(st, const RouteScreen()),
      ),
      // Scanner used as a picker (returns the scanned DIGIPIN to the caller).
      GoRoute(
        path: '/scan-pick',
        pageBuilder: (_, st) => _slidePage(st, const ScanScreen(pickMode: true)),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, st) => _slidePage(st, const ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, st) => _slidePage(st, const SettingsScreen()),
      ),
      GoRoute(
        path: '/create',
        pageBuilder: (_, st) => _slidePage(st, const CreateCardScreen()),
      ),
      GoRoute(
        path: '/edit',
        pageBuilder: (_, state) => _slidePage(
            state, CreateCardScreen(existing: state.extra as AddressCard)),
      ),
      // Private share link (works signed-out): https://…/c/<token>
      GoRoute(
        path: '/c/:token',
        pageBuilder: (_, state) => _slidePage(
          state,
          CardDetailScreen(token: state.pathParameters['token']!),
        ),
      ),
      // Own card, opened from the list (the full card travels in `extra`).
      GoRoute(
        path: '/my/:id',
        pageBuilder: (_, state) => _slidePage(
          state,
          CardDetailScreen(
            cardId: state.pathParameters['id']!,
            initial: state.extra is AddressCard ? state.extra as AddressCard : null,
          ),
        ),
      ),
      GoRoute(
        path: '/card/:digipin',
        pageBuilder: (_, state) => _slidePage(
          state,
          CardDetailScreen(digipin: state.pathParameters['digipin']!),
        ),
      ),
    ],
  );
});
