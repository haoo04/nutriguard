import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/user_model.dart';
import '../../../models/ingredient_model.dart';
import '../../../models/product_model.dart';

class RecentActivities extends StatelessWidget {
  final UserRole userRole;
  final List<IngredientModel> ingredients;
  final List<ProductModel> products;

  const RecentActivities({
    super.key,
    required this.userRole,
    required this.ingredients,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final activities = _buildActivitiesList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: activities.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No recent activities'),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 5 ? 5 : activities.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    return activities[index];
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildActivitiesList() {
    final activities = <ActivityItem>[];

    if (userRole == UserRole.consumer) {
      // 消费者活动：产品注册
      for (final product in products) {
        activities.add(ActivityItem(
          title: 'Registered Product: ${product.displayName}',
          subtitle: 'Product ID: ${product.id} • ${product.status.displayName}',
          timestamp: product.createdAt, // 在实际应用中应该是注册时间
          icon: Icons.verified_user,
          color: product.isValid ? Colors.green : Colors.orange,
        ));
      }
    } else {
      // 商家活动：原料相关活动
      for (final ingredient in ingredients) {
        activities.add(ActivityItem(
          title: 'Register Ingredient: ${ingredient.name}',
          subtitle: 'Ingredient ID: ${ingredient.id}',
          timestamp: ingredient.createdAt,
          icon: Icons.add_circle,
          color: Colors.green,
        ));

        // 添加原料状态记录
        if (ingredient.isExpired) {
          activities.add(ActivityItem(
            title: '原料过期: ${ingredient.name}',
            subtitle: '保质期: ${ingredient.expiryDate.toString().split(' ')[0]}',
            timestamp: ingredient.expiryDate,
            icon: Icons.schedule,
            color: Colors.orange,
          ));
        }

        // 添加召回记录
        if (ingredient.isRecalled) {
          activities.add(ActivityItem(
            title: 'Ingredient Recall: ${ingredient.name}',
            subtitle: 'Ingredient has been recalled',
            timestamp: ingredient.createdAt, // 实际应用中应该有召回时间
            icon: Icons.warning,
            color: Colors.red,
          ));
        }
      }
      
      // 商家的产品相关活动
      for (final product in products) {
        activities.add(ActivityItem(
          title: 'Create Product: ${product.displayName}',
          subtitle: 'Product ID: ${product.id}',
          timestamp: product.createdAt,
          icon: Icons.inventory,
          color: Colors.blue,
        ));
      }
    }

    // 按时间排序
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities.map((activity) => _buildActivityTile(activity)).toList();
  }

  Widget _buildActivityTile(ActivityItem activity) {
    final dateFormat = DateFormat('MM/dd HH:mm');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity.color.withOpacity(0.1),
        child: Icon(
          activity.icon,
          color: activity.color,
          size: 20,
        ),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(activity.subtitle),
      trailing: Text(
        dateFormat.format(activity.timestamp),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}

class ActivityItem {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}



