// HACCP质量控制规则模型
class QualityRule {
  final double minTemperature;
  final double maxTemperature;
  final double minHumidity;
  final double maxHumidity;
  final double minWeight;
  final double maxWeight;
  final double minPH;
  final double maxPH;
  final bool isActive;

  QualityRule({
    required this.minTemperature,
    required this.maxTemperature,
    required this.minHumidity,
    required this.maxHumidity,
    required this.minWeight,
    required this.maxWeight,
    required this.minPH,
    required this.maxPH,
    this.isActive = true,
  });

  factory QualityRule.fromBlockchain(List<dynamic> data) {
    return QualityRule(
      minTemperature: (data[0] as BigInt).toDouble(),
      maxTemperature: (data[1] as BigInt).toDouble(),
      minHumidity: (data[2] as BigInt).toDouble(),
      maxHumidity: (data[3] as BigInt).toDouble(),
      minWeight: (data[4] as BigInt).toDouble(),
      maxWeight: (data[5] as BigInt).toDouble(),
      minPH: (data[6] as BigInt).toDouble() / 100, // 从智能合约转换回小数
      maxPH: (data[7] as BigInt).toDouble() / 100,
      isActive: data[8],
    );
  }

  factory QualityRule.fromJson(Map<String, dynamic> json) {
    return QualityRule(
      minTemperature: json['minTemperature'].toDouble(),
      maxTemperature: json['maxTemperature'].toDouble(),
      minHumidity: json['minHumidity'].toDouble(),
      maxHumidity: json['maxHumidity'].toDouble(),
      minWeight: json['minWeight'].toDouble(),
      maxWeight: json['maxWeight'].toDouble(),
      minPH: json['minPH'].toDouble(),
      maxPH: json['maxPH'].toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'minWeight': minWeight,
      'maxWeight': maxWeight,
      'minPH': minPH,
      'maxPH': maxPH,
      'isActive': isActive,
    };
  }

  // 验证生产数据是否符合规则
  bool isCompliant(ProductionData data) {
    if (data.temperature < minTemperature || data.temperature > maxTemperature) {
      return false;
    }
    if (data.humidity < minHumidity || data.humidity > maxHumidity) {
      return false;
    }
    if (data.weight < minWeight || data.weight > maxWeight) {
      return false;
    }
    if (data.phValue < minPH || data.phValue > maxPH) {
      return false;
    }
    return true;
  }

  String get temperatureRange => '${minTemperature}°C - ${maxTemperature}°C';
  String get humidityRange => '${minHumidity}% - ${maxHumidity}%';
  String get weightRange => '${minWeight}g - ${maxWeight}g';
  String get phRange => '${minPH.toStringAsFixed(2)} - ${maxPH.toStringAsFixed(2)}';
}

// 生产数据模型
class ProductionData {
  final double temperature;
  final double humidity;
  final double weight;
  final double phValue;
  final DateTime timestamp;
  final bool isCompliant;

  ProductionData({
    required this.temperature,
    required this.humidity,
    required this.weight,
    required this.phValue,
    required this.timestamp,
    required this.isCompliant,
  });

  factory ProductionData.fromBlockchain(List<dynamic> data) {
    return ProductionData(
      temperature: (data[0] as BigInt).toDouble(),
      humidity: (data[1] as BigInt).toDouble(),
      weight: (data[2] as BigInt).toDouble(),
      phValue: (data[3] as BigInt).toDouble() / 100, // 从智能合约转换回小数
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data[4] as BigInt).toInt() * 1000,
      ),
      isCompliant: data[5],
    );
  }

  factory ProductionData.fromJson(Map<String, dynamic> json) {
    return ProductionData(
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      weight: json['weight'].toDouble(),
      phValue: json['phValue'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      isCompliant: json['isCompliant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'weight': weight,
      'phValue': phValue,
      'timestamp': timestamp.toIso8601String(),
      'isCompliant': isCompliant,
    };
  }

  bool get hasData => timestamp.millisecondsSinceEpoch > 0;

  String get statusText => isCompliant ? 'Compliant' : 'Non-compliant';
  String get temperatureText => '${temperature.toStringAsFixed(1)}°C';
  String get humidityText => '${humidity.toStringAsFixed(1)}%';
  String get weightText => '${weight.toStringAsFixed(1)}g';
  String get phText => phValue.toStringAsFixed(2);
}
