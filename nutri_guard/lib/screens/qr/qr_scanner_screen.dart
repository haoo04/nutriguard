import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!isScanning) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          _buildScannerOverlay(),
          _buildInstructions(),
        ],
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isMerchant = authProvider.currentUser?.role == UserRole.merchant;
          return BottomNavigation(currentIndex: isMerchant ? 3 : 1); // Scan tab index
        },
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Container(
      decoration: ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: Theme.of(context).colorScheme.primary,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 140, // 增加距离底部的高度以避免与底部导航栏重叠
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Scan the product QR code to view details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _handleQRCode(String qrData) {
    if (!mounted) return;
    setState(() {
      isScanning = false;
    });

    // 解析QR码数据
    try {
      // 假设QR码包含产品ID
      final productId = _extractProductId(qrData);
      
      if (productId != null) {
        _showProductDialog(productId);
      } else {
        _showErrorDialog('Invalid QR code');
      }
    } catch (e) {
      _showErrorDialog('QR code parsing failed: $e');
    }
  }

  String? _extractProductId(String qrData) {
    // 这里应该根据你的QR码格式来解析
    // 例如: "nutriguard://product/123" 或者简单的产品ID
    
    if (qrData.startsWith('nutriguard://product/')) {
      return qrData.split('/').last;
    } else if (RegExp(r'^\d+$').hasMatch(qrData)) {
      // 纯数字，可能是产品ID
      return qrData;
    }
    
    return null;
  }

  void _showProductDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => _ProductInfoDialog(
        productId: productId,
        onClose: () {
          Navigator.of(context).pop();
          if (!mounted) return;
          setState(() {
            isScanning = true;
          });
        },
        onViewDetails: () {
          Navigator.of(context).pop();
          context.go('/products/$productId');
        },
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan error'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (!mounted) return;
              setState(() {
                isScanning = true;
              });
            },
            child: const Text('Rescan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class QRScannerOverlayShape extends ShapeBorder {
  const QRScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - mCutOutSize) / 2 + borderOffset,
      rect.top + (height - mCutOutSize) / 2 + borderOffset,
      mCutOutSize - borderOffset * 2,
      mCutOutSize - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final path = Path()
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.left + borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderOffset);

    canvas.drawPath(path, borderPaint);

    final path2 = Path()
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.top + borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.top + borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.top - borderOffset,
          cutOutRect.right - borderRadius, cutOutRect.top - borderOffset)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderOffset);

    canvas.drawPath(path2, borderPaint);

    final path3 = Path()
      ..moveTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.left - borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.left + borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderOffset);

    canvas.drawPath(path3, borderPaint);

    final path4 = Path()
      ..moveTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderLength)
      ..lineTo(cutOutRect.right + borderOffset, cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(cutOutRect.right + borderOffset, cutOutRect.bottom + borderOffset,
          cutOutRect.right - borderRadius, cutOutRect.bottom + borderOffset)
      ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderOffset);

    canvas.drawPath(path4, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QRScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}

class _ProductInfoDialog extends StatefulWidget {
  final String productId;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;

  const _ProductInfoDialog({
    required this.productId,
    required this.onClose,
    required this.onViewDetails,
  });

  @override
  State<_ProductInfoDialog> createState() => _ProductInfoDialogState();
}

class _ProductInfoDialogState extends State<_ProductInfoDialog> {
  ProductModel? _product;
  bool _isLoading = true;
  String? _error;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      final product = await blockchainProvider.blockchainService
          .getProductWithDetails(int.parse(widget.productId));

      if (!mounted) return;
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load product: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Product Information'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // 限制最大高度
        child: SingleChildScrollView(
          child: _isLoading
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading product information...'),
                  ],
                )
              : _error != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: Colors.red[600])),
                      ],
                    )
                  : _buildProductInfo(),
        ),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildProductInfo() {
    if (_product == null) return const SizedBox.shrink();

    final isConsumer = context.read<AuthProvider>().currentUser?.role == UserRole.consumer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product basic info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Product details
        _buildInfoRow('Product ID', _product!.id),
        _buildInfoRow('Category', _product!.category.name),
        if (_product!.description.isNotEmpty)
          _buildInfoRow('Description', _product!.description),
        _buildInfoRow('Production Date', _product!.productionDate?.toString().split(' ')[0] ?? 'Not specified'),
        
        // Consumer registration section
        if (isConsumer && _product!.status == ProductStatus.safe) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Register for Product Alerts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 12),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final userEmail = authProvider.currentUser?.email ?? '';
              final hasEmail = userEmail.isNotEmpty;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasEmail ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasEmail ? Colors.green[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasEmail ? Icons.check_circle : Icons.warning,
                          color: hasEmail ? Colors.green[700] : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasEmail ? 'Email Configured' : 'Email Required',
                                style: TextStyle(
                                  color: hasEmail ? Colors.green[700] : Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                hasEmail 
                                    ? 'Notifications will be sent to: $userEmail'
                                    : 'Please set your email in settings',
                                style: TextStyle(
                                  color: hasEmail ? Colors.green[600] : Colors.orange[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!hasEmail) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close current dialog
                            context.push('/profile'); // Navigate to profile
                          },
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Go to Profile Settings'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(color: Colors.orange[300]!),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
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
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
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

  Color _getStatusColor() {
    if (_product == null) return Colors.grey;
    
    switch (_product!.status) {
      case ProductStatus.safe:
        return _product!.hasRecalledIngredients ? Colors.orange : Colors.green;
      case ProductStatus.alert:
        return Colors.orange;
      case ProductStatus.contaminated:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    if (_product == null) return Icons.help_outline;
    
    switch (_product!.status) {
      case ProductStatus.safe:
        return _product!.hasRecalledIngredients ? Icons.warning : Icons.check_circle;
      case ProductStatus.alert:
        return Icons.warning;
      case ProductStatus.contaminated:
        return Icons.dangerous;
    }
  }

  String _getStatusText() {
    if (_product == null) return 'Unknown';
    
    if (_product!.hasRecalledIngredients) {
      return 'Contains Recalled Ingredients';
    }
    
    switch (_product!.status) {
      case ProductStatus.safe:
        return 'Safe for Consumption';
      case ProductStatus.alert:
        return 'Quality Alert';
      case ProductStatus.contaminated:
        return 'Contaminated - Do Not Consume';
    }
  }

  List<Widget> _buildActions() {
    final authProvider = context.watch<AuthProvider>(); // Use watch instead of read for reactive updates
    final isConsumer = authProvider.currentUser?.role == UserRole.consumer;
    final userEmail = authProvider.currentUser?.email ?? '';
    final hasEmail = userEmail.isNotEmpty;
    
    List<Widget> actions = [
      TextButton(
        onPressed: widget.onClose,
        child: const Text('Close'),
      ),
    ];

    if (_product != null && !_isLoading && _error == null) {
      actions.add(
        TextButton(
          onPressed: widget.onViewDetails,
          child: const Text('View Details'),
        ),
      );

      // Add registration button for consumers
      if (isConsumer && _product!.status == ProductStatus.safe) {
        actions.add(
          ElevatedButton(
            onPressed: _isRegistering || !hasEmail ? null : _registerForAlerts,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasEmail ? null : Colors.grey,
            ),
            child: _isRegistering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(hasEmail ? 'Register for Alerts' : 'Email Required'),
          ),
        );
      }
    }

    return actions;
  }

  Future<void> _registerForAlerts() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final messenger = ScaffoldMessenger.of(context);
      final blockchainProvider = context.read<BlockchainProvider>();
      final authProvider = context.read<AuthProvider>();
      
      // 获取用户设置的邮箱
      final userEmail = authProvider.currentUser?.email ?? '';
      
      // 检查用户是否设置了邮箱
      if (userEmail.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Please set your email address in Profile settings first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _isRegistering = false;
        });
        return;
      }
      
      final success = await blockchainProvider.registerForProductAlerts(
        productId: int.parse(widget.productId),
        email: userEmail,
      );

      if (!mounted) return;
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Successfully registered product to your account!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onClose();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${blockchainProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}


