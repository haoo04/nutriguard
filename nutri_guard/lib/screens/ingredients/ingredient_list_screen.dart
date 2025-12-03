import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation.dart';
import '../../providers/blockchain_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ingredient_model.dart';
import 'create_ingredient_screen.dart';
import 'ingredient_detail_screen.dart';

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserIngredients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserIngredients() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final blockchainProvider = Provider.of<BlockchainProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await blockchainProvider.loadUserData(authProvider.currentUser!.walletAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateIngredientScreen(),
                ),
              );
              if (result == true) {
                _loadUserIngredients();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserIngredients,
          ),
        ],
      ),
      body: Consumer2<BlockchainProvider, AuthProvider>(
        builder: (context, blockchainProvider, authProvider, child) {
          if (blockchainProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (blockchainProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Load failed',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blockchainProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserIngredients,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final userAddress = authProvider.currentUser?.walletAddress ?? '';
          final userIngredients = blockchainProvider.getUserIngredients(userAddress);
          final filteredIngredients = blockchainProvider.searchIngredients(_searchQuery);
          final displayIngredients = _searchQuery.isEmpty 
              ? userIngredients 
              : filteredIngredients.where((ingredient) => 
                  ingredient.merchantAddress.toLowerCase() == userAddress.toLowerCase()
                ).toList();

          return Column(
            children: [
              // 搜索栏
              Container(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ingredient...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // 统计信息
              if (userIngredients.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total',
                        userIngredients.length.toString(),
                        Icons.inventory,
                      ),
                      _buildStatItem(
                        'Recall',
                        userIngredients.where((i) => i.isRecalled).length.toString(),
                        Icons.warning,
                        color: Colors.orange,
                      ),
                      _buildStatItem(
                        'Valid',
                        userIngredients.where((i) => i.isValid).length.toString(),
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // 原料列表
              Expanded(
                child: displayIngredients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No ingredient' : 'No matching ingredient',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty ? 'Click the + button in the top right corner to add an ingredient' : 'Please try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: displayIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = displayIngredients[index];
                          return _buildIngredientCard(ingredient);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildIngredientCard(IngredientModel ingredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ingredient.isRecalled
              ? Colors.red[100]
              : ingredient.isExpired
                  ? Colors.orange[100]
                  : Colors.green[100],
          child: Icon(
            ingredient.isRecalled
                ? Icons.warning
                : ingredient.isExpired
                    ? Icons.schedule
                    : Icons.check_circle,
            color: ingredient.isRecalled
                ? Colors.red
                : ingredient.isExpired
                    ? Colors.orange
                    : Colors.green,
          ),
        ),
        title: Text(
          ingredient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ingredient.category != null)
              Text('Category: ${ingredient.category}'),
            Text('Created at: ${_formatDate(ingredient.createdAt)}'),
            Text('Expiry date: ${_formatDate(ingredient.expiryDate)}'),
            Text('Weight: ${ingredient.weight.toStringAsFixed(0)}g'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ingredient.isRecalled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Recalled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientDetailScreen(
                ingredientId: ingredient.id,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}




