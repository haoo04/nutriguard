// 供应商模型
class SupplierModel {
  final String id;
  final String name;
  final String contactInfo;
  final String merchantAddress;
  final DateTime createdAt;
  final bool isActive;
  final String certifications;

  SupplierModel({
    required this.id,
    required this.name,
    required this.contactInfo,
    required this.merchantAddress,
    required this.createdAt,
    this.isActive = true,
    this.certifications = '',
  });

  factory SupplierModel.fromBlockchain(List<dynamic> data) {
    return SupplierModel(
      id: data[0].toString(),
      name: data[1],
      contactInfo: data[2],
      merchantAddress: data[3].toString(), // 将EthereumAddress转换为String
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data[4] as BigInt).toInt() * 1000,
      ),
      isActive: data[5],
      certifications: data[6],
    );
  }

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'],
      name: json['name'],
      contactInfo: json['contactInfo'],
      merchantAddress: json['merchantAddress'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
      certifications: json['certifications'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactInfo': contactInfo,
      'merchantAddress': merchantAddress,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'certifications': certifications,
    };
  }

  SupplierModel copyWith({
    String? id,
    String? name,
    String? contactInfo,
    String? merchantAddress,
    DateTime? createdAt,
    bool? isActive,
    String? certifications,
  }) {
    return SupplierModel(
      id: id ?? this.id,
      name: name ?? this.name,
      contactInfo: contactInfo ?? this.contactInfo,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      certifications: certifications ?? this.certifications,
    );
  }
}
