import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_navigation.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/recent_activities.dart';
import 'widgets/quality_monitor.dart';
import 'widgets/recall_alerts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlockchainProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BlockchainProvider>(
      builder: (context, authProvider, blockchainProvider, _) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: _buildAppBar(user),
          body: RefreshIndicator(
            onRefresh: () => _refreshData(blockchainProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120), // 增加更多底部填充以避免overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(user),
                  const SizedBox(height: 24),
                  if (blockchainProvider.getUnreadNotifications().isNotEmpty)
                    RecallAlerts(
                      notifications: blockchainProvider.getUnreadNotifications(),
                      onNotificationTap: (notification) {
                        blockchainProvider.markNotificationAsRead(notification.id);
                      },
                    ),
                  const SizedBox(height: 16),
                  DashboardStats(
                    userRole: user.role,
                    ingredients: blockchainProvider.getUserIngredients(user.walletAddress),
                    products: blockchainProvider.getUserProducts(user.walletAddress, user.role),
                  ),
                  const SizedBox(height: 24),
                  if (user.isMerchant)
                    QualityMonitor(
                      ingredients: blockchainProvider.getUserIngredients(user.walletAddress),
                    ),
                  const SizedBox(height: 24),
                  RecentActivities(
                    userRole: user.role,
                    ingredients: blockchainProvider.getUserIngredients(user.walletAddress),
                    products: blockchainProvider.getUserProducts(user.walletAddress, user.role),
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(user),
                  const SizedBox(height: 24), // 添加额外的底部间距
                ],
              ),
            ),
          ),
          bottomNavigationBar: const BottomNavigation(currentIndex: 0),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel user) {
    return AppBar(
      title: Text('Welcome, ${user.displayName ?? 'User'}'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      actions: [
        Consumer<BlockchainProvider>(
          builder: (context, blockchainProvider, _) {
            final unreadCount = blockchainProvider.getUnreadNotifications().length;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _showNotificationsDialog(context, blockchainProvider),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => context.go('/profile'),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your role: ${user.roleDisplayName}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wallet Address: ${user.walletAddress.substring(0, 6)}...${user.walletAddress.substring(user.walletAddress.length - 4)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(UserModel user) {
    final actions = <Map<String, dynamic>>[];

    if (user.isMerchant) {
      actions.addAll([
        {
          'title': 'Manage Suppliers',
          'icon': Icons.business,
          'color': Colors.indigo,
          'route': '/suppliers',
        },
        {
          'title': 'Register Ingredient',
          'icon': Icons.add_circle,
          'color': Colors.green,
          'route': '/ingredients/create',
        },
        {
          'title': 'Create Product',
          'icon': Icons.inventory,
          'color': Colors.blue,
          'route': '/products/create',
        },
        {
          'title': 'Quality Control',
          'icon': Icons.science,
          'color': Colors.orange,
          'route': '/quality-control',
        },
        {
          'title': 'Generate QR Code',
          'icon': Icons.qr_code,
          'color': Colors.purple,
          'route': '/qr-generator',
        },
        {
          'title': 'View Feedback',
          'icon': Icons.feedback,
          'color': Colors.teal,
          'route': '/feedback',
        },
        //{
        //  'title': 'Debug Status',
        //  'icon': Icons.bug_report,
        //  'color': Colors.red,
        //  'action': () => _showDebugStatus(context),
        //},
      ]);
    }

    if (user.isConsumer) {
      actions.addAll([
        {
          'title': 'Scan QR Code',
          'icon': Icons.qr_code_scanner,
          'color': Colors.orange,
          'route': '/qr-scanner',
        },
        {
          'title': 'View Products',
          'icon': Icons.search,
          'color': Colors.teal,
          'route': '/products',
        },
        {
          'title': 'My Alerts',
          'icon': Icons.notifications_active,
          'color': Colors.red,
          'route': '/my-alerts',
        },
        {
          'title': 'My Feedback',
          'icon': Icons.rate_review,
          'color': Colors.blue,
          'route': '/my-feedback',
        },
      ]);
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3, // 减少比例以给卡片更多垂直空间
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (action['action'] != null) {
            action['action']();
          } else if (action['route'] != null) {
            context.go(action['route']);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12), // 减少内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action['icon'],
                size: 28, // 减少图标大小
                color: action['color'],
              ),
              const SizedBox(height: 6), // 减少间距
              Text(
                action['title'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith( // 使用更小的字体
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // 限制最大行数
                overflow: TextOverflow.ellipsis, // 添加省略号处理
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData(BlockchainProvider blockchainProvider) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      await blockchainProvider.refreshAllData(user.role);
    }
  }

  void _showNotificationsDialog(BuildContext context, BlockchainProvider blockchainProvider) {
    final notifications = blockchainProvider.recallNotifications;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: notifications.isEmpty
              ? const Text('No notifications')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: notification.isRead ? Colors.grey : Colors.red,
                      ),
                      title: Text(
                        'Product #${notification.productId} Recalled',
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(notification.reason),
                      trailing: Text(
                        '${notification.timestamp.month}/${notification.timestamp.day}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      onTap: () {
                        blockchainProvider.markNotificationAsRead(notification.id);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /*Future<void> _showDebugStatus(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final blockchainProvider = context.read<BlockchainProvider>();
    
    final user = authProvider.currentUser;
    final userAddress = blockchainProvider.blockchainService.userAddress;
    
    String debugInfo = '🔧 Debug Information:\n\n';
    debugInfo += '📱 App User Info:\n';
    debugInfo += '  - Address: ${user?.walletAddress ?? "None"}\n';
    debugInfo += '  - Role: ${user?.role.name ?? "None"}\n';
    debugInfo += '  - Display Name: ${user?.displayName ?? "None"}\n\n';
    
    debugInfo += '⛓️ Blockchain Service Info:\n';
    debugInfo += '  - User Address: ${userAddress?.hex ?? "None"}\n';
    
    if (userAddress != null) {
      try {
        final isRegistered = await blockchainProvider.blockchainService.isUserRegistered(userAddress.hex);
        debugInfo += '  - Is Registered: $isRegistered\n';
        
        if (isRegistered) {
          final userRole = await blockchainProvider.blockchainService.getUserRole(userAddress.hex);
          debugInfo += '  - Blockchain Role: ${userRole.name}\n';
        }
      } catch (e) {
        debugInfo += '  - Error checking status: $e\n';
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Status'),
        content: SingleChildScrollView(
          child: Text(
            debugInfo,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Force re-register user
              if (user != null && userAddress != null) {
                try {
                  final role = user.role == UserRole.merchant ? UserRole.merchant : UserRole.consumer;
                  await blockchainProvider.blockchainService.registerUser(role);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User re-registration attempted')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Re-registration failed: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Re-register'),
          ),
        ],
      ),
    );
  }*/
}



