// 储存环境类
class StorageEnvironment {
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;

  StorageEnvironment({
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
  });

  factory StorageEnvironment.fromJson(Map<String, dynamic> json) {
    return StorageEnvironment(
      minTemperature: json['minTemperature'].toDouble(),
      maxTemperature: json['maxTemperature'].toDouble(),
      minHumidity: json['minHumidity'].toDouble(),
      maxHumidity: json['maxHumidity'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
    };
  }
}

class IngredientModel {
  final String id;
  final String name;                    // 必须
  final String? category;               // 种类
  final String upc;                     // 通用产品代码
  final String supplierId;              // 供应商ID
  final String merchantAddress;         // 商家地址
  final DateTime createdAt;
  final DateTime productionDate;        // 生产日期
  final DateTime expiryDate;            // 保质期
  final String batchNumber;             // 材料批次
  final bool isRecalled;
  final bool isContaminated;            // 是否被污染
  final StorageEnvironment storageEnv;  // 储存环境范围
  final double weight;                  // 重量（克）
  final String ipfsHash;

  IngredientModel({
    required this.id,
    required this.name,
    this.category,
    required this.upc,
    required this.supplierId,
    required this.merchantAddress,
    required this.createdAt,
    required this.productionDate,
    required this.expiryDate,
    required this.batchNumber,
    this.isRecalled = false,
    this.isContaminated = false,
    required this.storageEnv,
    required this.weight,
    required this.ipfsHash,
  });

  factory IngredientModel.fromBlockchain(List<dynamic> data) {
    return IngredientModel(
      id: data[0].toString(),
      name: data[1],
      category: data[2],
      upc: data[3],
      supplierId: data[4].toString(),
      merchantAddress: data[5].toString(), // 将EthereumAddress转换为String
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data[6] as BigInt).toInt() * 1000,
      ),
      productionDate: DateTime.fromMillisecondsSinceEpoch(
        (data[7] as BigInt).toInt() * 1000,
      ),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(
        (data[8] as BigInt).toInt() * 1000,
      ),
      batchNumber: data[9],
      isRecalled: data[10],
      isContaminated: data[11],
      storageEnv: StorageEnvironment(
        minTemperature: (data[12] as BigInt).toDouble(),
        maxTemperature: (data[13] as BigInt).toDouble(),
        minHumidity: (data[14] as BigInt).toDouble(),
        maxHumidity: (data[15] as BigInt).toDouble(),
      ),
      weight: (data[16] as BigInt).toDouble(),
      ipfsHash: data[17],
    );
  }

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      upc: json['upc'],
      supplierId: json['supplierId'],
      merchantAddress: json['merchantAddress'],
      createdAt: DateTime.parse(json['createdAt']),
      productionDate: DateTime.parse(json['productionDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      batchNumber: json['batchNumber'],
      isRecalled: json['isRecalled'] ?? false,
      isContaminated: json['isContaminated'] ?? false,
      storageEnv: StorageEnvironment.fromJson(json['storageEnv']),
      weight: json['weight'].toDouble(),
      ipfsHash: json['ipfsHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'upc': upc,
      'supplierId': supplierId,
      'merchantAddress': merchantAddress,
      'createdAt': createdAt.toIso8601String(),
      'productionDate': productionDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'batchNumber': batchNumber,
      'isRecalled': isRecalled,
      'isContaminated': isContaminated,
      'storageEnv': storageEnv.toJson(),
      'weight': weight,
      'ipfsHash': ipfsHash,
    };
  }

  IngredientModel copyWith({
    String? id,
    String? name,
    String? category,
    String? upc,
    String? supplierId,
    String? merchantAddress,
    DateTime? createdAt,
    DateTime? productionDate,
    DateTime? expiryDate,
    String? batchNumber,
    bool? isRecalled,
    bool? isContaminated,
    StorageEnvironment? storageEnv,
    double? weight,
    String? ipfsHash,
  }) {
    return IngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      upc: upc ?? this.upc,
      supplierId: supplierId ?? this.supplierId,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      createdAt: createdAt ?? this.createdAt,
      productionDate: productionDate ?? this.productionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      batchNumber: batchNumber ?? this.batchNumber,
      isRecalled: isRecalled ?? this.isRecalled,
      isContaminated: isContaminated ?? this.isContaminated,
      storageEnv: storageEnv ?? this.storageEnv,
      weight: weight ?? this.weight,
      ipfsHash: ipfsHash ?? this.ipfsHash,
    );
  }

  // 检查原料是否过期
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  // 检查原料是否有效（未召回、未污染且未过期）
  bool get isValid {
    return !isRecalled && !isContaminated && !isExpired;
  }

  // 获取原料状态文本
  String get statusText {
    if (isRecalled) return 'Recalled';
    if (isContaminated) return 'Contaminated';
    if (isExpired) return 'Expired';
    return 'Safe';
  }

  // 获取原料状态颜色
  String get statusColor {
    if (isRecalled || isContaminated) return '#F44336'; // 红色
    if (isExpired) return '#FF9800'; // 橙色
    return '#4CAF50'; // 绿色
  }

  // 获取储存环境描述
  String get storageDescription {
    return 'Temperature: ${storageEnv.minTemperature}°C ~ ${storageEnv.maxTemperature}°C, '
           'Humidity: ${storageEnv.minHumidity}% ~ ${storageEnv.maxHumidity}%';
  }
}

// QualityRecord类已移除，因为新的设计不再使用质量记录系统



