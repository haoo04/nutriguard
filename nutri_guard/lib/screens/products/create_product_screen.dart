import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/blockchain_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ingredient_model.dart';
import '../../models/product_model.dart';
import '../../models/quality_model.dart';

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _upcController = TextEditingController();
  
  // Quality control rule controllers
  final _minTempController = TextEditingController();
  final _maxTempController = TextEditingController();
  final _minHumidityController = TextEditingController();
  final _maxHumidityController = TextEditingController();
  final _minWeightController = TextEditingController();
  final _maxWeightController = TextEditingController();
  final _minPHController = TextEditingController();
  final _maxPHController = TextEditingController();
  
  ProductCategory _selectedCategory = ProductCategory.mainFood;
  List<IngredientModel> _selectedIngredients = [];
  List<IngredientModel> _availableIngredients = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableIngredients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _upcController.dispose();
    _minTempController.dispose();
    _maxTempController.dispose();
    _minHumidityController.dispose();
    _maxHumidityController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    _minPHController.dispose();
    _maxPHController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableIngredients() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final blockchainProvider = context.read<BlockchainProvider>();
      
      if (authProvider.currentUser != null) {
        final ingredientIds = await blockchainProvider.blockchainService
            .getMerchantIngredients(authProvider.currentUser!.walletAddress);
        
        final ingredients = <IngredientModel>[];
        for (final id in ingredientIds) {
          try {
            final ingredient = await blockchainProvider.blockchainService
                .getIngredientInfo(id);
            if (ingredient.isValid) {  // Only show valid ingredients
              ingredients.add(ingredient);
      }
    } catch (e) {
            print('Error loading ingredient $id: $e');
          }
    }

    setState(() {
          _availableIngredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ingredients: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Product'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                    _buildIngredientsSection(),
                    const SizedBox(height: 24),
                    _buildQualityRulesSection(),
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
            Icons.inventory,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Create New Product',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up product information and HACCP quality standards',
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
                  'Product Information',
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
                labelText: 'Product Name *',
                hintText: 'e.g., Black Pepper Chicken Steak',
                prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Product name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed product description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
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
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ProductCategory>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(),
                              ),
                              items: ProductCategory.values.map((category) {
                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.displayName),
                                );
                              }).toList(),
              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
    );
  }

  Widget _buildIngredientsSection() {
    return Card(
                      child: Padding(
        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ingredients (${_selectedIngredients.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                                  onPressed: _availableIngredients.isEmpty ? null : _showIngredientSelector,
                                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_availableIngredients.isEmpty)
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
                      'No ingredients available',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please register ingredients first',
                      style: TextStyle(
                        color: Colors.orange[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_selectedIngredients.isEmpty)
                              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                child: Text(
                  'No ingredients selected. Tap "Add Ingredients" to select.',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                                ),
                              )
                            else
              ..._selectedIngredients.map((ingredient) => _buildIngredientItem(ingredient)),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem(IngredientModel ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green,
            child: const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Batch: ${ingredient.batchNumber} | UPC: ${ingredient.upc}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedIngredients.remove(ingredient);
                                          });
                                        },
            icon: const Icon(Icons.remove_circle, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityRulesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'HACCP Quality Rules',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set production standards that must be met for this product',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Temperature range
            Text(
              'Temperature Range (°C)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minTempController,
                    decoration: const InputDecoration(
                      labelText: 'Min Temperature *',
                      hintText: '60',
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
                      labelText: 'Max Temperature *',
                      hintText: '75',
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
            // Humidity range
            Text(
              'Humidity Range (%)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minHumidityController,
                    decoration: const InputDecoration(
                      labelText: 'Min Humidity *',
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
                      labelText: 'Max Humidity *',
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
            const SizedBox(height: 16),
            // Weight range
            Text(
              'Weight Range (grams)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Min Weight *',
                      hintText: '200',
                      prefixIcon: Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0) {
                        return 'Enter valid weight';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxWeightController,
                    decoration: const InputDecoration(
                      labelText: 'Max Weight *',
                      hintText: '300',
                      prefixIcon: Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
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
            if (_selectedCategory == ProductCategory.beverage) ...[
              const SizedBox(height: 16),
              Text(
                'pH Range (for beverages)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPHController,
                      decoration: const InputDecoration(
                        labelText: 'Min pH *',
                        hintText: '6.5',
                        prefixIcon: Icon(Icons.science),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_selectedCategory == ProductCategory.beverage) {
                          if (value == null || value.isEmpty) {
                            return 'Required for beverages';
                          }
                          final ph = double.tryParse(value);
                          if (ph == null || ph < 0 || ph > 14) {
                            return 'Enter 0-14';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPHController,
                      decoration: const InputDecoration(
                        labelText: 'Max pH *',
                        hintText: '7.5',
                        prefixIcon: Icon(Icons.science),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_selectedCategory == ProductCategory.beverage) {
                          if (value == null || value.isEmpty) {
                            return 'Required for beverages';
                          }
                          final ph = double.tryParse(value);
                          if (ph == null || ph < 0 || ph > 14) {
                            return 'Enter 0-14';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
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
                'Create Product',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  void _showIngredientSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Select Ingredients',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _availableIngredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _availableIngredients[index];
                  final isSelected = _selectedIngredients.contains(ingredient);
                  
                  return CheckboxListTile(
                    title: Text(ingredient.name),
                    subtitle: Text('Batch: ${ingredient.batchNumber}'),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIngredients.add(ingredient);
                        } else {
                          _selectedIngredients.remove(ingredient);
                        }
                      });
                      Navigator.of(context).pop();
                      _showIngredientSelector(); // Refresh the modal
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one ingredient')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Validate ranges
      final minTemp = double.parse(_minTempController.text);
      final maxTemp = double.parse(_maxTempController.text);
      if (minTemp >= maxTemp) {
        throw Exception('Minimum temperature must be lower than maximum temperature');
      }

      final minHumidity = double.parse(_minHumidityController.text);
      final maxHumidity = double.parse(_maxHumidityController.text);
      if (minHumidity >= maxHumidity) {
        throw Exception('Minimum humidity must be lower than maximum humidity');
      }

      final minWeight = double.parse(_minWeightController.text);
      final maxWeight = double.parse(_maxWeightController.text);
      if (minWeight >= maxWeight) {
        throw Exception('Minimum weight must be lower than maximum weight');
      }

      double minPH = 0, maxPH = 0;
      if (_selectedCategory == ProductCategory.beverage) {
        minPH = double.parse(_minPHController.text);
        maxPH = double.parse(_maxPHController.text);
        if (minPH >= maxPH) {
          throw Exception('Minimum pH must be lower than maximum pH');
        }
      }

      final blockchainProvider = context.read<BlockchainProvider>();
      
      // Create quality rule
      final qualityRule = QualityRule(
        minTemperature: minTemp,
        maxTemperature: maxTemp,
        minHumidity: minHumidity,
        maxHumidity: maxHumidity,
        minWeight: minWeight,
        maxWeight: maxWeight,
        minPH: minPH,
        maxPH: maxPH,
      );
      
      // Mock IPFS hash (in real implementation, upload to IPFS)
      final ipfsHash = 'QmHash${DateTime.now().millisecondsSinceEpoch}';

      await blockchainProvider.blockchainService.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        upc: _upcController.text.trim(),
        category: _selectedCategory,
        ingredientIds: _selectedIngredients.map((i) => int.parse(i.id)).toList(),
        ipfsHash: ipfsHash,
        qualityRule: qualityRule,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create product: $e'),
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
}