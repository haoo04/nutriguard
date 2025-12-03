import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bottom_navigation.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/product_model.dart';
import '../../models/quality_model.dart';

class QRGeneratorScreen extends StatefulWidget {
  final String? productId;

  const QRGeneratorScreen({
    super.key,
    this.productId,
  });

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _productIdController = TextEditingController();
  String? _qrData;
  ProductModel? _product;
  QualityRule? _qualityRule;
  ProductionData? _productionData;
  bool _isLoading = false;
  String? _error;
  bool _canGenerateQR = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _productIdController.text = widget.productId!;
      _checkProductEligibility();
    }
  }

  Future<void> _checkProductEligibility() async {
    final productId = _productIdController.text.trim();
    if (productId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _canGenerateQR = false;
      _qrData = null;
    });

    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      
      // 1. 获取产品信息
      final product = await blockchainProvider.blockchainService
          .getProductWithDetails(int.parse(productId));
      
      // 2. 获取质量规则
      final qualityRule = await blockchainProvider.blockchainService
          .getProductQualityRule(int.parse(productId));
      
      // 3. 尝试获取生产数据
      ProductionData? productionData;
      try {
        productionData = await blockchainProvider.blockchainService
            .getProductionData(int.parse(productId));
      } catch (e) {
        // 如果没有生产数据，productionData保持为null
      }

      setState(() {
        _product = product;
        _qualityRule = qualityRule;
        _productionData = productionData;
        _canGenerateQR = _validateQRGeneration();
        _isLoading = false;
      });

      if (_canGenerateQR) {
        _generateQRData();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load product information: $e';
        _isLoading = false;
      });
    }
  }

  bool _validateQRGeneration() {
    if (_product == null || _qualityRule == null) return false;
    
    // 检查是否已提交生产数据
    if (_productionData == null || !_productionData!.hasData) return false;
    
    // 检查生产数据是否符合质量标准
    if (!_productionData!.isCompliant) return false;
    
    // 检查产品状态
    if (_product!.status != ProductStatus.safe) return false;
    
    // 检查是否有被召回的原料
    if (_product!.hasRecalledIngredients) return false;
    
    return true;
  }

  void _generateQRData() {
    if (_canGenerateQR && _product != null) {
      setState(() {
        // 生成标准的NutriGuard QR码格式
        _qrData = 'nutriguard://product/${_product!.id}';
      });
    }
  }

  void _handleBackNavigation(BuildContext context) {
    // 检查是否可以返回上一页
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // 如果无法返回，则导航到仪表板
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
            title: const Text('Generate QR code'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBackNavigation(context),
            ),
            actions: [
              if (_qrData != null)
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareQRCode,
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // 增加底部填充以避免与底部导航栏重叠
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(),
                const SizedBox(height: 16),
                if (_error != null) _buildErrorSection(),
                if (_product != null && !_isLoading) _buildProductStatusSection(),
                if (_canGenerateQR && _qrData != null) ...[
                  const SizedBox(height: 32),
                  _buildQRCodeSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
          bottomNavigationBar: const BottomNavigation(
            currentIndex: 2, // QR功能对两种角色都是索引2
          ),
        );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductStatusSection() {
    if (_product == null) return const SizedBox.shrink();

    final hasProductionData = _productionData != null && _productionData!.hasData;
    final isCompliant = _productionData?.isCompliant ?? false;
    final hasRecalledIngredients = _product!.hasRecalledIngredients;
    final isSafeStatus = _product!.status == ProductStatus.safe;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Status Check',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'Product Information',
              true,
              'Product found: ${_product!.name}',
            ),
            _buildStatusItem(
              'Production Data Submitted',
              hasProductionData,
              hasProductionData 
                  ? 'Production data submitted at ${_productionData!.timestamp.toString().split('.')[0]}'
                  : 'Production data not submitted yet',
            ),
            if (hasProductionData)
              _buildStatusItem(
                'Quality Compliance',
                isCompliant,
                isCompliant 
                    ? 'Production data meets quality standards'
                    : 'Production data does not meet quality standards',
              ),
            _buildStatusItem(
              'Product Status',
              isSafeStatus,
              'Status: ${_product!.status.name.toUpperCase()}',
            ),
            _buildStatusItem(
              'Ingredient Safety',
              !hasRecalledIngredients,
              hasRecalledIngredients 
                  ? 'Contains recalled/contaminated ingredients'
                  : 'All ingredients are safe',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canGenerateQR ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _canGenerateQR ? Colors.green[300]! : Colors.orange[300]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _canGenerateQR ? Icons.check_circle : Icons.warning,
                    color: _canGenerateQR ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _canGenerateQR 
                          ? 'All conditions met! QR code can be generated.'
                          : 'QR code generation not allowed. Please resolve the issues above.',
                      style: TextStyle(
                        color: _canGenerateQR ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasProductionData) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToProductionData(),
                  icon: const Icon(Icons.science),
                  label: const Text('Submit Production Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, bool isSuccess, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: isSuccess ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProductionData() {
    context.push('/quality-control').then((_) {
      // 返回时重新检查产品状态
      _checkProductEligibility();
    });
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _productIdController,
              decoration: const InputDecoration(
                labelText: 'Product ID',
                hintText: 'Enter product ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkProductEligibility,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'Checking...' : 'Check Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'product QR code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrData!,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                //embeddedImage: const AssetImage('assets/logo.png'), // 可选：添加logo
                //embeddedImageStyle: const QrEmbeddedImageStyle(
                //  size: Size(40, 40),
                //),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _qrData!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Card(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyQRData,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareQRCode,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Use instructions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Print or display QR code on product packaging\n'
                  '• Consumers can scan the product information using the NutriGuard application\n'
                  '• QR code contains the unique identifier of the product\n'
                  '• Supports product tracing and recall functions',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _copyQRData() {
    if (_qrData != null) {
      Clipboard.setData(ClipboardData(text: _qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code data has been copied to the clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareQRCode() {
    if (_qrData != null) {
      Share.share(
        'NutriGuard product QR code\nProduct ID: ${_productIdController.text}\nScan link: $_qrData',
        subject: 'NutriGuard product QR code',
      );
    }
  }

  @override
  void dispose() {
    _productIdController.dispose();
    super.dispose();
  }
}


