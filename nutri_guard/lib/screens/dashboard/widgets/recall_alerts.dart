import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/product_model.dart';

class RecallAlerts extends StatelessWidget {
  final List<RecallNotification> notifications;
  final Function(RecallNotification) onNotificationTap;

  const RecallAlerts({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recall Alerts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${notifications.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notifications.take(3).map((notification) => 
                _buildNotificationItem(context, notification)),
            if (notifications.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed: () => _showAllNotifications(context),
                    child: Text('View all ${notifications.length} notifications'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, RecallNotification notification) {
    final dateFormat = DateFormat('MM/dd HH:mm');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onNotificationTap(notification),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: notification.isRead ? Colors.grey[300]! : Colors.red[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getSeverityColor(notification.severity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product #${notification.productId} Recalled',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead 
                            ? FontWeight.normal 
                            : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateFormat.format(notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(notification.severity).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notification.severity.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(notification.severity),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSeverityColor(RecallSeverity severity) {
    switch (severity) {
      case RecallSeverity.low:
        return Colors.green;
      case RecallSeverity.medium:
        return Colors.orange;
      case RecallSeverity.high:
        return Colors.red;
      case RecallSeverity.critical:
        return Colors.purple;
    }
  }

  void _showAllNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Recall Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(context, notification);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // 标记所有通知为已读
              for (final notification in notifications) {
                if (!notification.isRead) {
                  onNotificationTap(notification);
                }
              }
              Navigator.of(context).pop();
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
    );
  }
}



