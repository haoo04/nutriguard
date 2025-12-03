import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../models/quality_model.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';
import '../services/blockchain_service.dart';

class BlockchainProvider extends ChangeNotifier {
  final BlockchainService _blockchainService = BlockchainService();

  List<SupplierModel> _suppliers = [];
  List<IngredientModel> _ingredients = [];
  List<ProductModel> _products = [];
  List<ProductModel> _consumerProducts = []; // 消费者注册的产品
  List<ConsumerFeedback> _feedbacks = [];
  List<RecallNotification> _recallNotifications = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SupplierModel> get suppliers => _suppliers;
  List<IngredientModel> get ingredients => _ingredients;
  List<ProductModel> get products => _products;
  List<ConsumerFeedback> get feedbacks => _feedbacks;
  List<RecallNotification> get recallNotifications => _recallNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 提供对blockchain service的访问
  BlockchainService get blockchainService => _blockchainService;

  // 获取用户相关的供应商
  List<SupplierModel> getUserSuppliers(String userAddress) {
    return _suppliers.where((supplier) => 
        supplier.merchantAddress.toLowerCase() == userAddress.toLowerCase()
    ).toList();
  }

  // 获取用户相关的原料
  List<IngredientModel> getUserIngredients(String userAddress) {
    return _ingredients.where((ingredient) => 
        ingredient.merchantAddress.toLowerCase() == userAddress.toLowerCase()
    ).toList();
  }

  // 获取用户相关的产品 - 需要传入用户角色
  List<ProductModel> getUserProducts(String userAddress, [UserRole? userRole]) {
    if (userRole == UserRole.consumer) {
      // 对于消费者，返回他们注册的产品
      return _consumerProducts;
    } else {
      // 对于商家，返回他们创建的产品
      return _products.where((product) => 
          product.merchantAddress.toLowerCase() == userAddress.toLowerCase()
      ).toList();
    }
  }
  
  // 获取消费者注册的产品
  List<ProductModel> getConsumerProducts(String userAddress) {
    return _consumerProducts;
  }

  // 获取用户相关的反馈
  List<ConsumerFeedback> getUserFeedbacks(String userAddress) {
    return _feedbacks.where((feedback) => 
        feedback.consumerAddress.toLowerCase() == userAddress.toLowerCase()
    ).toList();
  }

  // 获取未读的召回通知
  List<RecallNotification> getUnreadNotifications() {
    return _recallNotifications.where((notification) => !notification.isRead).toList();
  }

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _blockchainService.initialize();
      // 初始化时可以加载一些基础数据
    } catch (e) {
      _setError('区块链服务初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 用户注册
  Future<bool> registerUser(UserRole role) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.registerUser(role);
      await _waitForTransaction(txHash);
      return true;
    } catch (e) {
      _setError('用户注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 供应商相关操作
  Future<bool> registerSupplier({
    required String name,
    required String contactInfo,
    required String certifications,
  }) async {
    print('🔧 BlockchainProvider: 开始注册供应商');
    print('🔧 BlockchainProvider: 供应商名称: $name');
    
    _setLoading(true);
    _setError(null);

    try {
      // Check current user status before registering supplier
      if (_blockchainService.userAddress != null) {
        final userAddress = _blockchainService.userAddress!.hex;
        print('🔧 BlockchainProvider: 当前用户地址: $userAddress');
        
        try {
          final isRegistered = await _blockchainService.isUserRegistered(userAddress);
          print('🔧 BlockchainProvider: 用户已注册: $isRegistered');
          
          if (isRegistered) {
            final userRole = await _blockchainService.getUserRole(userAddress);
            print('🔧 BlockchainProvider: 用户角色: ${userRole.name}');
          }
        } catch (e) {
          print('🔧 BlockchainProvider: 检查用户状态失败: $e');
        }
      }
      
      print('🔧 BlockchainProvider: 调用 registerSupplier');
      final txHash = await _blockchainService.registerSupplier(
        name: name,
        contactInfo: contactInfo,
        certifications: certifications,
      );
      print('🔧 BlockchainProvider: 供应商注册交易哈希: $txHash');
      
      await _waitForTransaction(txHash);
      print('🔧 BlockchainProvider: 供应商注册交易确认');
      
      await loadSuppliers();
      print('🔧 BlockchainProvider: 供应商注册成功');
      return true;
    } catch (e) {
      print('🔧 BlockchainProvider: 供应商注册失败: $e');
      print('🔧 BlockchainProvider: 错误类型: ${e.runtimeType}');
      print('🔧 BlockchainProvider: 错误详情: ${e.toString()}');
      _setError('供应商注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSuppliers() async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔧 BlockchainProvider: 开始加载供应商列表');
      
      final userAddress = _blockchainService.userAddress;
      if (userAddress == null) {
        print('🔧 BlockchainProvider: 用户地址为空');
        _suppliers = [];
        notifyListeners();
        return;
      }

      print('🔧 BlockchainProvider: 用户地址: ${userAddress.hex}');
      
      // 获取商家的供应商ID列表
      final supplierIds = await _blockchainService.getMerchantSuppliers(userAddress.hex);
      print('🔧 BlockchainProvider: 供应商ID列表: $supplierIds');
      
      final suppliers = <SupplierModel>[];
      
      // 获取每个供应商的详细信息
      for (final supplierId in supplierIds) {
        try {
          print('🔧 BlockchainProvider: 加载供应商 $supplierId');
          final supplier = await _blockchainService.getSupplierInfo(supplierId);
          suppliers.add(supplier);
          print('🔧 BlockchainProvider: 成功加载供应商: ${supplier.name}');
        } catch (e) {
          print('🔧 BlockchainProvider: 加载供应商 $supplierId 失败: $e');
        }
      }
      
      _suppliers = suppliers;
      print('🔧 BlockchainProvider: 总共加载了 ${_suppliers.length} 个供应商');
      notifyListeners();
    } catch (e) {
      print('🔧 BlockchainProvider: 加载供应商列表失败: $e');
      _setError('加载供应商列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 原料相关操作
  Future<bool> registerIngredient({
    required String name,
    required String category,
    required String upc,
    required int supplierId,
    required DateTime productionDate,
    required DateTime expiryDate,
    required String batchNumber,
    required double minTemperature,
    required double maxTemperature,
    required double minHumidity,
    required double maxHumidity,
    required double weight,
    required String ipfsHash,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.registerIngredient(
        name: name,
        category: category,
        upc: upc,
        supplierId: supplierId,
        productionDate: productionDate,
        expiryDate: expiryDate,
        batchNumber: batchNumber,
        minTemperature: minTemperature,
        maxTemperature: maxTemperature,
        minHumidity: minHumidity,
        maxHumidity: maxHumidity,
        weight: weight,
        ipfsHash: ipfsHash,
      );

      await _waitForTransaction(txHash);
      await loadIngredients();
      return true;
    } catch (e) {
      _setError('原料注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadIngredients() async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔧 BlockchainProvider: 开始加载原料列表');
      
      final userAddress = _blockchainService.userAddress;
      if (userAddress == null) {
        print('🔧 BlockchainProvider: 用户地址为空');
        _ingredients = [];
        notifyListeners();
        return;
      }

      print('🔧 BlockchainProvider: 用户地址: ${userAddress.hex}');
      
      // 获取商家的原料ID列表
      final ingredientIds = await _blockchainService.getMerchantIngredients(userAddress.hex);
      print('🔧 BlockchainProvider: 原料ID列表: $ingredientIds');
      
      final ingredients = <IngredientModel>[];
      
      // 获取每个原料的详细信息
      for (final ingredientId in ingredientIds) {
        try {
          print('🔧 BlockchainProvider: 加载原料 $ingredientId');
          final ingredient = await _blockchainService.getIngredientWithSupplier(ingredientId);
          ingredients.add(ingredient);
          print('🔧 BlockchainProvider: 成功加载原料: ${ingredient.name}');
        } catch (e) {
          print('🔧 BlockchainProvider: 加载原料 $ingredientId 失败: $e');
        }
      }
      
      _ingredients = ingredients;
      print('🔧 BlockchainProvider: 总共加载了 ${_ingredients.length} 个原料');
      notifyListeners();
    } catch (e) {
      print('🔧 BlockchainProvider: 加载原料列表失败: $e');
      _setError('加载原料列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 产品相关操作
  Future<bool> createProduct({
    required String name,
    required String description,
    required String upc,
    required ProductCategory category,
    required List<int> ingredientIds,
    required String ipfsHash,
    required QualityRule qualityRule,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.createProduct(
        name: name,
        description: description,
        upc: upc,
        category: category,
        ingredientIds: ingredientIds,
        ipfsHash: ipfsHash,
        qualityRule: qualityRule,
      );

      await _waitForTransaction(txHash);
      await loadProducts();
      return true;
    } catch (e) {
      _setError('产品创建失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitProductionData({
    required int productId,
    required double temperature,
    required double humidity,
    required double weight,
    required double phValue,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.submitProductionData(
        productId: productId,
        temperature: temperature,
        humidity: humidity,
        weight: weight,
        phValue: phValue,
      );

      await _waitForTransaction(txHash);
      await loadProducts();
      return true;
    } catch (e) {
      _setError('生产数据提交失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateQRCode({
    required int productId,
    required String qrCodeHash,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.generateQRCode(
        productId: productId,
        qrCodeHash: qrCodeHash,
      );

      await _waitForTransaction(txHash);
      await loadProducts();
      return true;
    } catch (e) {
      _setError('二维码生成失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔧 BlockchainProvider: 开始加载产品列表');
      
      final userAddress = _blockchainService.userAddress;
      if (userAddress == null) {
        print('🔧 BlockchainProvider: 用户地址为空');
        _products = [];
        notifyListeners();
        return;
      }

      print('🔧 BlockchainProvider: 用户地址: ${userAddress.hex}');
      
      // 获取商家的产品ID列表
      final productIds = await _blockchainService.getMerchantProducts(userAddress.hex);
      print('🔧 BlockchainProvider: 产品ID列表: $productIds');
      
      final products = <ProductModel>[];
      
      // 获取每个产品的详细信息
      for (final productId in productIds) {
        try {
          print('🔧 BlockchainProvider: 加载产品 $productId');
          final product = await _blockchainService.getProductWithDetails(productId);
          products.add(product);
          print('🔧 BlockchainProvider: 成功加载产品: ${product.name}');
        } catch (e) {
          print('🔧 BlockchainProvider: 加载产品 $productId 失败: $e');
        }
      }
      
      _products = products;
      print('🔧 BlockchainProvider: 总共加载了 ${_products.length} 个产品');
      notifyListeners();
    } catch (e) {
      print('🔧 BlockchainProvider: 加载产品列表失败: $e');
      _setError('加载产品列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadConsumerProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔧 BlockchainProvider: 开始加载消费者注册的产品列表');
      
      final userAddress = _blockchainService.userAddress;
      if (userAddress == null) {
        print('🔧 BlockchainProvider: 用户地址为空');
        _consumerProducts = [];
        notifyListeners();
        return;
      }

      print('🔧 BlockchainProvider: 消费者地址: ${userAddress.hex}');
      
      // 获取消费者注册的产品ID列表
      final productIds = await _blockchainService.getConsumerProducts(userAddress.hex);
      print('🔧 BlockchainProvider: 消费者产品ID列表: $productIds');
      
      final products = <ProductModel>[];
      
      // 获取每个产品的详细信息
      for (final productId in productIds) {
        try {
          print('🔧 BlockchainProvider: 加载消费者产品 $productId');
          final product = await _blockchainService.getProductWithDetails(productId);
          products.add(product);
          print('🔧 BlockchainProvider: 成功加载消费者产品: ${product.name}');
        } catch (e) {
          print('🔧 BlockchainProvider: 加载消费者产品 $productId 失败: $e');
        }
      }
      
      _consumerProducts = products;
      print('🔧 BlockchainProvider: 消费者总共加载了 ${_consumerProducts.length} 个产品');
      notifyListeners();
    } catch (e) {
      print('🔧 BlockchainProvider: 加载消费者产品列表失败: $e');
      _setError('加载消费者产品列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 召回和污染相关操作
  Future<bool> markIngredientContaminated({
    required int ingredientId,
    required String reason,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.markIngredientContaminated(
        ingredientId: ingredientId,
        reason: reason,
      );

      await _waitForTransaction(txHash);
      await _handleRecallNotifications(ingredientId, reason);
      await loadIngredients();
      await loadProducts();
      return true;
    } catch (e) {
      _setError('标记污染失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> initiateRecall({
    required int ingredientId,
    required String reason,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.initiateRecall(
        ingredientId: ingredientId,
        reason: reason,
      );

      await _waitForTransaction(txHash);
      await _handleRecallNotifications(ingredientId, reason);
      await loadIngredients();
      await loadProducts();
      return true;
    } catch (e) {
      _setError('召回启动失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // 消费者相关操作
  Future<bool> registerForProductAlerts({
    required int productId,
    required String email,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.registerForProductAlerts(
        productId: productId,
        email: email,
      );

      await _waitForTransaction(txHash);
      
      // 注册成功后，重新加载消费者产品列表
      await loadConsumerProducts();
      
      return true;
    } catch (e) {
      _setError('警报注册失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitFeedback({
    required int productId,
    required String feedbackText,
    required int rating,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.submitFeedback(
        productId: productId,
        feedbackText: feedbackText,
        rating: rating,
      );

      await _waitForTransaction(txHash);
      await loadFeedbacks(UserRole.consumer); // 消费者提交反馈后重新加载
      return true;
    } catch (e) {
      _setError('反馈提交失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markFeedbackAsProcessed(int feedbackId) async {
    _setLoading(true);
    _setError(null);

    try {
      final txHash = await _blockchainService.markFeedbackAsProcessed(feedbackId);

      await _waitForTransaction(txHash);
      await loadFeedbacks(UserRole.merchant); // 商家处理反馈后重新加载
      return true;
    } catch (e) {
      _setError('标记反馈为已处理失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFeedbacks([UserRole? userRole]) async {
    _setLoading(true);
    _setError(null);

    try {
      print('🔧 BlockchainProvider: 开始加载反馈列表');
      
      final userAddress = _blockchainService.userAddress;
      if (userAddress == null) {
        print('🔧 BlockchainProvider: 用户地址为空');
        _feedbacks = [];
        notifyListeners();
        return;
      }

      print('🔧 BlockchainProvider: 用户地址: ${userAddress.hex}');
      
      List<int> feedbackIds = [];
      
      if (userRole == UserRole.consumer) {
        // 获取消费者提交的反馈ID列表
        feedbackIds = await _blockchainService.getConsumerFeedbacks(userAddress.hex);
        print('🔧 BlockchainProvider: 消费者反馈ID列表: $feedbackIds');
      } else {
        // 对于商家，获取所有产品的反馈
        final productIds = await _blockchainService.getMerchantProducts(userAddress.hex);
        print('🔧 BlockchainProvider: 商家产品ID列表: $productIds');
        
        for (final productId in productIds) {
          final productFeedbacks = await _blockchainService.getProductFeedbacks(productId);
          feedbackIds.addAll(productFeedbacks);
        }
        print('🔧 BlockchainProvider: 商家收到的反馈ID列表: $feedbackIds');
      }
      
      final feedbacks = <ConsumerFeedback>[];
      
      // 获取每个反馈的详细信息
      for (final feedbackId in feedbackIds) {
        try {
          print('🔧 BlockchainProvider: 加载反馈 $feedbackId');
          final feedback = await _blockchainService.getFeedback(feedbackId);
          feedbacks.add(feedback);
          print('🔧 BlockchainProvider: 成功加载反馈: ID $feedbackId');
        } catch (e) {
          print('🔧 BlockchainProvider: 加载反馈 $feedbackId 失败: $e');
        }
      }
      
      _feedbacks = feedbacks;
      print('🔧 BlockchainProvider: 总共加载了 ${_feedbacks.length} 个反馈');
      notifyListeners();
    } catch (e) {
      print('🔧 BlockchainProvider: 加载反馈列表失败: $e');
      _setError('加载反馈列表失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 验证产品
  Future<bool> verifyProduct(int productId) async {
    try {
      return await _blockchainService.verifyProduct(productId);
    } catch (e) {
      _setError('产品验证失败: $e');
      return false;
    }
  }

  // 根据用户地址和角色加载数据
  Future<void> loadUserData(String userAddress, [UserRole? userRole]) async {
    _setLoading(true);
    _setError(null);

    try {
      if (userRole == UserRole.consumer) {
        await Future.wait([
          loadConsumerProducts(),
          loadFeedbacks(userRole),
        ]);
      } else {
        await Future.wait([
          loadSuppliers(),
          loadIngredients(),
          loadProducts(),
          loadFeedbacks(userRole),
        ]);
      }
    } catch (e) {
      _setError('加载用户数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 刷新所有数据
  Future<void> refreshAllData([UserRole? userRole]) async {
    _setLoading(true);
    _setError(null);

    try {
      if (userRole == UserRole.consumer) {
        await Future.wait([
          loadConsumerProducts(),
          loadFeedbacks(userRole),
        ]);
      } else {
        await Future.wait([
          loadSuppliers(),
          loadIngredients(),
          loadProducts(),
          loadFeedbacks(userRole),
        ]);
      }
    } catch (e) {
      _setError('刷新数据失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 搜索功能
  List<SupplierModel> searchSuppliers(String query) {
    if (query.isEmpty) return _suppliers;
    
    return _suppliers.where((supplier) =>
        supplier.name.toLowerCase().contains(query.toLowerCase()) ||
        supplier.contactInfo.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<IngredientModel> searchIngredients(String query) {
    if (query.isEmpty) return _ingredients;
    
    return _ingredients.where((ingredient) =>
        ingredient.name.toLowerCase().contains(query.toLowerCase()) ||
        ingredient.category?.toLowerCase().contains(query.toLowerCase()) == true ||
        ingredient.upc.toLowerCase().contains(query.toLowerCase()) ||
        ingredient.batchNumber.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
        product.description.toLowerCase().contains(query.toLowerCase()) ||
        product.upc.toLowerCase().contains(query.toLowerCase()) ||
        product.category.displayName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  // 统计功能
  Map<String, int> getStatistics() {
    final totalSuppliers = _suppliers.length;
    final activeSuppliers = _suppliers.where((s) => s.isActive).length;
    final totalIngredients = _ingredients.length;
    final totalProducts = _products.length;
    final recalledIngredients = _ingredients.where((i) => i.isRecalled).length;
    final contaminatedIngredients = _ingredients.where((i) => i.isContaminated).length;
    final safeProducts = _products.where((p) => p.status == ProductStatus.safe).length;
    final alertProducts = _products.where((p) => p.status == ProductStatus.alert).length;
    final contaminatedProducts = _products.where((p) => p.status == ProductStatus.contaminated).length;
    final unreadNotifications = getUnreadNotifications().length;
    final totalFeedbacks = _feedbacks.length;
    final averageRating = _feedbacks.isEmpty 
        ? 0.0 
        : _feedbacks.map((f) => f.rating).reduce((a, b) => a + b) / _feedbacks.length;

    return {
      'totalSuppliers': totalSuppliers,
      'activeSuppliers': activeSuppliers,
      'totalIngredients': totalIngredients,
      'totalProducts': totalProducts,
      'recalledIngredients': recalledIngredients,
      'contaminatedIngredients': contaminatedIngredients,
      'safeProducts': safeProducts,
      'alertProducts': alertProducts,
      'contaminatedProducts': contaminatedProducts,
      'unreadNotifications': unreadNotifications,
      'totalFeedbacks': totalFeedbacks,
      'averageRating': averageRating.round(),
    };
  }

  // 通知管理
  void markNotificationAsRead(String notificationId) {
    final index = _recallNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _recallNotifications[index] = _recallNotifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (int i = 0; i < _recallNotifications.length; i++) {
      if (!_recallNotifications[i].isRead) {
        _recallNotifications[i] = _recallNotifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }

  // 私有辅助方法
  Future<void> _waitForTransaction(String txHash) async {
    print('🔧 BlockchainProvider: 等待交易确认: $txHash');
    
    try {
      // 使用 BlockchainService 的等待方法
      await _blockchainService.waitForTransactionReceipt(txHash);
      print('🔧 BlockchainProvider: 交易确认成功: $txHash');
    } catch (e) {
      print('🔧 BlockchainProvider: 交易确认失败: $e');
      rethrow;
    }
  }

  Future<void> _handleRecallNotifications(int ingredientId, String reason) async {
    try {
      // 获取受影响的产品
      final affectedProductIds = await _blockchainService.getAffectedProducts(ingredientId);
      
      // 创建召回通知并发送邮件通知
      for (final productId in affectedProductIds) {
        final notification = RecallNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_${productId}',
          ingredientId: ingredientId.toString(),
          productId: productId.toString(),
          reason: reason,
          timestamp: DateTime.now(),
          manufacturerAddress: _blockchainService.userAddress?.hex ?? '',
          severity: RecallSeverity.high,
        );
        _recallNotifications.add(notification);
        
        // 发送邮件通知给注册了此产品的消费者
        await _sendRecallEmailNotifications(productId, notification);
      }
      
      notifyListeners();
    } catch (e) {
      print('处理召回通知失败: $e');
    }
  }

  Future<void> _sendRecallEmailNotifications(int productId, RecallNotification notification) async {
    try {
      // 获取注册了此产品的消费者地址
      final registeredConsumers = await _blockchainService.getProductConsumers(productId);
      
      // 在实际应用中，这里应该：
      // 1. 通过消费者地址查询其设置的邮箱
      // 2. 发送邮件通知
      // 现在我们只是打印日志
      
      for (final consumerAddress in registeredConsumers) {
        print('🔧 BlockchainProvider: 应向消费者 $consumerAddress 发送召回通知邮件');
        print('🔧 BlockchainProvider: 产品ID: $productId, 原因: ${notification.reason}');
        
        // 模拟邮件发送
        await _simulateEmailNotification(consumerAddress, notification);
      }
      
      if (registeredConsumers.isNotEmpty) {
        print('🔧 BlockchainProvider: 已向 ${registeredConsumers.length} 位消费者发送召回通知');
      }
    } catch (e) {
      print('发送召回邮件通知失败: $e');
    }
  }

  Future<void> _simulateEmailNotification(String consumerAddress, RecallNotification notification) async {
    // 模拟邮件发送延迟
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 在实际应用中，这里会：
    // 1. 查询消费者的邮箱地址
    // 2. 使用邮件服务（如SendGrid, AWS SES等）发送邮件
    // 3. 记录发送状态
    
    print('📧 [模拟邮件] 发送给: $consumerAddress');
    print('📧 [模拟邮件] 主题: Product Recall Alert - Important Safety Notice');
    print('📧 [模拟邮件] 内容: A product you registered has been recalled. Reason: ${notification.reason}');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _blockchainService.dispose();
    super.dispose();
  }
}