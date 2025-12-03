import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/product_model.dart';
import '../../models/ingredient_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final blockchainProvider = context.read<BlockchainProvider>();
    try {
      // 直接通过blockchain service获取产品信息
      final productData = await blockchainProvider.blockchainService
          .getProductWithDetails(int.parse(widget.productId));
      setState(() {
        product = productData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Load product failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Detail'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product!.displayName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildBasicInfo(),
            const SizedBox(height: 16),
            _buildIngredientsSection(),
            const SizedBox(height: 16),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isValid = product!.isValid && !product!.hasRecalledIngredients;
    
    return Card(
      color: isValid ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isValid ? Icons.verified : Icons.warning,
              color: isValid ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isValid ? 'Product safe' : 'Product abnormal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isValid ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    isValid 
                        ? 'All ingredients passed quality test'
                        : product!.hasRecalledIngredients 
                            ? 'Contains recalled ingredients'
                            : 'Quality test failed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Product ID', product!.id),
            _buildInfoRow('Merchant', _formatAddress(product!.merchantAddress)),
            _buildInfoRow('Created at', product!.createdAt.toString().split('.')[0]),
            _buildInfoRow('QR code hash', _formatHash(product!.qrCodeHash)),
            _buildInfoRow('IPFS hash', _formatHash(product!.ipfsHash)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatHash(String hash) {
    if (hash.isEmpty) return 'Not set';
    if (hash.length <= 10) return hash;
    return '${hash.substring(0, 10)}...';
  }

  Widget _buildIngredientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contains ingredients',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...product!.ingredientIds.map((ingredientId) => 
                _buildIngredientItem(ingredientId)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(String ingredientId) {
    return FutureBuilder<IngredientModel>(
      future: context.read<BlockchainProvider>().blockchainService
          .getIngredientWithSupplier(int.parse(ingredientId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Loading ingredient...'),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load ingredient #$ingredientId',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ),
              ],
            ),
          );
        }

        final ingredient = snapshot.data!;
        final isContaminated = ingredient.isRecalled || ingredient.isContaminated;
        final statusColor = isContaminated ? Colors.red : 
                          ingredient.isExpired ? Colors.orange : Colors.green;

        return GestureDetector(
          onTap: () => _navigateToIngredientDetail(ingredientId),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  isContaminated ? Icons.warning : 
                  ingredient.isExpired ? Icons.schedule : Icons.inventory_2,
                  size: 20,
                  color: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredient.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor.shade700,
                        ),
                      ),
                      Text(
                        isContaminated ? 'Contaminated/Recalled' :
                        ingredient.isExpired ? 'Expired' : 'Safe',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (ingredient.category != null)
                        Text(
                          ingredient.category!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios, 
                  size: 16,
                  color: statusColor.shade600,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToIngredientDetail(String ingredientId) {
    context.push('/ingredients/$ingredientId');
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _verifyProduct(),
                icon: const Icon(Icons.verified_user),
                label: const Text('Verify product'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyProduct() async {
    final blockchainProvider = context.read<BlockchainProvider>();
    
    try {
      final isValid = await blockchainProvider.verifyProduct(int.parse(widget.productId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValid ? 'Product verification passed' : 'Product verification failed'),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

}




