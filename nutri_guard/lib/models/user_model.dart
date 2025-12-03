enum UserRole { merchant, consumer }

class UserModel {
  final String id;
  final String walletAddress;
  final String? email;
  final String? displayName;
  final UserRole role;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.walletAddress,
    this.email,
    this.displayName,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      walletAddress: json['walletAddress'],
      email: json['email'],
      displayName: json['displayName'],
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.consumer,
      ),
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletAddress': walletAddress,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? walletAddress,
    String? email,
    String? displayName,
    UserRole? role,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      walletAddress: walletAddress ?? this.walletAddress,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isMerchant => role == UserRole.merchant;
  bool get isConsumer => role == UserRole.consumer;

  String get roleDisplayName {
    switch (role) {
      case UserRole.merchant:
        return 'Merchant';
      case UserRole.consumer:
        return 'Consumer';
    }
  }
}



