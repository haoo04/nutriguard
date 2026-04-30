import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/blockchain_provider.dart';
import 'screens/auth/enhanced_login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/suppliers/supplier_list_screen.dart';
import 'screens/suppliers/create_supplier_screen.dart';
import 'screens/suppliers/supplier_detail_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/products/create_product_screen.dart';
import 'screens/ingredients/ingredient_list_screen.dart';
import 'screens/ingredients/ingredient_detail_screen.dart';
import 'screens/ingredients/create_ingredient_screen.dart';
import 'screens/quality/quality_control_screen.dart';
import 'screens/feedback/feedback_list_screen.dart';
import 'screens/alerts/my_alerts_screen.dart';
import 'screens/qr/qr_scanner_screen.dart';
import 'screens/qr/qr_generator_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const NutriGuardApp());
}

class NutriGuardApp extends StatefulWidget {
  const NutriGuardApp({super.key});

  @override
  State<NutriGuardApp> createState() => _NutriGuardAppState();
}

class _NutriGuardAppState extends State<NutriGuardApp> {
  late final AuthProvider _authProvider;
  late final BlockchainProvider _blockchainProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _blockchainProvider = BlockchainProvider();
    _router = _buildRouter(_authProvider);

    // 触发一次区块链服务初始化；失败由 Provider 自行暴露 error。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authProvider.initialize();
    });
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _blockchainProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<BlockchainProvider>.value(value: _blockchainProvider),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Green theme for food safety
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoggingIn) {
          return '/login';
        }
        if (isLoggedIn && isLoggingIn) {
          return '/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const EnhancedLoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) => const SupplierListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateSupplierScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final supplierId = state.pathParameters['id']!;
                return SupplierDetailScreen(supplierId: supplierId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateProductScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final productId = state.pathParameters['id']!;
                return ProductDetailScreen(productId: productId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/ingredients',
          builder: (context, state) => const IngredientListScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) => const CreateIngredientScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final ingredientId = state.pathParameters['id']!;
                return IngredientDetailScreen(ingredientId: ingredientId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) => const QRScannerScreen(),
        ),
        GoRoute(
          path: '/qr-generator',
          builder: (context, state) {
            final productId = state.uri.queryParameters['productId'];
            return QRGeneratorScreen(productId: productId);
          },
        ),
        GoRoute(
          path: '/quality-control',
          builder: (context, state) => const QualityControlScreen(),
        ),
        GoRoute(
          path: '/feedback',
          builder: (context, state) => const FeedbackListScreen(),
        ),
        GoRoute(
          path: '/my-alerts',
          builder: (context, state) => const MyAlertsScreen(),
        ),
        GoRoute(
          path: '/my-feedback',
          builder: (context, state) => const FeedbackListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );
  }
}
