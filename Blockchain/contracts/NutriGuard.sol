// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NutriGuard is Ownable, ReentrancyGuard {
    // 用户角色枚举
    enum UserRole { Consumer, Merchant }
    
    // 产品类别枚举
    enum ProductCategory { MainFood, Snack, Beverage }
    
    // 产品状态枚举
    enum ProductStatus { Safe, Alert, Contaminated }
    
    // 事件定义
    event SupplierRegistered(uint256 indexed supplierId, address indexed merchant, string name);
    event IngredientRegistered(uint256 indexed ingredientId, address indexed merchant, string name, string upc);
    event ProductCreated(uint256 indexed productId, address indexed merchant, uint256[] ingredientIds);
    event ProductionDataSubmitted(uint256 indexed productId, address indexed merchant, bool compliant);
    event QRCodeGenerated(uint256 indexed productId, string qrCodeHash);
    event RecallInitiated(uint256 indexed ingredientId, string reason, uint256 timestamp);
    event ProductVerified(uint256 indexed productId, address indexed verifier, uint256 timestamp);
    event ConsumerFeedbackSubmitted(uint256 indexed feedbackId, uint256 indexed productId, address indexed consumer);
    event ConsumerRegistered(uint256 indexed productId, address indexed consumer, string email);
    event AlertEmailSent(uint256 indexed productId, address indexed consumer, string reason);
    
    // 供应商结构体
    struct Supplier {
        uint256 id;
        string name;           // 供应商名称
        string contactInfo;    // 联系信息
        address merchant;      // 注册该供应商的商家
        uint256 createdAt;     // 创建时间
        bool isActive;         // 是否活跃
        string certifications; // 认证信息
    }
    
    // HACCP质量控制规则结构体
    struct QualityRule {
        int256 minTemperature;  // 最低加热温度 (摄氏度)
        int256 maxTemperature;  // 最高加热温度 (摄氏度)
        uint256 minHumidity;    // 最低湿度 (%)
        uint256 maxHumidity;    // 最高湿度 (%)
        uint256 minWeight;      // 最低使用重量 (克)
        uint256 maxWeight;      // 最高使用重量 (克)
        uint256 minPH;          // 最低pH值 (乘以100，如7.5存储为750)
        uint256 maxPH;          // 最高pH值 (乘以100)
        bool isActive;          // 规则是否激活
    }
    
    // 生产数据结构体
    struct ProductionData {
        int256 temperature;     // 实际温度
        uint256 humidity;       // 实际湿度
        uint256 weight;         // 实际使用重量
        uint256 phValue;        // 实际pH值
        uint256 timestamp;      // 数据提交时间
        bool isCompliant;       // 是否符合规则
    }
    
    // 储存环境结构体
    struct StorageEnvironment {
        int256 minTemperature; // 最低温度 (摄氏度)
        int256 maxTemperature; // 最高温度 (摄氏度)
        uint256 minHumidity;   // 最低湿度 (%)
        uint256 maxHumidity;   // 最高湿度 (%)
    }
    
    // 原料结构体
    struct Ingredient {
        uint256 id;
        string name;           // 原料名称 (必须)
        string category;       // 种类
        string upc;            // 通用产品代码
        uint256 supplierId;    // 供应商ID
        address merchant;      // 商家地址
        uint256 createdAt;     // 创建时间
        uint256 productionDate; // 生产日期
        uint256 expiryDate;    // 保质期 (时间戳)
        string batchNumber;    // 材料批次
        bool isRecalled;       // 是否被召回
        bool isContaminated;   // 是否被污染
        StorageEnvironment storageEnv; // 储存环境范围
        uint256 weight;        // 重量 (克)
        string ipfsHash;       // IPFS存储哈希
    }
    
    // 产品结构体
    struct Product {
        uint256 id;
        string name;              // 产品名称 (必须)
        string description;       // 产品描述
        string upc;              // 通用产品代码
        ProductCategory category; // 种类 (主食，小食，饮料)
        ProductStatus status;     // 产品状态
        address merchant;         // 商家地址
        uint256[] ingredientIds;  // 使用到的原料
        uint256 createdAt;        // 创建时间
        uint256 productionDate;   // 生产日期
        bool isValid;            // 是否有效
        bool canGenerateQR;      // 是否可以生成二维码
        string qrCodeHash;       // QR码哈希
        string ipfsHash;         // IPFS存储哈希（产品图片和证书）
        QualityRule qualityRule; // 质量控制规则
        ProductionData productionData; // 生产数据
    }
    
    // 消费者反馈结构体
    struct ConsumerFeedback {
        uint256 id;
        uint256 productId;      // 关联产品ID
        address consumer;       // 消费者地址
        string feedbackText;    // 反馈内容
        uint256 rating;         // 评分 (1-5)
        uint256 timestamp;      // 提交时间
        bool isProcessed;       // 是否已处理
    }
    
    // 消费者注册结构体
    struct ConsumerRegistration {
        address consumer;       // 消费者地址
        uint256 productId;      // 产品ID
        string email;           // 邮箱地址
        uint256 registeredAt;   // 注册时间
        bool isActive;          // 是否活跃
    }
    
    // 状态变量
    mapping(uint256 => Supplier) public suppliers;
    mapping(uint256 => Ingredient) public ingredients;
    mapping(uint256 => Product) public products;
    mapping(uint256 => ConsumerFeedback) public feedbacks;
    mapping(address => UserRole) public userRoles;
    mapping(address => bool) public registeredUsers;
    mapping(uint256 => ConsumerRegistration[]) public productConsumerRegistrations; // 产品ID -> 消费者注册列表
    mapping(address => mapping(uint256 => bool)) public consumerProductRegistered; // 消费者 -> 产品ID -> 是否已注册
    
    uint256 public supplierCounter;
    uint256 public ingredientCounter;
    uint256 public productCounter;
    uint256 public feedbackCounter;
    
    // 修饰符
    //modifier onlyMerchant() {
    //    require(registeredUsers[msg.sender] && userRoles[msg.sender] == UserRole.Merchant, "Only merchants allowed");
    //    _;
    //}
    
    //modifier onlyConsumer() {
    //    require(registeredUsers[msg.sender] && userRoles[msg.sender] == UserRole.Consumer, "Only consumers allowed");
    //    _;
    //}
    
    modifier supplierExists(uint256 _supplierId) {
        require(_supplierId > 0 && _supplierId <= supplierCounter, "Supplier does not exist");
        _;
    }
    
    modifier ingredientExists(uint256 _ingredientId) {
        require(_ingredientId > 0 && _ingredientId <= ingredientCounter, "Ingredient does not exist");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(_productId > 0 && _productId <= productCounter, "Product does not exist");
        _;
    }
    
    constructor() Ownable(msg.sender) {
        // 构造函数保持简单
    }
    
    // 用户注册
    function registerUser(UserRole _role) external {
        require(!registeredUsers[msg.sender], "User already registered");
        userRoles[msg.sender] = _role;
        registeredUsers[msg.sender] = true;
    }
    
    // 供应商注册 (仅商家)
    function registerSupplier(
        string memory _name,
        string memory _contactInfo,
        string memory _certifications
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Name is required");
        
        supplierCounter++;
        uint256 supplierId = supplierCounter;
        
        suppliers[supplierId] = Supplier({
            id: supplierId,
            name: _name,
            contactInfo: _contactInfo,
            merchant: msg.sender,
            createdAt: block.timestamp,
            isActive: true,
            certifications: _certifications
        });
        
        emit SupplierRegistered(supplierId, msg.sender, _name);
        return supplierId;
    }
    
    // 原料注册 (仅商家)
    function registerIngredient(
        string memory _name,
        string memory _category,
        string memory _upc,
        uint256 _supplierId,
        uint256 _productionDate,
        uint256 _expiryDate,
        string memory _batchNumber,
        int256 _minTemp,
        int256 _maxTemp,
        uint256 _minHumidity,
        uint256 _maxHumidity,
        uint256 _weight,
        string memory _ipfsHash
    ) external supplierExists(_supplierId) returns (uint256) {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_upc).length > 0, "UPC is required");
        require(suppliers[_supplierId].merchant == msg.sender, "Can only use own suppliers");
        require(_minTemp <= _maxTemp, "Invalid temperature range");
        require(_minHumidity <= _maxHumidity, "Invalid humidity range");
        require(_weight > 0, "Weight must be greater than 0");
        require(_expiryDate > block.timestamp, "Expiry date must be in the future");
        require(_productionDate <= block.timestamp, "Production date cannot be in the future");
        
        ingredientCounter++;
        uint256 ingredientId = ingredientCounter;
        
        Ingredient storage ingredient = ingredients[ingredientId];
        ingredient.id = ingredientId;
        ingredient.name = _name;
        ingredient.category = _category;
        ingredient.upc = _upc;
        ingredient.supplierId = _supplierId;
        ingredient.merchant = msg.sender;
        ingredient.createdAt = block.timestamp;
        ingredient.productionDate = _productionDate;
        ingredient.expiryDate = _expiryDate;
        ingredient.batchNumber = _batchNumber;
        ingredient.isRecalled = false;
        ingredient.isContaminated = false;
        ingredient.storageEnv = StorageEnvironment({
            minTemperature: _minTemp,
            maxTemperature: _maxTemp,
            minHumidity: _minHumidity,
            maxHumidity: _maxHumidity
        });
        ingredient.weight = _weight;
        ingredient.ipfsHash = _ipfsHash;
        
        emit IngredientRegistered(ingredientId, msg.sender, _name, _upc);
        return ingredientId;
    }
    
    // 产品创建 (仅商家)
    function createProduct(
        string memory _name,
        string memory _description,
        string memory _upc,
        ProductCategory _category,
        uint256[] memory _ingredientIds,
        string memory _ipfsHash,
        // HACCP质量控制规则参数
        int256 _minTemp,
        int256 _maxTemp,
        uint256 _minHumidity,
        uint256 _maxHumidity,
        uint256 _minWeight,
        uint256 _maxWeight,
        uint256 _minPH,
        uint256 _maxPH
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_upc).length > 0, "UPC is required");
        require(_ingredientIds.length > 0, "Product must have at least one ingredient");
        
        // 验证所有原料都存在且未召回，且属于当前商家
        for (uint256 i = 0; i < _ingredientIds.length; i++) {
            require(_ingredientIds[i] <= ingredientCounter, "Invalid ingredient ID");
            require(!ingredients[_ingredientIds[i]].isRecalled, "Cannot use recalled ingredient");
            require(!ingredients[_ingredientIds[i]].isContaminated, "Cannot use contaminated ingredient");
            require(ingredients[_ingredientIds[i]].merchant == msg.sender, "Can only use own ingredients");
        }
        
        // 验证质量控制规则参数
        require(_minTemp <= _maxTemp, "Invalid temperature range");
        require(_minHumidity <= _maxHumidity, "Invalid humidity range");
        require(_minWeight <= _maxWeight, "Invalid weight range");
        if (_category == ProductCategory.Beverage) {
            require(_minPH <= _maxPH, "Invalid pH range");
            require(_maxPH <= 1400, "pH value too high"); // 14.00的上限
        }
        
        productCounter++;
        uint256 productId = productCounter;
        
        products[productId] = Product({
            id: productId,
            name: _name,
            description: _description,
            upc: _upc,
            category: _category,
            status: ProductStatus.Safe,
            merchant: msg.sender,
            ingredientIds: _ingredientIds,
            createdAt: block.timestamp,
            productionDate: 0, // 将在提交生产数据时设置
            isValid: true,
            canGenerateQR: false, // 初始不能生成QR码，需要先通过生产验证
            qrCodeHash: "",
            ipfsHash: _ipfsHash,
            qualityRule: QualityRule({
                minTemperature: _minTemp,
                maxTemperature: _maxTemp,
                minHumidity: _minHumidity,
                maxHumidity: _maxHumidity,
                minWeight: _minWeight,
                maxWeight: _maxWeight,
                minPH: _minPH,
                maxPH: _maxPH,
                isActive: true
            }),
            productionData: ProductionData({
                temperature: 0,
                humidity: 0,
                weight: 0,
                phValue: 0,
                timestamp: 0,
                isCompliant: false
            })
        });
        
        emit ProductCreated(productId, msg.sender, _ingredientIds);
        return productId;
    }
    
    // 提交生产数据并验证 (仅商家)
    function submitProductionData(
        uint256 _productId,
        int256 _temperature,
        uint256 _humidity,
        uint256 _weight,
        uint256 _phValue
    ) external productExists(_productId) {
        require(products[_productId].merchant == msg.sender, "Can only update own products");
        require(products[_productId].productionData.timestamp == 0, "Production data already submitted");
        
        Product storage product = products[_productId];
        QualityRule storage rule = product.qualityRule;
        
        // 验证生产数据是否符合HACCP规则
        bool isCompliant = true;
        
        // 检查温度
        if (_temperature < rule.minTemperature || _temperature > rule.maxTemperature) {
            isCompliant = false;
        }
        
        // 检查湿度
        if (_humidity < rule.minHumidity || _humidity > rule.maxHumidity) {
            isCompliant = false;
        }
        
        // 检查重量
        if (_weight < rule.minWeight || _weight > rule.maxWeight) {
            isCompliant = false;
        }
        
        // 检查pH值（仅饮料）
        if (product.category == ProductCategory.Beverage) {
            if (_phValue < rule.minPH || _phValue > rule.maxPH) {
                isCompliant = false;
            }
        }
        
        // 更新生产数据
        product.productionData = ProductionData({
            temperature: _temperature,
            humidity: _humidity,
            weight: _weight,
            phValue: _phValue,
            timestamp: block.timestamp,
            isCompliant: isCompliant
        });
        
        product.productionDate = block.timestamp;
        
        // 根据合规性设置产品状态
        if (isCompliant) {
            product.status = ProductStatus.Safe;
            product.canGenerateQR = true;
        } else {
            product.status = ProductStatus.Alert;
            product.canGenerateQR = false;
        }
        
        emit ProductionDataSubmitted(_productId, msg.sender, isCompliant);
    }
    
    // 生成二维码 (仅商家，且产品必须符合质量标准)
    function generateQRCode(
        uint256 _productId,
        string memory _qrCodeHash
    ) external productExists(_productId) {
        require(products[_productId].merchant == msg.sender, "Can only generate QR for own products");
        require(products[_productId].canGenerateQR, "Product does not meet quality standards");
        require(bytes(_qrCodeHash).length > 0, "QR code hash is required");
        
        products[_productId].qrCodeHash = _qrCodeHash;
        
        emit QRCodeGenerated(_productId, _qrCodeHash);
    }
    
    // 标记原料为污染 (仅商家，只能标记自己的原料)
    function markIngredientContaminated(
        uint256 _ingredientId,
        string memory _reason
    ) external ingredientExists(_ingredientId) {
        require(ingredients[_ingredientId].merchant == msg.sender, "Can only mark own ingredients");
        ingredients[_ingredientId].isContaminated = true;
        
        // 自动将使用了该原料的产品状态设为污染
        _updateAffectedProductsStatus(_ingredientId, ProductStatus.Contaminated);
        
        emit RecallInitiated(_ingredientId, _reason, block.timestamp);
    }
    
    // 启动原料召回 (仅商家，只能召回自己的原料)
    function initiateRecall(
        uint256 _ingredientId,
        string memory _reason
    ) external ingredientExists(_ingredientId) {
        require(ingredients[_ingredientId].merchant == msg.sender, "Can only recall own ingredients");
        ingredients[_ingredientId].isRecalled = true;
        ingredients[_ingredientId].isContaminated = true;
        
        // 自动将使用了该原料的产品状态设为污染
        _updateAffectedProductsStatus(_ingredientId, ProductStatus.Contaminated);
        
        emit RecallInitiated(_ingredientId, _reason, block.timestamp);
    }
    
    // 内部函数：更新受影响产品的状态
    function _updateAffectedProductsStatus(uint256 _ingredientId, ProductStatus _status) internal {
        for (uint256 i = 1; i <= productCounter; i++) {
            Product storage product = products[i];
            for (uint256 j = 0; j < product.ingredientIds.length; j++) {
                if (product.ingredientIds[j] == _ingredientId) {
                    product.status = _status;
                    product.isValid = false;
                    product.canGenerateQR = false;
                    break;
                }
            }
        }
    }
    
    // 验证产品 (消费者和商家都可以)
    function verifyProduct(uint256 _productId) external productExists(_productId) returns (bool) {
        Product storage product = products[_productId];
        
        // 检查所有原料是否都未被召回或污染
        for (uint256 i = 0; i < product.ingredientIds.length; i++) {
            if (ingredients[product.ingredientIds[i]].isRecalled || 
                ingredients[product.ingredientIds[i]].isContaminated) {
                product.isValid = false;
                product.status = ProductStatus.Contaminated;
                break;
            }
        }
        
        emit ProductVerified(_productId, msg.sender, block.timestamp);
        return product.isValid;
    }
    
    // 消费者注册产品警报 (仅消费者)
    function registerForProductAlerts(
        uint256 _productId,
        string memory _email
    ) external productExists(_productId) {
        require(bytes(_email).length > 0, "Email is required");
        require(!consumerProductRegistered[msg.sender][_productId], "Already registered for this product");
        
        productConsumerRegistrations[_productId].push(ConsumerRegistration({
            consumer: msg.sender,
            productId: _productId,
            email: _email,
            registeredAt: block.timestamp,
            isActive: true
        }));
        
        consumerProductRegistered[msg.sender][_productId] = true;
        
        emit ConsumerRegistered(_productId, msg.sender, _email);
    }
    
    // 提交消费者反馈 (仅消费者)
    function submitFeedback(
        uint256 _productId,
        string memory _feedbackText,
        uint256 _rating
    ) external productExists(_productId) returns (uint256) {
        require(bytes(_feedbackText).length > 0, "Feedback text is required");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        
        feedbackCounter++;
        uint256 feedbackId = feedbackCounter;
        
        feedbacks[feedbackId] = ConsumerFeedback({
            id: feedbackId,
            productId: _productId,
            consumer: msg.sender,
            feedbackText: _feedbackText,
            rating: _rating,
            timestamp: block.timestamp,
            isProcessed: false
        });
        
        emit ConsumerFeedbackSubmitted(feedbackId, _productId, msg.sender);
        return feedbackId;
    }
    
    // 获取供应商信息
    function getSupplierInfo(uint256 _supplierId) external view supplierExists(_supplierId) returns (
        uint256 id,
        string memory name,
        string memory contactInfo,
        address merchant,
        uint256 createdAt,
        bool isActive,
        string memory certifications
    ) {
        Supplier storage supplier = suppliers[_supplierId];
        return (
            supplier.id,
            supplier.name,
            supplier.contactInfo,
            supplier.merchant,
            supplier.createdAt,
            supplier.isActive,
            supplier.certifications
        );
    }
    
    // 获取原料信息
    function getIngredientInfo(uint256 _ingredientId) external view ingredientExists(_ingredientId) returns (
        uint256 id,
        string memory name,
        string memory category,
        string memory upc,
        uint256 supplierId,
        address merchant,
        uint256 createdAt,
        uint256 productionDate,
        uint256 expiryDate,
        string memory batchNumber,
        bool isRecalled,
        bool isContaminated,
        int256 minTemp,
        int256 maxTemp,
        uint256 minHumidity,
        uint256 maxHumidity,
        uint256 weight,
        string memory ipfsHash
    ) {
        Ingredient storage ingredient = ingredients[_ingredientId];
        return (
            ingredient.id,
            ingredient.name,
            ingredient.category,
            ingredient.upc,
            ingredient.supplierId,
            ingredient.merchant,
            ingredient.createdAt,
            ingredient.productionDate,
            ingredient.expiryDate,
            ingredient.batchNumber,
            ingredient.isRecalled,
            ingredient.isContaminated,
            ingredient.storageEnv.minTemperature,
            ingredient.storageEnv.maxTemperature,
            ingredient.storageEnv.minHumidity,
            ingredient.storageEnv.maxHumidity,
            ingredient.weight,
            ingredient.ipfsHash
        );
    }
    
    // 获取产品信息
    function getProductInfo(uint256 _productId) external view productExists(_productId) returns (
        uint256 id,
        string memory name,
        string memory description,
        string memory upc,
        ProductCategory category,
        ProductStatus status,
        address merchant,
        uint256[] memory ingredientIds,
        uint256 createdAt,
        uint256 productionDate,
        bool isValid,
        bool canGenerateQR,
        string memory qrCodeHash,
        string memory ipfsHash
    ) {
        Product storage product = products[_productId];
        return (
            product.id,
            product.name,
            product.description,
            product.upc,
            product.category,
            product.status,
            product.merchant,
            product.ingredientIds,
            product.createdAt,
            product.productionDate,
            product.isValid,
            product.canGenerateQR,
            product.qrCodeHash,
            product.ipfsHash
        );
    }
    
    // 获取产品质量规则
    function getProductQualityRule(uint256 _productId) external view productExists(_productId) returns (
        int256 minTemperature,
        int256 maxTemperature,
        uint256 minHumidity,
        uint256 maxHumidity,
        uint256 minWeight,
        uint256 maxWeight,
        uint256 minPH,
        uint256 maxPH,
        bool isActive
    ) {
        QualityRule storage rule = products[_productId].qualityRule;
        return (
            rule.minTemperature,
            rule.maxTemperature,
            rule.minHumidity,
            rule.maxHumidity,
            rule.minWeight,
            rule.maxWeight,
            rule.minPH,
            rule.maxPH,
            rule.isActive
        );
    }
    
    // 获取产品生产数据
    function getProductionData(uint256 _productId) external view productExists(_productId) returns (
        int256 temperature,
        uint256 humidity,
        uint256 weight,
        uint256 phValue,
        uint256 timestamp,
        bool isCompliant
    ) {
        ProductionData storage data = products[_productId].productionData;
        return (
            data.temperature,
            data.humidity,
            data.weight,
            data.phValue,
            data.timestamp,
            data.isCompliant
        );
    }
    
    // 获取消费者反馈
    function getFeedback(uint256 _feedbackId) external view returns (
        uint256 id,
        uint256 productId,
        address consumer,
        string memory feedbackText,
        uint256 rating,
        uint256 timestamp,
        bool isProcessed
    ) {
        require(_feedbackId > 0 && _feedbackId <= feedbackCounter, "Feedback does not exist");
        ConsumerFeedback storage feedback = feedbacks[_feedbackId];
        return (
            feedback.id,
            feedback.productId,
            feedback.consumer,
            feedback.feedbackText,
            feedback.rating,
            feedback.timestamp,
            feedback.isProcessed
        );
    }
    
    // 获取产品的注册消费者列表 (仅商家)
    function getProductConsumers(uint256 _productId) external view productExists(_productId) returns (
        address[] memory consumers,
        string[] memory emails,
        uint256[] memory registeredTimes
    ) {
        require(products[_productId].merchant == msg.sender, "Can only view own product consumers");
        
        ConsumerRegistration[] memory registrations = productConsumerRegistrations[_productId];
        uint256 activeCount = 0;
        
        // 计算活跃注册数量
        for (uint256 i = 0; i < registrations.length; i++) {
            if (registrations[i].isActive) {
                activeCount++;
            }
        }
        
        // 创建返回数组
        consumers = new address[](activeCount);
        emails = new string[](activeCount);
        registeredTimes = new uint256[](activeCount);
        
        uint256 index = 0;
        for (uint256 i = 0; i < registrations.length; i++) {
            if (registrations[i].isActive) {
                consumers[index] = registrations[i].consumer;
                emails[index] = registrations[i].email;
                registeredTimes[index] = registrations[i].registeredAt;
                index++;
            }
        }
        
        return (consumers, emails, registeredTimes);
    }
    
    // 获取受影响的产品列表（用于召回）
    function getAffectedProducts(uint256 _ingredientId) external view ingredientExists(_ingredientId) returns (uint256[] memory) {
        uint256[] memory affectedProducts = new uint256[](productCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= productCounter; i++) {
            Product storage product = products[i];
            for (uint256 j = 0; j < product.ingredientIds.length; j++) {
                if (product.ingredientIds[j] == _ingredientId) {
                    affectedProducts[count] = i;
                    count++;
                    break;
                }
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = affectedProducts[i];
        }
        
        return result;
    }
    
    // 获取用户角色
    function getUserRole(address _user) external view returns (UserRole) {
        require(registeredUsers[_user], "User not registered");
        return userRoles[_user];
    }
    
    // 检查用户是否已注册
    function isUserRegistered(address _user) external view returns (bool) {
        return registeredUsers[_user];
    }
    
    // 获取商家的供应商列表
    function getMerchantSuppliers(address _merchant) external view returns (uint256[] memory) {
        uint256[] memory merchantSuppliers = new uint256[](supplierCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= supplierCounter; i++) {
            if (suppliers[i].merchant == _merchant && suppliers[i].isActive) {
                merchantSuppliers[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = merchantSuppliers[i];
        }
        
        return result;
    }
    
    // 获取商家的原料列表
    function getMerchantIngredients(address _merchant) external view returns (uint256[] memory) {
        uint256[] memory merchantIngredients = new uint256[](ingredientCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= ingredientCounter; i++) {
            if (ingredients[i].merchant == _merchant) {
                merchantIngredients[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = merchantIngredients[i];
        }
        
        return result;
    }
    
    // 获取商家的产品列表
    function getMerchantProducts(address _merchant) external view returns (uint256[] memory) {
        uint256[] memory merchantProducts = new uint256[](productCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= productCounter; i++) {
            if (products[i].merchant == _merchant) {
                merchantProducts[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = merchantProducts[i];
        }
        
        return result;
    }
    
    // 获取消费者注册的产品列表
    function getConsumerProducts(address _consumer) external view returns (uint256[] memory) {
        uint256[] memory consumerProducts = new uint256[](productCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= productCounter; i++) {
            if (consumerProductRegistered[_consumer][i]) {
                consumerProducts[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = consumerProducts[i];
        }
        
        return result;
    }
    
    // 获取消费者提交的反馈列表
    function getConsumerFeedbacks(address _consumer) external view returns (uint256[] memory) {
        uint256[] memory consumerFeedbacks = new uint256[](feedbackCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= feedbackCounter; i++) {
            if (feedbacks[i].consumer == _consumer) {
                consumerFeedbacks[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = consumerFeedbacks[i];
        }
        
        return result;
    }
    
    // 获取产品的所有反馈列表
    function getProductFeedbacks(uint256 _productId) external view productExists(_productId) returns (uint256[] memory) {
        uint256[] memory productFeedbacks = new uint256[](feedbackCounter);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= feedbackCounter; i++) {
            if (feedbacks[i].productId == _productId) {
                productFeedbacks[count] = i;
                count++;
            }
        }
        
        // 创建正确大小的数组
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = productFeedbacks[i];
        }
        
        return result;
    }
    
    // 标记反馈为已处理 (仅商家)
    function markFeedbackAsProcessed(uint256 _feedbackId) external returns (bool) {
        require(_feedbackId > 0 && _feedbackId <= feedbackCounter, "Feedback does not exist");
        
        ConsumerFeedback storage feedback = feedbacks[_feedbackId];
        require(feedback.id != 0, "Feedback not found");
        
        // 验证商家是否拥有该反馈相关的产品
        Product storage product = products[feedback.productId];
        require(product.merchant == msg.sender, "Only product merchant can process feedback");
        require(!feedback.isProcessed, "Feedback already processed");
        
        feedback.isProcessed = true;
        
        emit FeedbackProcessed(_feedbackId, msg.sender, block.timestamp);
        return true;
    }
    
    // 添加反馈处理事件
    event FeedbackProcessed(uint256 indexed feedbackId, address indexed merchant, uint256 timestamp);
}