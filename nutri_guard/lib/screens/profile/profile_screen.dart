import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_navigation.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 增加底部填充以避免与底部导航栏重叠
            child: Column(
              children: [
                _buildUserCard(context, user),
                const SizedBox(height: 24),
                _buildEmailSection(context, user, authProvider),
                const SizedBox(height: 24),
                _buildSettingsSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(context, authProvider),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return const BottomNavigation(currentIndex: 4); // Profile is always index 4 for both roles
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? 'User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.roleDisplayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${user.walletAddress.substring(0, 6)}...${user.walletAddress.substring(user.walletAddress.length - 4)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (user.isVerified)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection(BuildContext context, UserModel user, AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.email,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Set your email address to receive recall notifications and important updates.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: user.email != null && user.email!.isNotEmpty 
                    ? Colors.green[50] 
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: user.email != null && user.email!.isNotEmpty 
                      ? Colors.green[200]! 
                      : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user.email != null && user.email!.isNotEmpty 
                        ? Icons.check_circle 
                        : Icons.warning,
                    color: user.email != null && user.email!.isNotEmpty 
                        ? Colors.green[700] 
                        : Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email != null && user.email!.isNotEmpty 
                              ? 'Email Configured' 
                              : 'No Email Set',
                          style: TextStyle(
                            color: user.email != null && user.email!.isNotEmpty 
                                ? Colors.green[700] 
                                : Colors.orange[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.email != null && user.email!.isNotEmpty 
                              ? user.email! 
                              : 'Set your email to receive notifications',
                          style: TextStyle(
                            color: user.email != null && user.email!.isNotEmpty 
                                ? Colors.green[600] 
                                : Colors.orange[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showEmailDialog(context, user, authProvider),
                icon: Icon(
                  user.email != null && user.email!.isNotEmpty 
                      ? Icons.edit 
                      : Icons.add,
                ),
                label: Text(
                  user.email != null && user.email!.isNotEmpty 
                      ? 'Update Email' 
                      : 'Set Email',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Application settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 导航到设置页面
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help and support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 导航到帮助页面
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About the application'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: authProvider.isLoading 
            ? null 
            : () => _logout(context, authProvider),
        icon: authProvider.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout),
        label: Text(authProvider.isLoading ? 'Logging out...' : 'Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _showEmailDialog(BuildContext context, UserModel user, AuthProvider authProvider) {
    final emailController = TextEditingController(text: user.email ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email, color: Colors.blue),
            SizedBox(width: 8),
            Text('Set Email Address'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your email address to receive notifications about product recalls and safety alerts.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your email will be used for important notifications only and will not be shared with third parties.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateEmail(context, emailController.text.trim(), authProvider),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEmail(BuildContext context, String email, AuthProvider authProvider) async {
    // 先在 pop 前抓住 Messenger / Navigator，避免 dialog 关闭后使用失效 context。
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Email validation
    if (email.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    navigator.pop(); // Close dialog

    try {
      await authProvider.updateUserEmail(email.isEmpty ? null : email);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            email.isEmpty
                ? 'Email removed successfully'
                : 'Email updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'NutriGuard',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.eco, size: 32),
      children: [
        const Text('Food tracing and recall system based on blockchain'),
        const SizedBox(height: 8),
        const Text('Ensure food safety, achieve rapid recall'),
      ],
    );
  }
}




