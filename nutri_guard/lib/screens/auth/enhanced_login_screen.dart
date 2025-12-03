import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_config.dart';
import '../../models/wallet_model.dart' as wallet;

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> {
  wallet.UserRole _selectedRole = wallet.UserRole.consumer;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showCredentialFields = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF4CAF50),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 48),
                  _buildWelcomeText(),
                  const SizedBox(height: 32),
                  _buildLoginCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.eco,
        size: 64,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          AppConfig.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Blockchain food traceability system',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoleSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    final authProvider = context.watch<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your role',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRoleSelector(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: authProvider.isLoading ? null : _connectWithPresetAccount,
            icon: authProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.login),
            label: const Text('Connect Wallet'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (authProvider.error != null) ...[
          const SizedBox(height: 16),
          Text(
            authProvider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ]
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      children: [
        SegmentedButton<wallet.UserRole>(
          segments: const <ButtonSegment<wallet.UserRole>>[
            ButtonSegment(value: wallet.UserRole.consumer, label: Text('Consumer'), icon: Icon(Icons.person)),
            ButtonSegment(value: wallet.UserRole.merchant, label: Text('Merchant'), icon: Icon(Icons.business)),
          ],
          selected: <wallet.UserRole>{_selectedRole},
          onSelectionChanged: (Set<wallet.UserRole> newSelection) {
            setState(() {
              _selectedRole = newSelection.first;
              _showCredentialFields = _selectedRole == wallet.UserRole.merchant;
              // 清空输入字段
              _usernameController.clear();
              _passwordController.clear();
            });
          },
        ),
        if (_showCredentialFields) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Enter your username',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _connectWithPresetAccount() async {
    final authProvider = context.read<AuthProvider>();
    
    // 如果是商家角色，验证用户名和密码
    if (_selectedRole == wallet.UserRole.merchant) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();
      
      if (username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter username and password'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // 验证商家凭据
      if (username != 'admin' || password != '123456') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username or password is incorrect'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    try {
      await authProvider.loginWithPresetAccount(_selectedRole);
      
      if (authProvider.isAuthenticated && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      // Error is already handled by the provider and displayed in the UI
      print('UI: Preset account connection failed - $e');
    }
  }
}
