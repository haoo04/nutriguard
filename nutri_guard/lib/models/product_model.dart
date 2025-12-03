import 'ingredient_model.dart';
import 'quality_model.dart';

// 产品类别枚举
enum ProductCategory { mainFood, snack, beverage }

// 产品状态枚举
enum ProductStatus { safe, alert, contaminated }

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.mainFood:
        return 'Main food';
      case ProductCategory.snack:
        return 'Snack';
      case ProductCategory.beverage:
        return 'Beverage';
    }
  }

  static ProductCategory fromIndex(int index) {
    return ProductCategory.values[index];
  }
}

extension ProductStatusExtension on ProductStatus {
  String get displayName {
    switch (this) {
      case ProductStatus.safe:
        return 'Safe';
      case ProductStatus.alert:
        return 'Alert';
      case ProductStatus.contaminated:
        return 'Contaminated';
    }
  }

  String get color {
    switch (this) {
      case ProductStatus.safe:
        return '#4CAF50'; // 绿色
      case ProductStatus.alert:
        return '#FF9800'; // 橙色
      case ProductStatus.contaminated:
        return '#F44336'; // 红色
    }
  }

  static ProductStatus fromIndex(int index) {
    return ProductStatus.values[index];
  }
}

class ProductModel {
  final String id;
  final String name;                      // 产品名称（必须）
  final String description;               // 产品描述
  final String upc;                       // 通用产品代码
  final ProductCategory category;         // 种类（主食，小食，饮料）
  final ProductStatus status;             // 产品状态
  final String merchantAddress;           // 商家地址
  final List<String> ingredientIds;      // 使用到的原料
  final DateTime createdAt;
  final DateTime? productionDate;         // 生产日期
  final bool isValid;
  final bool canGenerateQR;               // 是否可以生成二维码
  final String qrCodeHash;
  final String ipfsHash;
  final QualityRule? qualityRule;         // 质量控制规则
  final ProductionData? productionData;   // 生产数据
  final List<IngredientModel>? ingredients; // 关联的原料对象

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.upc,
    required this.category,
    required this.status,
    required this.merchantAddress,
    required this.ingredientIds,
    required this.createdAt,
    this.productionDate,
    this.isValid = true,
    this.canGenerateQR = false,
    required this.qrCodeHash,
    required this.ipfsHash,
    this.qualityRule,
    this.productionData,
    this.ingredients,
  });

  factory ProductModel.fromBlockchain(List<dynamic> data) {
    return ProductModel(
      id: data[0].toString(),
      name: data[1],
      description: data[2],
      upc: data[3],
      category: ProductCategoryExtension.fromIndex((data[4] as BigInt).toInt()),
      status: ProductStatusExtension.fromIndex((data[5] as BigInt).toInt()),
      merchantAddress: data[6].toString(), // 将EthereumAddress转换为String
      ingredientIds: (data[7] as List).map((e) => e.toString()).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data[8] as BigInt).toInt() * 1000,
      ),
      productionDate: (data[9] as BigInt).toInt() > 0 
          ? DateTime.fromMillisecondsSinceEpoch((data[9] as BigInt).toInt() * 1000)
          : null,
      isValid: data[10],
      canGenerateQR: data[11],
      qrCodeHash: data[12],
      ipfsHash: data[13],
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      upc: json['upc'],
      category: ProductCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ProductCategory.mainFood,
      ),
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.safe,
      ),
      merchantAddress: json['merchantAddress'],
      ingredientIds: List<String>.from(json['ingredientIds']),
      createdAt: DateTime.parse(json['createdAt']),
      productionDate: json['productionDate'] != null 
          ? DateTime.parse(json['productionDate'])
          : null,
      isValid: json['isValid'] ?? true,
      canGenerateQR: json['canGenerateQR'] ?? false,
      qrCodeHash: json['qrCodeHash'],
      ipfsHash: json['ipfsHash'],
      qualityRule: json['qualityRule'] != null 
          ? QualityRule.fromJson(json['qualityRule'])
          : null,
      productionData: json['productionData'] != null 
          ? ProductionData.fromJson(json['productionData'])
          : null,
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => IngredientModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'upc': upc,
      'category': category.name,
      'status': status.name,
      'merchantAddress': merchantAddress,
      'ingredientIds': ingredientIds,
      'createdAt': createdAt.toIso8601String(),
      'productionDate': productionDate?.toIso8601String(),
      'isValid': isValid,
      'canGenerateQR': canGenerateQR,
      'qrCodeHash': qrCodeHash,
      'ipfsHash': ipfsHash,
      'qualityRule': qualityRule?.toJson(),
      'productionData': productionData?.toJson(),
      'ingredients': ingredients?.map((e) => e.toJson()).toList(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? upc,
    ProductCategory? category,
    ProductStatus? status,
    String? merchantAddress,
    List<String>? ingredientIds,
    DateTime? createdAt,
    DateTime? productionDate,
    bool? isValid,
    bool? canGenerateQR,
    String? qrCodeHash,
    String? ipfsHash,
    QualityRule? qualityRule,
    ProductionData? productionData,
    List<IngredientModel>? ingredients,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      upc: upc ?? this.upc,
      category: category ?? this.category,
      status: status ?? this.status,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      ingredientIds: ingredientIds ?? this.ingredientIds,
      createdAt: createdAt ?? this.createdAt,
      productionDate: productionDate ?? this.productionDate,
      isValid: isValid ?? this.isValid,
      canGenerateQR: canGenerateQR ?? this.canGenerateQR,
      qrCodeHash: qrCodeHash ?? this.qrCodeHash,
      ipfsHash: ipfsHash ?? this.ipfsHash,
      qualityRule: qualityRule ?? this.qualityRule,
      productionData: productionData ?? this.productionData,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  bool get hasRecalledIngredients {
    if (ingredients == null) return false;
    return ingredients!.any((ingredient) => ingredient.isRecalled);
  }

  bool get hasContaminatedIngredients {
    if (ingredients == null) return false;
    return ingredients!.any((ingredient) => ingredient.isContaminated);
  }

  List<IngredientModel> get recalledIngredients {
    if (ingredients == null) return [];
    return ingredients!.where((ingredient) => ingredient.isRecalled).toList();
  }

  List<IngredientModel> get contaminatedIngredients {
    if (ingredients == null) return [];
    return ingredients!.where((ingredient) => ingredient.isContaminated).toList();
  }

  bool get hasExpiredIngredients {
    if (ingredients == null) return false;
    return ingredients!.any((ingredient) => ingredient.isExpired);
  }

  bool get isProductValid {
    return isValid && !hasRecalledIngredients && !hasContaminatedIngredients && !hasExpiredIngredients;
  }

  // 获取产品生产状态
  bool get isProductionCompliant {
    return productionData?.isCompliant ?? false;
  }

  // 获取pH值显示文本
  String get phValueDisplay {
    if (category != ProductCategory.beverage || 
        productionData?.phValue == null) {
      return 'Not applicable';
    }
    return productionData!.phValue.toStringAsFixed(2);
  }

  // 获取产品状态描述
  String get statusDescription {
    switch (status) {
      case ProductStatus.safe:
        return '产品安全，可以放心食用';
      case ProductStatus.alert:
        return '产品警报，生产过程不符合标准';
      case ProductStatus.contaminated:
        return '产品被污染，禁止食用';
    }
  }

  String get displayName => name;


}

class RecallNotification {
  final String id;
  final String ingredientId;
  final String productId;
  final String reason;
  final DateTime timestamp;
  final String manufacturerAddress;
  final bool isRead;
  final RecallSeverity severity;

  RecallNotification({
    required this.id,
    required this.ingredientId,
    required this.productId,
    required this.reason,
    required this.timestamp,
    required this.manufacturerAddress,
    this.isRead = false,
    this.severity = RecallSeverity.medium,
  });

  factory RecallNotification.fromJson(Map<String, dynamic> json) {
    return RecallNotification(
      id: json['id'],
      ingredientId: json['ingredientId'],
      productId: json['productId'],
      reason: json['reason'],
      timestamp: DateTime.parse(json['timestamp']),
      manufacturerAddress: json['manufacturerAddress'],
      isRead: json['isRead'] ?? false,
      severity: RecallSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => RecallSeverity.medium,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ingredientId': ingredientId,
      'productId': productId,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'manufacturerAddress': manufacturerAddress,
      'isRead': isRead,
      'severity': severity.name,
    };
  }

  RecallNotification copyWith({
    String? id,
    String? ingredientId,
    String? productId,
    String? reason,
    DateTime? timestamp,
    String? manufacturerAddress,
    bool? isRead,
    RecallSeverity? severity,
  }) {
    return RecallNotification(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      productId: productId ?? this.productId,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      manufacturerAddress: manufacturerAddress ?? this.manufacturerAddress,
      isRead: isRead ?? this.isRead,
      severity: severity ?? this.severity,
    );
  }
}

enum RecallSeverity { low, medium, high, critical }

extension RecallSeverityExtension on RecallSeverity {
  String get displayName {
    switch (this) {
      case RecallSeverity.low:
        return 'Low risk';
      case RecallSeverity.medium:
        return 'Medium risk';
      case RecallSeverity.high:
        return 'High risk';
      case RecallSeverity.critical:
        return 'Critical recall';
    }
  }

  String get color {
    switch (this) {
      case RecallSeverity.low:
        return '#4CAF50';
      case RecallSeverity.medium:
        return '#FF9800';
      case RecallSeverity.high:
        return '#FF5722';
      case RecallSeverity.critical:
        return '#F44336';
    }
  }
}



