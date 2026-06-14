import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zqwis/back/api/dio_client.dart';
import 'package:zqwis/main/helper/app_theme.dart';
import 'package:zqwis/main/helper/switchmode_provider.dart';
import 'package:zqwis/main/helper/auth_provider.dart';
import 'main/login/login_page.dart';
import 'main/home/home_page.dart';
import 'main/docs/docs_page.dart';
import 'main/profile/profile_page.dart';
import 'main/admin/admin_page.dart';
import 'main/owner/owner_page.dart';
import 'main/missions/missions_page.dart';
import 'main/helper/sidemenu_wrapper.dart'; 
import 'main/splash/splash_screen.dart';
import 'main/whatsapp/whatsapp_page.dart';
import 'main/store/store_page.dart';

//==================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent, 
    systemNavigationBarDividerColor: Colors.transparent, 
    statusBarColor: Colors.transparent, 
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark, 
  ));
  await DioClient.instance.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkSession()),
        ChangeNotifierProvider(create: (_) => SwitchmodeProvider()),
      ],
      child: const ZqwisApp(),
    ),
  );
}

//==================
class ZqwisApp extends StatelessWidget {
  const ZqwisApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<SwitchmodeProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent, 
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false, 
      ),
      child: MaterialApp.router(
        title: 'Zqwis Panel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        routerConfig: _buildRouter(context),
      ),
    );
  }
}

//==================
GoRouter _buildRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/splash', 
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(), 
      ),
      GoRoute(
        path: '/',
        name: 'login',
        builder: (ctx, state) => const _AuthGuard(
          authRequired: false,
          child: LoginPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return SidemenuWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: HomePage()),
          ),
          GoRoute(
            path: '/docsmenu',
            name: 'docsmenu',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: ApiListPage()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: ProfilePage()),
          ),
          GoRoute(
            path: '/store',
            name: 'store',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: StorePage()),
          ),
          GoRoute(
            path: '/missions',
            name: 'missions',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: MissionsPage()),
          ),
          GoRoute(
            path: '/whatsapp',
            name: 'whatsapp',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, child: WhatsAppPairingPage()),
          ),
          GoRoute(
            path: '/adminmenu',
            name: 'adminmenu',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, requireAdmin: true, child: AdminPage()),
          ),
          GoRoute(
            path: '/ownermenu',
            name: 'ownermenu',
            builder: (ctx, state) => const _AuthGuard(authRequired: true, requireOwner: true, child: OwnerPage()),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('404 — Page Not Found', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => ctx.go('/'), child: const Text('Go Home')),
          ],
        ),
      ),
    ),
  );
}

//==================
class _AuthGuard extends StatelessWidget {
  final Widget child;
  final bool authRequired;
  final bool requireAdmin;
  final bool requireOwner;
  const _AuthGuard({
    required this.child, 
    this.authRequired = false, 
    this.requireAdmin = false, 
    this.requireOwner = false
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.unknown) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!authRequired && auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/home'));
      return const SizedBox.shrink();
    }
    if (authRequired && !auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }
    if (requireOwner && auth.user?.role != 'owner') {
      return const _AccessDenied(message: 'Owner access required.');
    }
    if (requireAdmin && auth.user?.role != 'admin' && auth.user?.role != 'owner') {
      return const _AccessDenied(message: 'Admin access required.');
    }
    return child;
  }
}

//==================
class _AccessDenied extends StatelessWidget {
  final String message;
  const _AccessDenied({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
