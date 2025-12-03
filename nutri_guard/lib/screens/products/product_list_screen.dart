import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../widgets/bottom_navigation.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<BlockchainProvider>().refreshAllData(user.role);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final user = authProvider.currentUser;
            return Text(user?.isMerchant == true ? 'Product management' : 'My Products');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.currentUser?.isMerchant == true) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context.go('/products/create'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, BlockchainProvider>(
        builder: (context, authProvider, blockchainProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = blockchainProvider.getUserProducts(user.walletAddress, user.role);

          if (blockchainProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_basket_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.isMerchant ? 'No product' : 'No registered products',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.isMerchant 
                        ? 'Click the + button in the top right corner to add product' 
                        : 'Scan product QR codes to register them to your account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => blockchainProvider.refreshAllData(user.role),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 增加底部填充以避免与底部导航栏重叠
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: product.isValid 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        product.isValid ? Icons.verified : Icons.warning,
                        color: product.isValid ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      product.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product ID: ${product.id}'),
                        Text('Ingredient quantity: ${product.ingredientIds.length}'),
                        Text('Created at: ${product.createdAt.toString().split(' ')[0]}'),
                      ],
                    ),
                    trailing: product.hasRecalledIngredients
                        ? const Icon(Icons.warning, color: Colors.red)
                        : const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => context.go('/products/${product.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 2),
    );
  }
}

