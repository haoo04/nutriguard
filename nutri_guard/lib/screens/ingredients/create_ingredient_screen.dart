import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/blockchain_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/supplier_model.dart';

class CreateIngredientScreen extends StatefulWidget {
  const CreateIngredientScreen({super.key});

  @override
  State<CreateIngredientScreen> createState() => _CreateIngredientScreenState();
}

class _CreateIngredientScreenState extends State<CreateIngredientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _upcController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _weightController = TextEditingController();
  final _minTempController = TextEditingController();
  final _maxTempController = TextEditingController();
  final _minHumidityController = TextEditingController();
  final _maxHumidityController = TextEditingController();
  
  DateTime? _productionDate;
  DateTime? _expiryDate;
  int? _selectedSupplierId;
  List<SupplierModel> _suppliers = [];
  bool _isSubmitting = false;
  bool _isLoadingSuppliers = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _upcController.dispose();
    _batchNumberController.dispose();
    _weightController.dispose();
    _minTempController.dispose();
    _maxTempController.dispose();
    _minHumidityController.dispose();
    _maxHumidityController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoadingSuppliers = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final blockchainProvider = context.read<BlockchainProvider>();
      
      if (authProvider.currentUser != null) {
        final supplierIds = await blockchainProvider.blockchainService
            .getMerchantSuppliers(authProvider.currentUser!.walletAddress);
        
        final supplierResults = await Future.wait(supplierIds.map((id) async {
          try {
            final supplier = await blockchainProvider.blockchainService
                .getSupplierInfo(id);
            if (supplier.isActive) {
              return supplier;
            }
            return null;
          } catch (e) {
            print('Error loading supplier $id: $e');
            return null;
          }
        }));

        if (!mounted) return;
        setState(() {
          _suppliers = supplierResults.whereType<SupplierModel>().toList();
          _isLoadingSuppliers = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoadingSuppliers = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSuppliers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load suppliers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Ingredient'),
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
              _buildSupplierSection(),
              const SizedBox(height: 24),
              _buildDatesSection(),
              const SizedBox(height: 24),
              _buildStorageSection(),
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
            Icons.add_circle,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Register New Ingredient',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add ingredient information with complete traceability',
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
                          labelText: 'Ingredient Name *',
                hintText: 'e.g., Organic Flour',
                prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingredient name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                hintText: 'e.g., Grains, Meat, Vegetables',
                prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _upcController,
                    decoration: const InputDecoration(
                      labelText: 'UPC Code *',
                      hintText: 'Universal Product Code',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'UPC code is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _batchNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Batch Number *',
                      hintText: 'Batch identification',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Batch number is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                      labelText: 'Weight (grams) *',
                      hintText: '1000',
                      prefixIcon: Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Weight is required';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Enter valid weight';
                          }
                          return null;
                        },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierSection() {
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
                Expanded(
                  child: Text(
                    'Supplier Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/suppliers/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingSuppliers)
              const Center(child: CircularProgressIndicator())
            else if (_suppliers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No suppliers found',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please add a supplier first',
                      style: TextStyle(
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'Select Supplier *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: _suppliers.map((supplier) {
                  return DropdownMenuItem<int>(
                    value: int.parse(supplier.id),
                    child: Text(supplier.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a supplier';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
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
                  'Dates',
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
                  child: InkWell(
                    onTap: _selectProductionDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.production_quantity_limits),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'P.D. *',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _productionDate != null
                                    ? _formatDate(_productionDate!)
                                    : 'Select date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date *',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _expiryDate != null
                                    ? _formatDate(_expiryDate!)
                                    : 'Select date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildStorageSection() {
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
                  'Storage Environment',
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
                            child: TextFormField(
                              controller: _minTempController,
                              decoration: const InputDecoration(
                      labelText: 'Min Temp (°C) *',
                      hintText: '-18',
                      prefixIcon: Icon(Icons.ac_unit),
                                border: OutlineInputBorder(),
                              ),
                    keyboardType: TextInputType.number,
                              validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                        return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxTempController,
                              decoration: const InputDecoration(
                      labelText: 'Max Temp (°C) *',
                      hintText: '4',
                      prefixIcon: Icon(Icons.whatshot),
                                border: OutlineInputBorder(),
                              ),
                    keyboardType: TextInputType.number,
                              validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                        return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minHumidityController,
                              decoration: const InputDecoration(
                      labelText: 'Min Humidity (%) *',
                                hintText: '30',
                      prefixIcon: Icon(Icons.water_drop),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                                }
                                final humidity = double.tryParse(value);
                                if (humidity == null || humidity < 0 || humidity > 100) {
                        return 'Enter 0-100';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _maxHumidityController,
                              decoration: const InputDecoration(
                      labelText: 'Max Humidity (%) *',
                      hintText: '60',
                      prefixIcon: Icon(Icons.opacity),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                                }
                                final humidity = double.tryParse(value);
                                if (humidity == null || humidity < 0 || humidity > 100) {
                        return 'Enter 0-100';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
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
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Register Ingredient',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _selectProductionDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _productionDate = date;
      });
    }
  }

  Future<void> _selectExpiryDate() async {
    final initialDate = _productionDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.add(const Duration(days: 30)),
      firstDate: initialDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );

      if (!mounted) return;
      if (result != null) {
        setState(() {
          _upcController.text = result;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select production date')),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expiry date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Validate temperature range
      final minTemp = double.parse(_minTempController.text);
      final maxTemp = double.parse(_maxTempController.text);
      if (minTemp >= maxTemp) {
        throw Exception('Minimum temperature must be lower than maximum temperature');
      }

      // Validate humidity range
      final minHumidity = double.parse(_minHumidityController.text);
      final maxHumidity = double.parse(_maxHumidityController.text);
      if (minHumidity >= maxHumidity) {
        throw Exception('Minimum humidity must be lower than maximum humidity');
      }

      final blockchainProvider = context.read<BlockchainProvider>();
      
      // Mock IPFS hash (in real implementation, upload to IPFS)
      final ipfsHash = 'QmHash${DateTime.now().millisecondsSinceEpoch}';

      await blockchainProvider.blockchainService.registerIngredient(
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        upc: _upcController.text.trim(),
        supplierId: _selectedSupplierId!,
        productionDate: _productionDate!,
        expiryDate: _expiryDate!,
        batchNumber: _batchNumberController.text.trim(),
        minTemperature: minTemp,
        maxTemperature: maxTemp,
        minHumidity: minHumidity,
        maxHumidity: maxHumidity,
        weight: double.parse(_weightController.text),
        ipfsHash: ipfsHash,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingredient registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/ingredients');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register ingredient: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (_handled) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _handled = true;
              Navigator.of(context).pop(barcode.rawValue);
              return;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}