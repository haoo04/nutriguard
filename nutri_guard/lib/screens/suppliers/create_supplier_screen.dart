import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/blockchain_provider.dart';
import '../../providers/auth_provider.dart';

class CreateSupplierScreen extends StatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  State<CreateSupplierScreen> createState() => _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends State<CreateSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _certificationsController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactInfoController.dispose();
    _certificationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Supplier'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildContactSection(),
              const SizedBox(height: 24),
              _buildCertificationSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
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
          Icon(
            Icons.business,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Register New Supplier',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add supplier information to enable ingredient sourcing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name *',
                hintText: 'Enter supplier company name',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Supplier name is required';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactInfoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Contact Information *',
                hintText: 'Enter phone, email, address, etc.',
                prefixIcon: Icon(Icons.contact_mail),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Contact information is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Certifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Optional certifications (e.g., Organic, Halal, ISO)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _certificationsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Certifications',
                hintText: 'Enter certifications separated by commas',
                prefixIcon: Icon(Icons.assignment_turned_in),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerSupplier,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Register Supplier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _registerSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔧 CreateSupplierScreen: 开始注册供应商');
    print('🔧 CreateSupplierScreen: 供应商名称: ${_nameController.text.trim()}');

    setState(() => _isLoading = true);

    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      final authProvider = context.read<AuthProvider>();
      
      print('🔧 CreateSupplierScreen: 当前用户: ${authProvider.currentUser?.walletAddress}');
      print('🔧 CreateSupplierScreen: 用户角色: ${authProvider.currentUser?.role}');
      
      // Check blockchain service user address
      final userAddress = blockchainProvider.blockchainService.userAddress;
      print('🔧 CreateSupplierScreen: 区块链服务用户地址: $userAddress');
      
      // Check if user is registered on blockchain
      if (userAddress != null) {
        try {
          final isRegistered = await blockchainProvider.blockchainService.isUserRegistered(userAddress.hex);
          print('🔧 CreateSupplierScreen: 区块链用户已注册: $isRegistered');
          
          if (isRegistered) {
            final userRole = await blockchainProvider.blockchainService.getUserRole(userAddress.hex);
            print('🔧 CreateSupplierScreen: 区块链用户角色: ${userRole.name}');
          }
        } catch (e) {
          print('🔧 CreateSupplierScreen: 检查用户状态失败: $e');
        }
      }
      
      print('🔧 CreateSupplierScreen: 调用 registerSupplier');
      await blockchainProvider.blockchainService.registerSupplier(
        name: _nameController.text.trim(),
        contactInfo: _contactInfoController.text.trim(),
        certifications: _certificationsController.text.trim(),
      );

      print('🔧 CreateSupplierScreen: 供应商注册成功');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/suppliers');
      }
    } catch (e) {
      print('🔧 CreateSupplierScreen: 供应商注册失败: $e');
      print('🔧 CreateSupplierScreen: 错误类型: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register supplier: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
