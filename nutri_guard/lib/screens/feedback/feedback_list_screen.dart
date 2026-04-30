import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blockchain_provider.dart';
import '../../models/feedback_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../widgets/bottom_navigation.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  List<ConsumerFeedback> _feedbacks = [];
  Map<String, ProductModel> _products = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
  }

  Future<void> _loadFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final blockchainProvider = context.read<BlockchainProvider>();

      if (authProvider.currentUser != null) {
        final user = authProvider.currentUser!;

        // Load feedbacks + products 并行，确保反馈卡片能显示产品名。
        await Future.wait([
          blockchainProvider.loadFeedbacks(user.role),
          if (blockchainProvider.products.isEmpty) blockchainProvider.loadProducts(),
        ]);

        final feedbacks = blockchainProvider.feedbacks;
        final productMap = <String, ProductModel>{
          for (final p in blockchainProvider.products) p.id: p,
        };

        if (!mounted) return;
        setState(() {
          _feedbacks = feedbacks;
          _products = productMap;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load feedbacks: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(user?.isMerchant == true ? 'Customer Feedback' : 'My Feedback'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbacks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFeedbacks,
              child: _feedbacks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _feedbacks.length,
                      itemBuilder: (context, index) {
                        final feedback = _feedbacks[index];
                        return _buildFeedbackCard(feedback);
                      },
                    ),
            ),
      floatingActionButton: user?.isConsumer == true 
          ? FloatingActionButton(
              onPressed: _showSubmitFeedbackDialog,
              child: const Icon(Icons.add),
              tooltip: 'Submit Feedback',
            )
          : null,
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isMerchant = authProvider.currentUser?.role == UserRole.merchant;
          // For merchants, feedback is not in navigation. For consumers, it's index 3
          return BottomNavigation(currentIndex: isMerchant ? 0 : 3); // Feedback tab for consumer
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final user = context.read<AuthProvider>().currentUser;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.feedback_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            user?.isMerchant == true ? 'No customer feedback yet' : 'No feedback submitted yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.isMerchant == true 
                ? 'Customer feedback will appear here'
                : 'Your submitted feedback will appear here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (user?.isConsumer == true) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showSubmitFeedbackDialog,
              icon: const Icon(Icons.add),
              label: const Text('Submit Feedback'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(ConsumerFeedback feedback) {
    final product = _products[feedback.productId];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRatingColor(feedback.rating),
                  child: Text(
                    feedback.rating.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product?.name ?? 'Product #${feedback.productId}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) => Icon(
                            index < feedback.rating ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          )),
                          const SizedBox(width: 8),
                          Text(
                            feedback.ratingText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
                    color: feedback.isProcessed 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feedback.isProcessed ? 'Processed' : 'Pending',
                    style: TextStyle(
                      color: feedback.isProcessed ? Colors.green : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                feedback.feedbackText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${feedback.consumerAddress.substring(0, 6)}...${feedback.consumerAddress.substring(feedback.consumerAddress.length - 4)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(feedback.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Add action button for merchants
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final isMerchant = authProvider.currentUser?.isMerchant == true;
                if (isMerchant && !feedback.isProcessed) {
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _markAsProcessed(feedback),
                            icon: const Icon(Icons.check_circle, size: 16),
                            label: const Text('Mark as Processed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showSubmitFeedbackDialog() {
    final blockchainProvider = context.read<BlockchainProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) return;

    // Get consumer's registered products
    final registeredProducts = blockchainProvider.getUserProducts(user.walletAddress, user.role);
    
    if (registeredProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No registered products found. Please register products first by scanning their QR codes.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _FeedbackSubmissionDialog(
        products: registeredProducts,
        onSubmit: _submitFeedback,
      ),
    );
  }

  Future<void> _submitFeedback(String productId, String feedbackText, int rating) async {
    try {
      final blockchainProvider = context.read<BlockchainProvider>();
      
      final success = await blockchainProvider.submitFeedback(
        productId: int.parse(productId),
        feedbackText: feedbackText,
        rating: rating,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback submitted successfully!')),
          );
          _loadFeedbacks(); // Refresh the feedback list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit feedback')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  Future<void> _markAsProcessed(ConsumerFeedback feedback) async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mark as Processed'),
          content: Text(
            'Are you sure you want to mark this feedback as processed?\n\nProduct: ${_products[feedback.productId]?.name ?? 'Product #${feedback.productId}'}\nRating: ${feedback.rating} stars',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Processed'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final blockchainProvider = context.read<BlockchainProvider>();
      
      final success = await blockchainProvider.markFeedbackAsProcessed(int.parse(feedback.id));

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback marked as processed successfully!')),
          );
          _loadFeedbacks(); // Refresh the feedback list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to mark feedback as processed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing feedback: $e')),
        );
      }
    }
  }
}

class _FeedbackSubmissionDialog extends StatefulWidget {
  final List<ProductModel> products;
  final Function(String productId, String feedbackText, int rating) onSubmit;

  const _FeedbackSubmissionDialog({
    required this.products,
    required this.onSubmit,
  });

  @override
  State<_FeedbackSubmissionDialog> createState() => _FeedbackSubmissionDialogState();
}

class _FeedbackSubmissionDialogState extends State<_FeedbackSubmissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  ProductModel? _selectedProduct;
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Feedback'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Product', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ProductModel>(
                  value: _selectedProduct,
                  items: widget.products.map((product) {
                    return DropdownMenuItem<ProductModel>(
                      value: product,
                      child: Text(
                        product.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Choose a product',
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a product';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 4.0,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Share your experience with this product...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your feedback';
                    }
                    if (value.trim().length < 10) {
                      return 'Feedback must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  void _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(
        _selectedProduct!.id,
        _feedbackController.text.trim(),
        _rating,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
