import 'package:flutter/material.dart';
import '../../../models/ingredient_model.dart';

class QualityMonitor extends StatelessWidget {
  final List<IngredientModel> ingredients;

  const QualityMonitor({
    super.key,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Monitoring',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQualityOverview(context),
                const SizedBox(height: 16),
                _buildQualityChart(context),
                const SizedBox(height: 16),
                _buildAlertsList(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityOverview(BuildContext context) {
    final totalIngredients = ingredients.length;
    final passedIngredients = ingredients.where((i) => i.isValid).length;
    final failedIngredients = totalIngredients - passedIngredients;
    final recalledIngredients = ingredients.where((i) => i.isRecalled).length;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            context,
            title: 'Passed',
            value: passedIngredients,
            total: totalIngredients,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            context,
            title: 'Failed',
            value: failedIngredients,
            total: totalIngredients,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOverviewCard(
            context,
            title: 'Recalled',
            value: recalledIngredients,
            total: totalIngredients,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required String title,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityChart(BuildContext context) {
    // 显示原料状态分布图表
    final validIngredients = ingredients.where((i) => i.isValid).length;
    final expiredIngredients = ingredients.where((i) => i.isExpired).length;
    final recalledIngredients = ingredients.where((i) => i.isRecalled).length;
    
    if (ingredients.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No ingredient data',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      //height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildStatusBar('valid', validIngredients, Colors.green),
          _buildStatusBar('Expired', expiredIngredients, Colors.orange),
          _buildStatusBar('recalled', recalledIngredients, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, Color color) {
    final maxHeight = 60.0;
    final total = ingredients.length;
    final height = total > 0 ? (count / total) * maxHeight : 0.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: height.clamp(5.0, maxHeight),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildAlertsList(BuildContext context) {
    final alerts = <Widget>[];
    
    // 检查原料状态异常
    for (final ingredient in ingredients) {
      if (ingredient.isExpired) {
        alerts.add(_buildAlertItem(
          context,
          title: '${ingredient.name} expired alert',
          description: 'expired: ${ingredient.expiryDate.toString().split(' ')[0]}',
          severity: AlertSeverity.warning,
        ));
      } else if (ingredient.isRecalled) {
        alerts.add(_buildAlertItem(
          context,
          title: '${ingredient.name} recall alert',
          description: 'This ingredient has been recalled',
          severity: AlertSeverity.critical,
        ));
      }
    }

    // 检查召回原料
    for (final ingredient in ingredients.where((i) => i.isRecalled)) {
      alerts.add(_buildAlertItem(
        context,
        title: '${ingredient.name} Recalled',
        description: 'Please stop using',
        severity: AlertSeverity.critical,
      ));
    }

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text('No quality alerts'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quality Alerts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...alerts.take(3), // Only show the first 3 alerts
      ],
    );
  }

  Widget _buildAlertItem(
    BuildContext context, {
    required String title,
    required String description,
    required AlertSeverity severity,
  }) {
    Color color;
    IconData icon;
    
    switch (severity) {
      case AlertSeverity.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case AlertSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum AlertSeverity { info, warning, critical }



