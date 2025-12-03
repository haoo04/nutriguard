import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/ingredient_model.dart';
import '../../../models/product_model.dart';

class DashboardStats extends StatelessWidget {
  final UserRole userRole;
  final List<IngredientModel> ingredients;
  final List<ProductModel> products;

  const DashboardStats({
    super.key,
    required this.userRole,
    required this.ingredients,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1, // 减少比例以给卡片更多垂直空间
          children: _buildStatCards(context),
        ),
      ],
    );
  }

  List<Widget> _buildStatCards(BuildContext context) {
    final cards = <Widget>[];

    if (userRole == UserRole.merchant) {
      cards.addAll([
        _buildStatCard(
          context,
          title: 'Ingredients',
          value: ingredients.length.toString(),
          icon: Icons.inventory_2,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Products',
          value: products.length.toString(),
          icon: Icons.shopping_basket,
          color: Colors.blue,
        ),
        _buildStatCard(
          context,
          title: 'Pass Rate',
          value: '${_getQualityPassRate().toStringAsFixed(1)}%',
          icon: Icons.verified,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'Recalled',
          value: _getRecalledProductsCount().toString(),
          icon: Icons.warning,
          color: Colors.red,
        ),
      ]);
    } else if (userRole == UserRole.consumer) {
      cards.addAll([
        _buildStatCard(
          context,
          title: 'Verified Products',
          value: products.length.toString(),
          icon: Icons.verified_user,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Safe Products',
          value: _getSafeProductsCount().toString(),
          icon: Icons.security,
          color: Colors.blue,
        ),
      ]);
    }

    return cards;
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12), // 减少内边距
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28, // 减少图标大小
              color: color,
            ),
            const SizedBox(height: 6), // 减少间距
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith( // 使用更小的字体
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2), // 减少间距
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith( // 使用更小的字体
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // 限制最大行数
              overflow: TextOverflow.ellipsis, // 添加省略号处理
            ),
          ],
        ),
      ),
    );
  }

  double _getQualityPassRate() {
    if (ingredients.isEmpty) return 0.0;
    
    final passedCount = ingredients.where((ingredient) => 
        ingredient.isValid).length;
    
    return (passedCount / ingredients.length) * 100;
  }

  int _getRecalledProductsCount() {
    return products.where((product) => product.hasRecalledIngredients).length;
  }

  int _getSafeProductsCount() {
    return products.where((product) => 
        product.isValid && !product.hasRecalledIngredients).length;
  }


}



