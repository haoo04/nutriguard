class AppConfig {
  static const String appName = 'NutriGuard';
  static const String appVersion = '1.0.0';
  
  // Blockchain Configuration
  static const String ethereumChainId = '1337'; // Hardhat local network
  static const String ethereumRpcUrl = 'http://192.168.0.16:8545'; //172.20.10.4
  static const String sepoliaRpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY';
  
  // Contract Addresses (will be updated after deployment)
  static const String nutriGuardContractAddress = '0x5FbDB2315678afecb367f032d93F642f64180aa3';
  
  // Preset Local Accounts (from Hardhat)
  static const Map<String, Map<String, String>> presetAccounts = {
    'consumer': {
      'address': '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      'privateKey': '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    },
    'merchant': {
      'address': '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
      'privateKey': '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
    },
  };

  // WalletConnect Configuration
  static const String walletConnectProjectId = '4c70563ddbc2c6d08619a256b0ec1793';
  
  // Ubidots Configuration
  static const String ubidotsApiUrl = 'https://industrial.api.ubidots.com/api/v1.6';
  static const String ubidotsToken = 'YOUR_UBIDOTS_TOKEN';

  // IoT Edge Gateway (Raspberry Pi + DHT11)
  // 树莓派运行的 Flask 边缘网关地址, 需与 App 所在手机/模拟器保持同网段
  static const String iotGatewayBaseUrl = 'http://192.168.0.32:5000';
  static const Duration iotFetchTimeout = Duration(seconds: 5);
  
  // Firebase Configuration (will be configured in firebase_options.dart)
  
  // Quality Standards
  static const Map<String, Map<String, double>> qualityStandards = {
    'default': {
      'minTemperature': -10.0,
      'maxTemperature': 25.0,
      'minHumidity': 30.0,
      'maxHumidity': 70.0,
      'minWeight': 1.0,
      'maxWeight': 10000.0,
    },
    'frozen': {
      'minTemperature': -25.0,
      'maxTemperature': -15.0,
      'minHumidity': 20.0,
      'maxHumidity': 60.0,
      'minWeight': 1.0,
      'maxWeight': 5000.0,
    },
    'fresh': {
      'minTemperature': 0.0,
      'maxTemperature': 8.0,
      'minHumidity': 85.0,
      'maxHumidity': 95.0,
      'minWeight': 1.0,
      'maxWeight': 2000.0,
    },
  };
  
  // Environment
  static const bool isDevelopment = true;
  static const bool useLocalBlockchain = true;
}



