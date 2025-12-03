enum WalletType { metamask, walletConnect }

enum UserRole { merchant, consumer }

class WalletConnection {
  final WalletType type;
  final String address;
  final String? name;

  WalletConnection({
    required this.type,
    required this.address,
    this.name,
  });

  String get displayName {
    switch (type) {
      case WalletType.metamask:
        return 'MetaMask';
      case WalletType.walletConnect:
        return 'WalletConnect';
    }
  }
}

class LoginCredentials {
  final String username;
  final String password;

  LoginCredentials({
    required this.username,
    required this.password,
  });

  bool get isValid => username == 'admin123' && password == '123456';
}
