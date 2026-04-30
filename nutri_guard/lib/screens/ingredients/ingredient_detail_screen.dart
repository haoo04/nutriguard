import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/ingredient_model.dart';
import '../../models/supplier_model.dart';

class IngredientDetailScreen extends StatefulWidget {
  final String ingredientId;

  const IngredientDetailScreen({
    super.key,
    required this.ingredientId,
  });

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  IngredientModel? _ingredient;
  SupplierModel? _supplier;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIngredient();
  }

  Future<void> _loadIngredient() async {
    setState(() => _isLoading = true);
    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      final ingredient = await blockchainProvider.blockchainService
          .getIngredientInfo(int.parse(widget.ingredientId));
      
      // Load supplier information
      SupplierModel? supplier;
      try {
        supplier = await blockchainProvider.blockchainService
            .getSupplierInfo(int.parse(ingredient.supplierId));
      } catch (e) {
        print('Error loading supplier: $e');
      }

      if (!mounted) return;
      setState(() {
        _ingredient = ingredient;
        _supplier = supplier;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load ingredient: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ingredient?.name ?? 'Ingredient Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ingredient == null
              ? const Center(child: Text('Ingredient not found'))
              : RefreshIndicator(
                  onRefresh: _loadIngredient,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusCard(),
                        const SizedBox(height: 16),
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        if (_supplier != null)
                          _buildSupplierCard(),
                        const SizedBox(height: 16),
                        _buildDatesCard(),
                        const SizedBox(height: 16),
                        _buildStorageCard(),
                        const SizedBox(height: 16),
                        _buildActionsCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _parseStatusColor(_ingredient!.statusColor),
              child: Icon(
                _ingredient!.isRecalled || _ingredient!.isContaminated
                    ? Icons.warning
                    : _ingredient!.isExpired
                        ? Icons.schedule
                        : Icons.check_circle,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ingredient!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _parseStatusColor(_ingredient!.statusColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _ingredient!.statusText,
                      style: TextStyle(
                        color: _parseStatusColor(_ingredient!.statusColor),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
            _buildInfoRow('Ingredient ID', _ingredient!.id),
            _buildInfoRow('Name', _ingredient!.name),
            if (_ingredient!.category != null)
              _buildInfoRow('Category', _ingredient!.category!),
            _buildInfoRow('UPC Code', _ingredient!.upc),
            _buildInfoRow('Batch Number', _ingredient!.batchNumber),
            _buildInfoRow('Weight', '${_ingredient!.weight.toStringAsFixed(0)} grams'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Supplier Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Supplier Name', _supplier!.name),
            _buildInfoRow('Contact Info', _supplier!.contactInfo),
            if (_supplier!.certifications.isNotEmpty)
              _buildInfoRow('Certifications', _supplier!.certifications),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Production Date', _formatDate(_ingredient!.productionDate)),
            _buildInfoRow('Expiry Date', _formatDate(_ingredient!.expiryDate)),
            _buildInfoRow('Registered Date', _formatDate(_ingredient!.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Storage Requirements',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.thermostat, color: Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          'Temperature',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_ingredient!.storageEnv.minTemperature.toStringAsFixed(1)}°C to ${_ingredient!.storageEnv.maxTemperature.toStringAsFixed(1)}°C',
                          style: TextStyle(color: Colors.blue[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.water_drop, color: Colors.teal),
                        const SizedBox(height: 8),
                        Text(
                          'Humidity',
                          style: TextStyle(
                            color: Colors.teal[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_ingredient!.storageEnv.minHumidity.toStringAsFixed(0)}% to ${_ingredient!.storageEnv.maxHumidity.toStringAsFixed(0)}%',
                          style: TextStyle(color: Colors.teal[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    // 只有商家可以标记原料为召回状态，且原料不能已经被标记为召回或污染
    final canMarkRecall = !_ingredient!.isRecalled && !_ingredient!.isContaminated;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Management Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (canMarkRecall) ...[
              /*SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showMarkContaminatedDialog(),
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text('Mark as Contaminated'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ), */
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showInitiateRecallDialog(),
                  icon: const Icon(Icons.report_problem, color: Colors.white),
                  label: const Text('Initiate Recall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ingredient!.isRecalled 
                          ? 'This ingredient has already been recalled'
                          : 'This ingredient has been marked as contaminated',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /*void _showMarkContaminatedDialog() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mark as Contaminated'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This action will mark the ingredient "${_ingredient!.name}" as contaminated. '
                  'All products containing this ingredient will be affected.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Contamination Reason',
                    hintText: 'Enter the reason for contamination...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
            onPressed: () => _markAsContaminated(reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Contaminated'),
          ),
        ],
      ),
    );
  }*/

  void _showInitiateRecallDialog() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red),
            SizedBox(width: 8),
            Text('Initiate Recall'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a critical action that cannot be undone!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This action will initiate a full recall of ingredient "${_ingredient!.name}" '
                  'and notify all consumers who have registered for alerts about affected products.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Recall Reason *',
                    hintText: 'Enter the reason for recall...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
            onPressed: () => _initiateRecall(reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Initiate Recall'),
          ),
        ],
      ),
    );
  }

  /*Future<void> _markAsContaminated(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for contamination')),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    final blockchainProvider = context.read<BlockchainProvider>();
    
    try {
      final success = await blockchainProvider.markIngredientContaminated(
        ingredientId: int.parse(widget.ingredientId),
        reason: reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingredient marked as contaminated successfully'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadIngredient(); // Refresh the ingredient data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark ingredient as contaminated: ${blockchainProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }*/

  Future<void> _initiateRecall(String reason) async {
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for recall')),
      );
      return;
    }

    Navigator.of(context).pop(); // Close dialog

    final blockchainProvider = context.read<BlockchainProvider>();
    
    try {
      final success = await blockchainProvider.initiateRecall(
        ingredientId: int.parse(widget.ingredientId),
        reason: reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recall initiated successfully. Consumers will be notified.'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadIngredient(); // Refresh the ingredient data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initiate recall: ${blockchainProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _parseStatusColor(String value) {
    final hex = value.startsWith('#') ? value.substring(1) : value;
    try {
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      // Invalid color values should not break the detail page.
    }
    return Colors.grey;
  }
}