import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class BottomNavigation extends StatelessWidget {
  /// 已废弃：高亮位以当前路由为准，保留仅为兼容旧调用点，不再生效。
  @Deprecated('currentIndex 已按当前路由自动识别，传入值会被忽略。')
  final int? currentIndex;

  const BottomNavigation({
    super.key,
    @Deprecated('currentIndex 已按当前路由自动识别，传入值会被忽略。')
    this.currentIndex,
  });

  // 路由 -> tab index 的映射，保持与 _onTap 一致。
  static const _merchantRoutes = <String>[
    '/dashboard',
    '/ingredients',
    '/products',
    '/qr-scanner',
    '/profile',
  ];

  static const _consumerRoutes = <String>[
    '/dashboard',
    '/qr-scanner',
    '/my-alerts',
    '/my-feedback',
    '/profile',
  ];

  int _deriveIndex(BuildContext context, bool isMerchant) {
    final location = GoRouterState.of(context).matchedLocation;
    final routes = isMerchant ? _merchantRoutes : _consumerRoutes;

    // 使用 startsWith，让 /products/123 这类子路由仍能高亮到 /products 所在 tab。
    // 同时排除 '/dashboard' 的前缀冲突——这里所有根路由都不是彼此前缀，不会有歧义。
    for (var i = 0; i < routes.length; i++) {
      if (location == routes[i] || location.startsWith('${routes[i]}/')) {
        return i;
      }
    }
    return -1; // 非 tab 页：不选中任何 item
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isMerchant = authProvider.currentUser?.role == UserRole.merchant;
        final items = _getNavigationItems(isMerchant);
        final derived = _deriveIndex(context, isMerchant);

        // BottomNavigationBar 的 currentIndex 必须在 [0, items.length) 范围内；
        // 超出范围时传 0 并靠 selectedItemColor == unselectedItemColor 来“去高亮”。
        final safeIndex = (derived >= 0 && derived < items.length) ? derived : 0;
        final hasActiveTab = derived >= 0 && derived < items.length;

        final selectedColor = hasActiveTab
            ? Theme.of(context).colorScheme.primary
            : Colors.grey;

        return BottomNavigationBar(
          currentIndex: safeIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: Colors.grey,
          onTap: (index) => _onTap(context, index, isMerchant),
          items: items,
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getNavigationItems(bool isMerchant) {
    if (isMerchant) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Ingredients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.feedback),
          label: 'Feedback',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  void _onTap(BuildContext context, int index, bool isMerchant) {
    final routes = isMerchant ? _merchantRoutes : _consumerRoutes;
    if (index < 0 || index >= routes.length) return;
    context.go(routes[index]);
  }
}
