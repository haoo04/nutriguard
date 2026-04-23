import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/product_model.dart';
import '../../models/quality_model.dart';
import '../../services/iot_sensor_service.dart';
import '../../widgets/bottom_navigation.dart';

class QualityControlScreen extends StatefulWidget {
  const QualityControlScreen({super.key});

  @override
  State<QualityControlScreen> createState() => _QualityControlScreenState();
}

class _QualityControlScreenState extends State<QualityControlScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final blockchainProvider = context.read<BlockchainProvider>();
      
      if (authProvider.currentUser != null) {
        final productIds = await blockchainProvider.blockchainService
            .getMerchantProducts(authProvider.currentUser!.walletAddress);
        
        final products = <ProductModel>[];
        for (final id in productIds) {
          try {
            final product = await blockchainProvider.blockchainService
                .getProductWithDetails(id);
            products.add(product);
          } catch (e) {
            print('Error loading product $id: $e');
          }
        }
        
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quality Control'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products for quality control',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create products to manage quality control',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final hasProductionData = product.productionData?.hasData ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () => _showProductionDataDialog(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(product.status),
                    child: Icon(
                      _getStatusIcon(product.status),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(product.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(product.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (hasProductionData) ...[
                _buildProductionDataSummary(product.productionData!),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Production data not submitted',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showProductionDataDialog(product),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 16,
                    color: product.canGenerateQR ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.canGenerateQR ? 'QR Ready' : 'QR Blocked',
                    style: TextStyle(
                      color: product.canGenerateQR ? Colors.green : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'ID: ${product.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
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

  Widget _buildProductionDataSummary(ProductionData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: data.isCompliant 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                data.isCompliant ? Icons.check_circle : Icons.error,
                color: data.isCompliant ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                data.statusText,
                style: TextStyle(
                  color: data.isCompliant ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Submitted: ${_formatDate(data.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDataPoint('Temp', data.temperatureText, Icons.thermostat),
              ),
              Expanded(
                child: _buildDataPoint('Humidity', data.humidityText, Icons.water_drop),
              ),
              Expanded(
                child: _buildDataPoint('Weight', data.weightText, Icons.monitor_weight),
              ),
              if (data.phValue > 0)
                Expanded(
                  child: _buildDataPoint('pH', data.phText, Icons.science),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataPoint(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showProductionDataDialog(ProductModel product) {
    final hasData = product.productionData?.hasData ?? false;
    
    if (hasData) {
      _showProductionDataDetails(product);
    } else {
      _showSubmitProductionDataDialog(product);
    }
  }

  void _showProductionDataDetails(ProductModel product) {
    final data = product.productionData!;
    final rule = product.qualityRule;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Production Data - ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.isCompliant 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.isCompliant ? Icons.check_circle : Icons.error,
                      color: data.isCompliant ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.statusText,
                      style: TextStyle(
                        color: data.isCompliant ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildComparisonRow('Temperature', data.temperatureText, 
                  rule?.temperatureRange ?? 'N/A', data.temperature, 
                  rule?.minTemperature, rule?.maxTemperature),
              _buildComparisonRow('Humidity', data.humidityText, 
                  rule?.humidityRange ?? 'N/A', data.humidity, 
                  rule?.minHumidity, rule?.maxHumidity),
              _buildComparisonRow('Weight', data.weightText, 
                  rule?.weightRange ?? 'N/A', data.weight, 
                  rule?.minWeight, rule?.maxWeight),
              if (product.category == ProductCategory.beverage && data.phValue > 0)
                _buildComparisonRow('pH', data.phText, 
                    rule?.phRange ?? 'N/A', data.phValue, 
                    rule?.minPH, rule?.maxPH),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${_formatDateTime(data.timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
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

  Widget _buildComparisonRow(String label, String actual, String required, 
      double actualValue, double? minValue, double? maxValue) {
    bool isInRange = true;
    if (minValue != null && maxValue != null) {
      isInRange = actualValue >= minValue && actualValue <= maxValue;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Actual: $actual'),
                    const SizedBox(width: 8),
                    Icon(
                      isInRange ? Icons.check : Icons.close,
                      size: 16,
                      color: isInRange ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                Text(
                  'Required: $required',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitProductionDataDialog(ProductModel product) {
    final tempController = TextEditingController();
    final humidityController = TextEditingController();
    final weightController = TextEditingController();
    final phController = TextEditingController();

    SensorReading? lastReading;
    bool isFetching = false;
    String? fetchError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> fetchFromIoT() async {
            setDialogState(() {
              isFetching = true;
              fetchError = null;
            });
            final service = IoTSensorService();
            try {
              final reading = await service.fetchLatest();
              if (!reading.isUsable) {
                setDialogState(() {
                  isFetching = false;
                  lastReading = reading;
                  fetchError =
                      '传感器数据过期 (quality=${reading.quality}), 请检查树莓派';
                });
                return;
              }
              setDialogState(() {
                isFetching = false;
                lastReading = reading;
                tempController.text = reading.temperatureC!.round().toString();
                humidityController.text =
                    reading.humidityPct!.round().toString();
              });
            } catch (err) {
              setDialogState(() {
                isFetching = false;
                fetchError = '$err';
              });
            } finally {
              service.dispose();
            }
          }

          return AlertDialog(
            title: Text('Submit Production Data - ${product.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: isFetching ? null : fetchFromIoT,
                    icon: isFetching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sensors),
                    label: Text(isFetching ? '读取中...' : '从 IoT 设备读取'),
                  ),
                  if (lastReading != null || fetchError != null) ...[
                    const SizedBox(height: 8),
                    _buildSensorStatus(lastReading, fetchError),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: tempController,
                    decoration: const InputDecoration(
                      labelText: 'Temperature (°C)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: humidityController,
                    decoration: const InputDecoration(
                      labelText: 'Humidity (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (product.category == ProductCategory.beverage) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phController,
                      decoration: const InputDecoration(
                        labelText: 'pH Value',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tempController.text.isEmpty ||
                      humidityController.text.isEmpty ||
                      weightController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all required fields')),
                    );
                    return;
                  }

                  Navigator.of(dialogContext).pop();
                  await _submitProductionData(
                    product,
                    double.parse(tempController.text),
                    double.parse(humidityController.text),
                    double.parse(weightController.text),
                    phController.text.isNotEmpty
                        ? double.parse(phController.text)
                        : 0,
                  );
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorStatus(SensorReading? reading, String? error) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
    if (reading == null) return const SizedBox.shrink();
    final isOk = reading.isUsable;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isOk ? Colors.green : Colors.orange).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: (isOk ? Colors.green : Colors.orange).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.warning_amber_rounded,
            color: isOk ? Colors.green : Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设备: ${reading.deviceId} · 样本数: ${reading.sampleCount}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '采样时间: ${_formatDateTime(reading.sampledAt)}'
                  ' · 质量: ${reading.quality}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProductionData(ProductModel product, double temperature,
      double humidity, double weight, double phValue) async {
    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      await blockchainProvider.blockchainService.submitProductionData(
        productId: int.parse(product.id),
        temperature: temperature,
        humidity: humidity,
        weight: weight,
        phValue: phValue,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Production data submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit production data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(ProductStatus status) {
    switch (status) {
      case ProductStatus.safe:
        return Colors.green;
      case ProductStatus.alert:
        return Colors.orange;
      case ProductStatus.contaminated:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ProductStatus status) {
    switch (status) {
      case ProductStatus.safe:
        return Icons.check_circle;
      case ProductStatus.alert:
        return Icons.warning;
      case ProductStatus.contaminated:
        return Icons.dangerous;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
