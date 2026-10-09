import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: DigiRoutesApp(),
    ),
  );
}

class DigiRoutesApp extends ConsumerStatefulWidget {
  const DigiRoutesApp({super.key});

  @override
  ConsumerState<DigiRoutesApp> createState() => _DigiRoutesAppState();
}

class _DigiRoutesAppState extends ConsumerState<DigiRoutesApp> {
  @override
  void initState() {
    super.initState();
    _setUpShortcuts();
  }

  /// Launcher shortcuts (long-press the app icon): quick-add and scan.
  void _setUpShortcuts() {
    const quickActions = QuickActions();
    quickActions.initialize(_runShortcut);
    quickActions.setShortcutItems(const [
      ShortcutItem(type: 'new_card', localizedTitle: 'New card here'),
      ShortcutItem(type: 'scan_qr', localizedTitle: 'Scan QR'),
    ]);
  }

  Future<void> _runShortcut(String type) async {
    final router = ref.read(routerProvider);
    // On a cold start wait for the splash screen to hand over to the app.
    for (var i = 0; i < 30; i++) {
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (path != '/splash' && path != '/') break;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    switch (type) {
      case 'new_card':
        router.push('/create'); // auto-locates; login redirect if signed out
      case 'scan_qr':
        router.go('/scan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DigiRoutes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));
        return child!;
      },
    );
  }
}
