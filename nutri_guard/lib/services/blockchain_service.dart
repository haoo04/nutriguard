import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ingredient_model.dart';
import '../models/product_model.dart';
import '../models/supplier_model.dart';
import '../models/quality_model.dart';
import '../models/feedback_model.dart';
import '../models/user_model.dart';

class BlockchainService {
  static final BlockchainService _instance = BlockchainService._internal();
  factory BlockchainService() => _instance;
  BlockchainService._internal();

  late Web3Client _client;
  late DeployedContract _contract;
  
  // Contract functions
  late ContractFunction _registerUser;
  late ContractFunction _registerSupplier;
  late ContractFunction _registerIngredient;
  late ContractFunction _createProduct;
  late ContractFunction _submitProductionData;
  late ContractFunction _generateQRCode;
  late ContractFunction _markIngredientContaminated;
  late ContractFunction _initiateRecall;
  late ContractFunction _verifyProduct;
  late ContractFunction _registerForProductAlerts;
  late ContractFunction _submitFeedback;
  
  // View functions
  late ContractFunction _getSupplierInfo;
  late ContractFunction _getIngredientInfo;
  late ContractFunction _getProductInfo;
  late ContractFunction _getProductQualityRule;
  late ContractFunction _getProductionData;
  late ContractFunction _getFeedback;

  late ContractFunction _getAffectedProducts;
  late ContractFunction _getUserRole;
  late ContractFunction _isUserRegistered;
  late ContractFunction _getMerchantSuppliers;
  late ContractFunction _getMerchantIngredients;
  late ContractFunction _getMerchantProducts;
  late ContractFunction _getConsumerProducts;
  late ContractFunction _getConsumerFeedbacks;
  late ContractFunction _getProductFeedbacks;
  late ContractFunction _markFeedbackAsProcessed;
  late ContractFunction _getProductConsumers;

  EthereumAddress? _userAddress;
  Credentials? _credentials;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('BlockchainService: already initialized, skipping');
      return;
    }

    try {
      print('BlockchainService: starting initialization...');
      // Initialize Web3 client
      final rpcUrl = AppConfig.useLocalBlockchain 
          ? AppConfig.ethereumRpcUrl 
          : AppConfig.sepoliaRpcUrl;
      
      print('BlockchainService: using RPC URL - $rpcUrl');
      _client = Web3Client(rpcUrl, http.Client());

      // Load contract ABI and address
      await _loadContract();
      
      _isInitialized = true;
      print('BlockchainService: initialization completed');
    } catch (e) {
      print('BlockchainService: initialization failed - $e');
      throw Exception('Failed to initialize blockchain service: $e');
    }
  }

  Future<void> _loadContract() async {
    try {
      print('BlockchainService: loading contract address...');
      
      // 使用AppConfig中的合约地址
      final contractAddress = AppConfig.nutriGuardContractAddress; 
      print('BlockchainService: using contract address - $contractAddress');
      
      if (contractAddress.isEmpty) {
        throw Exception('NutriGuard contract address not found');
      }

      // 完整的合约ABI - 根据新的智能合约更新
      const contractAbi = '''[
        {
          "inputs": [{"internalType": "enum NutriGuard.UserRole", "name": "_role", "type": "uint8"}],
          "name": "registerUser",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_contactInfo", "type": "string"},
            {"internalType": "string", "name": "_certifications", "type": "string"}
          ],
          "name": "registerSupplier",
          "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_category", "type": "string"},
            {"internalType": "string", "name": "_upc", "type": "string"},
            {"internalType": "uint256", "name": "_supplierId", "type": "uint256"},
            {"internalType": "uint256", "name": "_productionDate", "type": "uint256"},
            {"internalType": "uint256", "name": "_expiryDate", "type": "uint256"},
            {"internalType": "string", "name": "_batchNumber", "type": "string"},
            {"internalType": "int256", "name": "_minTemp", "type": "int256"},
            {"internalType": "int256", "name": "_maxTemp", "type": "int256"},
            {"internalType": "uint256", "name": "_minHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "_maxHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "_weight", "type": "uint256"},
            {"internalType": "string", "name": "_ipfsHash", "type": "string"}
          ],
          "name": "registerIngredient",
          "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "string", "name": "_name", "type": "string"},
            {"internalType": "string", "name": "_description", "type": "string"},
            {"internalType": "string", "name": "_upc", "type": "string"},
            {"internalType": "enum NutriGuard.ProductCategory", "name": "_category", "type": "uint8"},
            {"internalType": "uint256[]", "name": "_ingredientIds", "type": "uint256[]"},
            {"internalType": "string", "name": "_ipfsHash", "type": "string"},
            {"internalType": "int256", "name": "_minTemp", "type": "int256"},
            {"internalType": "int256", "name": "_maxTemp", "type": "int256"},
            {"internalType": "uint256", "name": "_minHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "_maxHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "_minWeight", "type": "uint256"},
            {"internalType": "uint256", "name": "_maxWeight", "type": "uint256"},
            {"internalType": "uint256", "name": "_minPH", "type": "uint256"},
            {"internalType": "uint256", "name": "_maxPH", "type": "uint256"}
          ],
          "name": "createProduct",
          "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"},
            {"internalType": "int256", "name": "_temperature", "type": "int256"},
            {"internalType": "uint256", "name": "_humidity", "type": "uint256"},
            {"internalType": "uint256", "name": "_weight", "type": "uint256"},
            {"internalType": "uint256", "name": "_phValue", "type": "uint256"}
          ],
          "name": "submitProductionData",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"},
            {"internalType": "string", "name": "_qrCodeHash", "type": "string"}
          ],
          "name": "generateQRCode",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_ingredientId", "type": "uint256"},
            {"internalType": "string", "name": "_reason", "type": "string"}
          ],
          "name": "markIngredientContaminated",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_ingredientId", "type": "uint256"},
            {"internalType": "string", "name": "_reason", "type": "string"}
          ],
          "name": "initiateRecall",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "verifyProduct",
          "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"},
            {"internalType": "string", "name": "_email", "type": "string"}
          ],
          "name": "registerForProductAlerts",
          "outputs": [],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [
            {"internalType": "uint256", "name": "_productId", "type": "uint256"},
            {"internalType": "string", "name": "_feedbackText", "type": "string"},
            {"internalType": "uint256", "name": "_rating", "type": "uint256"}
          ],
          "name": "submitFeedback",
          "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
          "stateMutability": "nonpayable",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_supplierId", "type": "uint256"}],
          "name": "getSupplierInfo",
          "outputs": [
            {"internalType": "uint256", "name": "id", "type": "uint256"},
            {"internalType": "string", "name": "name", "type": "string"},
            {"internalType": "string", "name": "contactInfo", "type": "string"},
            {"internalType": "address", "name": "merchant", "type": "address"},
            {"internalType": "uint256", "name": "createdAt", "type": "uint256"},
            {"internalType": "bool", "name": "isActive", "type": "bool"},
            {"internalType": "string", "name": "certifications", "type": "string"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_ingredientId", "type": "uint256"}],
          "name": "getIngredientInfo",
          "outputs": [
            {"internalType": "uint256", "name": "id", "type": "uint256"},
            {"internalType": "string", "name": "name", "type": "string"},
            {"internalType": "string", "name": "category", "type": "string"},
            {"internalType": "string", "name": "upc", "type": "string"},
            {"internalType": "uint256", "name": "supplierId", "type": "uint256"},
            {"internalType": "address", "name": "merchant", "type": "address"},
            {"internalType": "uint256", "name": "createdAt", "type": "uint256"},
            {"internalType": "uint256", "name": "productionDate", "type": "uint256"},
            {"internalType": "uint256", "name": "expiryDate", "type": "uint256"},
            {"internalType": "string", "name": "batchNumber", "type": "string"},
            {"internalType": "bool", "name": "isRecalled", "type": "bool"},
            {"internalType": "bool", "name": "isContaminated", "type": "bool"},
            {"internalType": "int256", "name": "minTemp", "type": "int256"},
            {"internalType": "int256", "name": "maxTemp", "type": "int256"},
            {"internalType": "uint256", "name": "minHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "maxHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "weight", "type": "uint256"},
            {"internalType": "string", "name": "ipfsHash", "type": "string"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "getProductInfo",
          "outputs": [
            {"internalType": "uint256", "name": "id", "type": "uint256"},
            {"internalType": "string", "name": "name", "type": "string"},
            {"internalType": "string", "name": "description", "type": "string"},
            {"internalType": "string", "name": "upc", "type": "string"},
            {"internalType": "enum NutriGuard.ProductCategory", "name": "category", "type": "uint8"},
            {"internalType": "enum NutriGuard.ProductStatus", "name": "status", "type": "uint8"},
            {"internalType": "address", "name": "merchant", "type": "address"},
            {"internalType": "uint256[]", "name": "ingredientIds", "type": "uint256[]"},
            {"internalType": "uint256", "name": "createdAt", "type": "uint256"},
            {"internalType": "uint256", "name": "productionDate", "type": "uint256"},
            {"internalType": "bool", "name": "isValid", "type": "bool"},
            {"internalType": "bool", "name": "canGenerateQR", "type": "bool"},
            {"internalType": "string", "name": "qrCodeHash", "type": "string"},
            {"internalType": "string", "name": "ipfsHash", "type": "string"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "getProductQualityRule",
          "outputs": [
            {"internalType": "int256", "name": "minTemperature", "type": "int256"},
            {"internalType": "int256", "name": "maxTemperature", "type": "int256"},
            {"internalType": "uint256", "name": "minHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "maxHumidity", "type": "uint256"},
            {"internalType": "uint256", "name": "minWeight", "type": "uint256"},
            {"internalType": "uint256", "name": "maxWeight", "type": "uint256"},
            {"internalType": "uint256", "name": "minPH", "type": "uint256"},
            {"internalType": "uint256", "name": "maxPH", "type": "uint256"},
            {"internalType": "bool", "name": "isActive", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "getProductionData",
          "outputs": [
            {"internalType": "int256", "name": "temperature", "type": "int256"},
            {"internalType": "uint256", "name": "humidity", "type": "uint256"},
            {"internalType": "uint256", "name": "weight", "type": "uint256"},
            {"internalType": "uint256", "name": "phValue", "type": "uint256"},
            {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"internalType": "bool", "name": "isCompliant", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_feedbackId", "type": "uint256"}],
          "name": "getFeedback",
          "outputs": [
            {"internalType": "uint256", "name": "id", "type": "uint256"},
            {"internalType": "uint256", "name": "productId", "type": "uint256"},
            {"internalType": "address", "name": "consumer", "type": "address"},
            {"internalType": "string", "name": "feedbackText", "type": "string"},
            {"internalType": "uint256", "name": "rating", "type": "uint256"},
            {"internalType": "uint256", "name": "timestamp", "type": "uint256"},
            {"internalType": "bool", "name": "isProcessed", "type": "bool"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "getProductConsumers",
          "outputs": [
            {"internalType": "address[]", "name": "consumers", "type": "address[]"},
            {"internalType": "string[]", "name": "emails", "type": "string[]"},
            {"internalType": "uint256[]", "name": "registeredTimes", "type": "uint256[]"}
          ],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_ingredientId", "type": "uint256"}],
          "name": "getAffectedProducts",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_user", "type": "address"}],
          "name": "getUserRole",
          "outputs": [{"internalType": "enum NutriGuard.UserRole", "name": "", "type": "uint8"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_user", "type": "address"}],
          "name": "isUserRegistered",
          "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_merchant", "type": "address"}],
          "name": "getMerchantSuppliers",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_merchant", "type": "address"}],
          "name": "getMerchantIngredients",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_merchant", "type": "address"}],
          "name": "getMerchantProducts",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_consumer", "type": "address"}],
          "name": "getConsumerProducts",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "address", "name": "_consumer", "type": "address"}],
          "name": "getConsumerFeedbacks",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_productId", "type": "uint256"}],
          "name": "getProductFeedbacks",
          "outputs": [{"internalType": "uint256[]", "name": "", "type": "uint256[]"}],
          "stateMutability": "view",
          "type": "function"
        },
        {
          "inputs": [{"internalType": "uint256", "name": "_feedbackId", "type": "uint256"}],
          "name": "markFeedbackAsProcessed",
          "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
          "stateMutability": "nonpayable",
          "type": "function"
        }
      ]''';

      _contract = DeployedContract(
        ContractAbi.fromJson(contractAbi, 'NutriGuard'),
        EthereumAddress.fromHex(contractAddress),
      );

      // Initialize contract functions
      _registerUser = _contract.function('registerUser');
      _registerSupplier = _contract.function('registerSupplier');
      _registerIngredient = _contract.function('registerIngredient');
      _createProduct = _contract.function('createProduct');
      _submitProductionData = _contract.function('submitProductionData');
      _generateQRCode = _contract.function('generateQRCode');
      _markIngredientContaminated = _contract.function('markIngredientContaminated');
      _initiateRecall = _contract.function('initiateRecall');
      _verifyProduct = _contract.function('verifyProduct');
      _registerForProductAlerts = _contract.function('registerForProductAlerts');
      _submitFeedback = _contract.function('submitFeedback');

      // View functions
      _getSupplierInfo = _contract.function('getSupplierInfo');
      _getIngredientInfo = _contract.function('getIngredientInfo');
      _getProductInfo = _contract.function('getProductInfo');
      _getProductQualityRule = _contract.function('getProductQualityRule');
      _getProductionData = _contract.function('getProductionData');
      _getFeedback = _contract.function('getFeedback');

      _getAffectedProducts = _contract.function('getAffectedProducts');
      _getUserRole = _contract.function('getUserRole');
      _isUserRegistered = _contract.function('isUserRegistered');
      _getMerchantSuppliers = _contract.function('getMerchantSuppliers');
      _getMerchantIngredients = _contract.function('getMerchantIngredients');
      _getMerchantProducts = _contract.function('getMerchantProducts');
      _getConsumerProducts = _contract.function('getConsumerProducts');
      _getConsumerFeedbacks = _contract.function('getConsumerFeedbacks');
      _getProductFeedbacks = _contract.function('getProductFeedbacks');
      _markFeedbackAsProcessed = _contract.function('markFeedbackAsProcessed');
      _getProductConsumers = _contract.function('getProductConsumers');
      
      print('BlockchainService: contract functions initialized');
      
      // 测试区块链连接
      try {
        final blockNumber = await _client.getBlockNumber();
        print('BlockchainService: connected successfully, current block number: $blockNumber');
      } catch (e) {
        print('BlockchainService: connection test failed - $e');
        throw Exception('Failed to connect to blockchain: $e');
      }

    } catch (e) {
      throw Exception('Failed to load contract: $e');
    }
  }

  void setCredentials(Credentials credentials) {
    _credentials = credentials;
    _userAddress = credentials.address;
  }

  EthereumAddress? get userAddress => _userAddress;

  // User registration
  Future<String> registerUser(UserRole role) async {
    if (_credentials == null) throw Exception('No credentials set');

    print('🔧 BlockchainService: Registering user with role: ${role.name}');
    print('🔧 BlockchainService: User address: ${_credentials!.address}');
    print('🔧 BlockchainService: Role index: ${role.index}');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _registerUser,
      parameters: [BigInt.from(role.index)],
    );

    print('🔧 BlockchainService: Sending registerUser transaction...');
    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    print('🔧 BlockchainService: RegisterUser transaction sent, hash: $txHash');
    
    // Wait for transaction to be mined
    await waitForTransactionReceipt(txHash);
    print('🔧 BlockchainService: RegisterUser transaction confirmed');

    return txHash;
  }

  // Helper method to wait for transaction receipt
  Future<void> waitForTransactionReceipt(String txHash) async {
    print('🔧 BlockchainService: Waiting for transaction receipt: $txHash');
    int attempts = 0;
    const maxAttempts = 30;
    
    while (attempts < maxAttempts) {
      try {
        final receipt = await _client.getTransactionReceipt(txHash);
        if (receipt != null) {
          print('🔧 BlockchainService: Transaction confirmed in block ${receipt.blockNumber}');
          if (receipt.status != null && !receipt.status!) {
            throw Exception('Transaction failed');
          }
          return;
        }
      } catch (e) {
        if (e.toString().contains('Transaction failed')) {
          rethrow;
        }
        // Continue waiting for other errors
      }
      
      attempts++;
      await Future.delayed(const Duration(seconds: 2));
    }
    
    throw Exception('Transaction confirmation timeout');
  }

  // Supplier functions
  Future<String> registerSupplier({
    required String name,
    required String contactInfo,
    required String certifications,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    print('🔧 BlockchainService: Registering supplier...');
    print('🔧 BlockchainService: Caller address: ${_credentials!.address}');
    print('🔧 BlockchainService: Supplier name: $name');
    
    // First check if user is registered and is merchant
    try {
      final isRegistered = await isUserRegistered(_credentials!.address.hex);
      print('🔧 BlockchainService: User is registered: $isRegistered');
      
      if (isRegistered) {
        final userRole = await getUserRole(_credentials!.address.hex);
        print('🔧 BlockchainService: User role: ${userRole.name}');
      }
    } catch (e) {
      print('🔧 BlockchainService: Error checking user status: $e');
    }

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _registerSupplier,
      parameters: [name, contactInfo, certifications],
    );

    print('🔧 BlockchainService: Sending registerSupplier transaction...');
    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    print('🔧 BlockchainService: RegisterSupplier transaction sent, hash: $txHash');
    
    // Wait for transaction to be mined
    await waitForTransactionReceipt(txHash);
    print('🔧 BlockchainService: RegisterSupplier transaction confirmed');

    return txHash;
  }

  // Ingredient functions
  Future<String> registerIngredient({
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
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _registerIngredient,
      parameters: [
        name,
        category,
        upc,
        BigInt.from(supplierId),
        BigInt.from(productionDate.millisecondsSinceEpoch ~/ 1000),
        BigInt.from(expiryDate.millisecondsSinceEpoch ~/ 1000),
        batchNumber,
        BigInt.from(minTemperature.round()),
        BigInt.from(maxTemperature.round()),
        BigInt.from(minHumidity.round()),
        BigInt.from(maxHumidity.round()),
        BigInt.from(weight.round()),
        ipfsHash,
      ],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  // Product functions
  Future<String> createProduct({
    required String name,
    required String description,
    required String upc,
    required ProductCategory category,
    required List<int> ingredientIds,
    required String ipfsHash,
    required QualityRule qualityRule,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _createProduct,
      parameters: [
        name,
        description,
        upc,
        BigInt.from(category.index),
        ingredientIds.map((id) => BigInt.from(id)).toList(),
        ipfsHash,
        BigInt.from(qualityRule.minTemperature.round()),
        BigInt.from(qualityRule.maxTemperature.round()),
        BigInt.from(qualityRule.minHumidity.round()),
        BigInt.from(qualityRule.maxHumidity.round()),
        BigInt.from(qualityRule.minWeight.round()),
        BigInt.from(qualityRule.maxWeight.round()),
        BigInt.from((qualityRule.minPH * 100).round()),
        BigInt.from((qualityRule.maxPH * 100).round()),
      ],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<String> submitProductionData({
    required int productId,
    required double temperature,
    required double humidity,
    required double weight,
    required double phValue,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _submitProductionData,
      parameters: [
        BigInt.from(productId),
        BigInt.from(temperature.round()),
        BigInt.from(humidity.round()),
        BigInt.from(weight.round()),
        BigInt.from((phValue * 100).round()),
      ],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<String> generateQRCode({
    required int productId,
    required String qrCodeHash,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _generateQRCode,
      parameters: [BigInt.from(productId), qrCodeHash],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<String> markIngredientContaminated({
    required int ingredientId,
    required String reason,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _markIngredientContaminated,
      parameters: [BigInt.from(ingredientId), reason],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<String> initiateRecall({
    required int ingredientId,
    required String reason,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _initiateRecall,
      parameters: [BigInt.from(ingredientId), reason],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<bool> verifyProduct(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _verifyProduct,
      params: [BigInt.from(productId)],
    );

    return result.first as bool;
  }

  // Consumer functions
  Future<String> registerForProductAlerts({
    required int productId,
    required String email,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _registerForProductAlerts,
      parameters: [BigInt.from(productId), email],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  Future<String> submitFeedback({
    required int productId,
    required String feedbackText,
    required int rating,
  }) async {
    if (_credentials == null) throw Exception('No credentials set');

    final transaction = Transaction.callContract(
      contract: _contract,
      function: _submitFeedback,
      parameters: [
        BigInt.from(productId),
        feedbackText,
        BigInt.from(rating),
      ],
    );

    final txHash = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: int.parse(AppConfig.ethereumChainId),
    );

    return txHash;
  }

  // View functions
  Future<SupplierModel> getSupplierInfo(int supplierId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getSupplierInfo,
      params: [BigInt.from(supplierId)],
    );

    return SupplierModel.fromBlockchain(result);
  }

  Future<IngredientModel> getIngredientInfo(int ingredientId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getIngredientInfo,
      params: [BigInt.from(ingredientId)],
    );

    return IngredientModel.fromBlockchain(result);
  }

  Future<ProductModel> getProductInfo(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductInfo,
      params: [BigInt.from(productId)],
    );

    return ProductModel.fromBlockchain(result);
  }

  Future<QualityRule> getProductQualityRule(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductQualityRule,
      params: [BigInt.from(productId)],
    );

    return QualityRule.fromBlockchain(result);
  }

  Future<ProductionData> getProductionData(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductionData,
      params: [BigInt.from(productId)],
    );

    return ProductionData.fromBlockchain(result);
  }

  Future<ConsumerFeedback> getFeedback(int feedbackId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getFeedback,
      params: [BigInt.from(feedbackId)],
    );

    return ConsumerFeedback.fromBlockchain(result);
  }

  Future<List<int>> getAffectedProducts(int ingredientId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getAffectedProducts,
      params: [BigInt.from(ingredientId)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<UserRole> getUserRole(String address) async {
    final result = await _client.call(
      contract: _contract,
      function: _getUserRole,
      params: [EthereumAddress.fromHex(address)],
    );

    return UserRole.values[result.first.toInt()];
  }

  Future<bool> isUserRegistered(String address) async {
    final result = await _client.call(
      contract: _contract,
      function: _isUserRegistered,
      params: [EthereumAddress.fromHex(address)],
    );

    return result.first as bool;
  }

  Future<List<int>> getMerchantSuppliers(String merchantAddress) async {
    final result = await _client.call(
      contract: _contract,
      function: _getMerchantSuppliers,
      params: [EthereumAddress.fromHex(merchantAddress)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<List<int>> getMerchantIngredients(String merchantAddress) async {
    final result = await _client.call(
      contract: _contract,
      function: _getMerchantIngredients,
      params: [EthereumAddress.fromHex(merchantAddress)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<List<int>> getMerchantProducts(String merchantAddress) async {
    final result = await _client.call(
      contract: _contract,
      function: _getMerchantProducts,
      params: [EthereumAddress.fromHex(merchantAddress)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<List<int>> getConsumerProducts(String consumerAddress) async {
    final result = await _client.call(
      contract: _contract,
      function: _getConsumerProducts,
      params: [EthereumAddress.fromHex(consumerAddress)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<List<int>> getConsumerFeedbacks(String consumerAddress) async {
    final result = await _client.call(
      contract: _contract,
      function: _getConsumerFeedbacks,
      params: [EthereumAddress.fromHex(consumerAddress)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<List<int>> getProductFeedbacks(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductFeedbacks,
      params: [BigInt.from(productId)],
    );

    return (result.first as List).map((e) => (e as BigInt).toInt()).toList();
  }

  Future<String> markFeedbackAsProcessed(int feedbackId) async {
    final transaction = Transaction.callContract(
      contract: _contract,
      function: _markFeedbackAsProcessed,
      parameters: [BigInt.from(feedbackId)],
    );

    final result = await _client.sendTransaction(
      _credentials!,
      transaction,
      chainId: 1337,
    );

    return result;
  }

  // Helper function to get product with full details
  Future<ProductModel> getProductWithDetails(int productId) async {
    final product = await getProductInfo(productId);
    
    try {
      final qualityRule = await getProductQualityRule(productId);
      final productionData = await getProductionData(productId);
      
      return product.copyWith(
        qualityRule: qualityRule,
        productionData: productionData,
      );
    } catch (e) {
      print('Error getting product details: $e');
      return product;
    }
  }

  // Helper function to get ingredient with supplier info
  Future<IngredientModel> getIngredientWithSupplier(int ingredientId) async {
    final ingredient = await getIngredientInfo(ingredientId);
    return ingredient;
  }

  Future<List<String>> getProductConsumers(int productId) async {
    final result = await _client.call(
      contract: _contract,
      function: _getProductConsumers,
      params: [BigInt.from(productId)],
    );

    // The result contains [addresses[], emails[], timestamps[]]
    // We only need the addresses for now
    final addresses = result[0] as List;
    return addresses.map((address) => address.toString()).toList();
  }

  // Dispose method
  void dispose() {
    _client.dispose();
  }
}