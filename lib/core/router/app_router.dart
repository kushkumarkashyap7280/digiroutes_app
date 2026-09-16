import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/providers.dart';
import '../../ui/screens/splash_screen.dart';
import '../../ui/screens/onboarding_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/signup_screen.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/dashboard_screen.dart';
import '../../ui/screens/create_card_screen.dart';
import '../../ui/screens/card_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // No redirect on splash/onboarding/auth screens
      final path = state.matchedLocation;
      final isAuthPath = path == '/login' || path == '/signup';
      final isPublicPath = path.startsWith('/card/') ||
          path == '/splash' || path == '/onboarding';
      if (isPublicPath || isAuthPath) return null;

      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      if (authState.user == null) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding',  builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',      builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/dashboard',   builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/create',      builder: (_, __) => const CreateCardScreen()),
      GoRoute(
        path: '/card/:digipin',
        builder: (_, state) => CardDetailScreen(
          digipin: state.pathParameters['digipin']!,
        ),
      ),
    ],
  );
});
