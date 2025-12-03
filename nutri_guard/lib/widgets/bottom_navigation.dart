import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isMerchant = authProvider.currentUser?.role == UserRole.merchant;
        
        return BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          onTap: (index) => _onTap(context, index, isMerchant),
          items: _getNavigationItems(isMerchant),
        );
      },
    );
  }

  List<BottomNavigationBarItem> _getNavigationItems(bool isMerchant) {
    if (isMerchant) {
      // Merchant navigation items
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
      // Consumer navigation items
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
    if (isMerchant) {
      // Merchant navigation
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/ingredients');
          break;
        case 2:
          context.go('/products');
          break;
        case 3:
          context.go('/qr-scanner');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    } else {
      // Consumer navigation
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/qr-scanner');
          break;
        case 2:
          context.go('/my-alerts');
          break;
        case 3:
          context.go('/my-feedback');
          break;
        case 4:
          context.go('/profile');
          break;
      }
    }
  }
}



