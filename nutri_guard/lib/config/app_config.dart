class AppConfig {
  static const String appName = 'NutriGuard';
  static const String appVersion = '1.0.0';
  
  // Blockchain Configuration
  static const String ethereumChainId = '11155111'; // Sepolia test network
  static const String ethereumRpcUrl = 'http://172.20.10.4:8545';
  static const String sepoliaRpcUrl = 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY';

  // IoT Edge Gateway (Raspberry Pi + DHT11)
  // Raspberry Pi running Flask edge gateway address, needs to be in the same network as the App phone/simulator
  static const String iotGatewayBaseUrl = 'http://172.20.10.2:5000';
  static const Duration iotFetchTimeout = Duration(seconds: 5);
  
  // Contract Addresses (will be updated after deployment)
  static const String nutriGuardContractAddress = '0xC1707AAa3b0dc69438c0122E4985586A811011c1';
  
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
  static const String walletConnectProjectId = 'YOUR_PROJECT_ID';
  static const String walletConnectRedirectNative = 'nutriguard://';

  // Pinata IPFS Configuration
  static const String pinataJwt = String.fromEnvironment('PINATA_JWT');
  static const String pinataUploadUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  static const String pinataGatewayBaseUrl = 'https://YOUR_BASEURL/ipfs';

  // Ubidots Configuration
  static const String ubidotsApiUrl = 'https://industrial.api.ubidots.com/api/v1.6';
  static const String ubidotsToken = 'YOUR_UBIDOTS_TOKEN';
  
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
  static const bool useLocalBlockchain = false;
}



