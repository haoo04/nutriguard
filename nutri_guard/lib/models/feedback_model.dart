// 消费者反馈模型
class ConsumerFeedback {
  final String id;
  final String productId;
  final String consumerAddress;
  final String feedbackText;
  final int rating; // 1-5 评分
  final DateTime timestamp;
  final bool isProcessed;

  ConsumerFeedback({
    required this.id,
    required this.productId,
    required this.consumerAddress,
    required this.feedbackText,
    required this.rating,
    required this.timestamp,
    this.isProcessed = false,
  });

  factory ConsumerFeedback.fromBlockchain(List<dynamic> data) {
    return ConsumerFeedback(
      id: data[0].toString(),
      productId: data[1].toString(),
      consumerAddress: data[2].toString(), // 将EthereumAddress转换为String
      feedbackText: data[3],
      rating: (data[4] as BigInt).toInt(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (data[5] as BigInt).toInt() * 1000,
      ),
      isProcessed: data[6],
    );
  }

  factory ConsumerFeedback.fromJson(Map<String, dynamic> json) {
    return ConsumerFeedback(
      id: json['id'],
      productId: json['productId'],
      consumerAddress: json['consumerAddress'],
      feedbackText: json['feedbackText'],
      rating: json['rating'],
      timestamp: DateTime.parse(json['timestamp']),
      isProcessed: json['isProcessed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'consumerAddress': consumerAddress,
      'feedbackText': feedbackText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
      'isProcessed': isProcessed,
    };
  }

  ConsumerFeedback copyWith({
    String? id,
    String? productId,
    String? consumerAddress,
    String? feedbackText,
    int? rating,
    DateTime? timestamp,
    bool? isProcessed,
  }) {
    return ConsumerFeedback(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      consumerAddress: consumerAddress ?? this.consumerAddress,
      feedbackText: feedbackText ?? this.feedbackText,
      rating: rating ?? this.rating,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  String get ratingText {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  String get ratingEmoji {
    switch (rating) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😍';
      default:
        return '❓';
    }
  }
}

// 消费者注册模型
class ConsumerRegistration {
  final String consumerAddress;
  final String productId;
  final String email;
  final DateTime registeredAt;
  final bool isActive;

  ConsumerRegistration({
    required this.consumerAddress,
    required this.productId,
    required this.email,
    required this.registeredAt,
    this.isActive = true,
  });

  factory ConsumerRegistration.fromJson(Map<String, dynamic> json) {
    return ConsumerRegistration(
      consumerAddress: json['consumerAddress'],
      productId: json['productId'],
      email: json['email'],
      registeredAt: DateTime.parse(json['registeredAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consumerAddress': consumerAddress,
      'productId': productId,
      'email': email,
      'registeredAt': registeredAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}
