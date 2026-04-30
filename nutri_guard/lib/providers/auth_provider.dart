import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/blockchain_service.dart';
import '../models/wallet_model.dart' as wallet;
import '../config/app_config.dart';
import 'package:web3dart/web3dart.dart';

class AuthProvider extends ChangeNotifier {
  final BlockchainService _blockchainService = BlockchainService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 公开钱包服务以便UI访问
  // EnhancedWalletService get walletService => _walletService; // No longer needed

  Future<void> initialize() async {
    _setLoading(true);
    try {
      // await _walletService.initialize(); // No longer needed
      await _blockchainService.initialize();
      
      // 检查是否有已连接的钱包 - This logic is no longer relevant for preset accounts
      // if (_walletService.isConnected) {
      //   await _loadUserFromWallet();
      // }
    } catch (e) {
      _setError('初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithPresetAccount(wallet.UserRole userRole) async {
    print('开始使用预设账户登录...');
    _setLoading(true);
    _setError(null);

    try {
      await _blockchainService.initialize();

      final roleKey = userRole == wallet.UserRole.consumer ? 'consumer' : 'merchant';
      final account = AppConfig.presetAccounts[roleKey]!;
      final address = account['address']!;
      final privateKey = account['privateKey']!;

      print('使用账户: $roleKey, 地址: $address');

      // 设置区块链服务的凭证
      final credentials = EthPrivateKey.fromHex(privateKey);
      _blockchainService.setCredentials(credentials);
      
      // 创建或加载用户
      await _createOrLoadUser(address, userRole);
      
      print('预设账户登录成功');
    } catch (e) {
      print('预设账户登录失败: $e');
      _setError('登录失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createOrLoadUser(String walletAddress, wallet.UserRole userRole) async {
    // 在实际应用中，这里应该从Firebase或其他数据库加载用户数据
    // 现在我们创建一个模拟用户
    _currentUser = UserModel(
      id: walletAddress.toLowerCase(),
      walletAddress: walletAddress,
      role: _mapUserRole(userRole),
      isVerified: true,
      createdAt: DateTime.now(),
      displayName: '${_getRoleDisplayName(userRole)} ${walletAddress.substring(0, 6)}...',
    );
    
    // 在区块链上注册用户（如果还未注册）
    try {
      final blockchainUserRole = userRole == wallet.UserRole.merchant 
          ? UserRole.merchant 
          : UserRole.consumer;
      
      print('🔧 AuthProvider: 开始检查区块链用户注册状态');
      print('🔧 AuthProvider: 钱包地址: $walletAddress');
      print('🔧 AuthProvider: 用户角色: ${blockchainUserRole.name}');
      
      // 检查用户是否已在区块链上注册
      final isRegistered = await _blockchainService.isUserRegistered(walletAddress);
      print('🔧 AuthProvider: 用户已注册: $isRegistered');
      
      if (!isRegistered) {
        print('🔧 AuthProvider: 在区块链上注册用户: $walletAddress as ${blockchainUserRole.name}');
        final txHash = await _blockchainService.registerUser(blockchainUserRole);
        print('🔧 AuthProvider: 用户注册交易哈希: $txHash');
        print('🔧 AuthProvider: 用户注册成功');
        
        // Double check registration after transaction
        final isNowRegistered = await _blockchainService.isUserRegistered(walletAddress);
        print('🔧 AuthProvider: 注册后验证 - 用户已注册: $isNowRegistered');
        
        if (isNowRegistered) {
          final actualRole = await _blockchainService.getUserRole(walletAddress);
          print('🔧 AuthProvider: 注册后验证 - 用户实际角色: ${actualRole.name}');
        }
      } else {
        print('🔧 AuthProvider: 用户已在区块链上注册');
        try {
          final existingRole = await _blockchainService.getUserRole(walletAddress);
          print('🔧 AuthProvider: 现有用户角色: ${existingRole.name}');
        } catch (e) {
          print('🔧 AuthProvider: 获取现有用户角色失败: $e');
        }
      }
    } catch (e) {
      print('🔧 AuthProvider: 区块链用户注册失败: $e');
      print('🔧 AuthProvider: 错误详情: ${e.toString()}');
      // 不抛出异常，让用户可以继续使用应用
      _setError('区块链用户注册失败: $e');
    }
    
    _notifyIfAlive();
  }

  UserRole _mapUserRole(wallet.UserRole walletRole) {
    switch (walletRole) {
      case wallet.UserRole.merchant:
        return UserRole.merchant;
      case wallet.UserRole.consumer:
        return UserRole.consumer;
    }
  }

  String _getRoleDisplayName(wallet.UserRole role) {
    switch (role) {
      case wallet.UserRole.merchant:
        return 'Merchant';
      case wallet.UserRole.consumer:
        return 'Consumer';
    }
  }

  Future<void> updateUserEmail(String? email) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    try {
      // 更新用户邮箱
      _currentUser = _currentUser!.copyWith(email: email);
      _notifyIfAlive();
      
      // 在实际应用中，这里应该同步到后端数据库
      print('🔧 AuthProvider: 用户邮箱已更新: $email');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      // await _walletService.disconnect(); // No longer needed
      _currentUser = null;
      _setError(null);
    } catch (e) {
      _setError('登出失败: $e');
    } finally {
      _setLoading(false);
    }
  }



  Future<String?> signMessage(String message) async {
    try {
      if (_currentUser == null) {
        _setError('用户未登录');
        return null;
      }

      // 获取当前用户对应的私钥
      final userRole = _currentUser!.role == UserRole.merchant ? 'merchant' : 'consumer';
      final account = AppConfig.presetAccounts[userRole];
      
      if (account == null) {
        _setError('找不到用户账户信息');
        return null;
      }

      final privateKeyHex = account['privateKey']!;
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      
      // 使用私钥签名消息（web3dart会自动处理以太坊消息格式）
      final signature = await credentials.signPersonalMessage(utf8.encode(message));
      
      // 将签名转换为十六进制字符串格式
      final signatureHex = '0x${signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      
      print('消息签名成功: ${signatureHex.substring(0, 10)}...');
      return signatureHex;
    } catch (e) {
      print('消息签名失败: $e');
      _setError('消息签名失败: $e');
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyIfAlive();
  }

  void _setError(String? error) {
    _error = error;
    _notifyIfAlive();
  }

  void _notifyIfAlive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // _walletService.dispose(); // No longer needed
    _blockchainService.dispose();
    super.dispose();
  }
}



