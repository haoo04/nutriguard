import 'dart:async';
import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

import '../config/app_config.dart';

class EnhancedWalletService extends ChangeNotifier {
  static final EnhancedWalletService _instance = EnhancedWalletService._internal();
  factory EnhancedWalletService() => _instance;
  EnhancedWalletService._internal();

  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _lastError;

  static const String _contractAbi = '''[
    {
      "inputs": [{"internalType": "enum NutriGuard.UserRole", "name": "_role", "type": "uint8"}],
      "name": "registerUser",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ]''';

  ReownAppKitModal? get appKitModal => _appKitModal;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isConnected => _appKitModal?.isConnected ?? false;
  String? get lastError => _lastError;

  String get _sepoliaChainId => 'eip155:${AppConfig.ethereumChainId}';

  String? get selectedChainId => _appKitModal?.session?.chainId;

  String? get connectedAddress {
    final modal = _appKitModal;
    final session = modal?.session;
    if (modal == null || session == null) {
      return null;
    }

    return session.address;
  }

  Future<void> initialize(BuildContext context) async {
    if (_isInitialized || _isInitializing) {
      return;
    }

    _isInitializing = true;
    _lastError = null;
    notifyListeners();

    try {
      final sepoliaNetwork = _ensureSepoliaNetwork();

      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: AppConfig.walletConnectProjectId,
        metadata: const PairingMetadata(
          name: AppConfig.appName,
          description: 'Blockchain food traceability system',
          url: 'https://nutriguard.local',
          icons: ['https://walletconnect.com/walletconnect-logo.png'],
          redirect: Redirect(
            native: AppConfig.walletConnectRedirectNative,
            linkMode: false,
          ),
        ),
      );

      _appKitModal!.onModalConnect.subscribe(_handleWalletEvent);
      _appKitModal!.onModalUpdate.subscribe(_handleWalletEvent);
      _appKitModal!.onModalNetworkChange.subscribe(_handleWalletEvent);
      _appKitModal!.onModalDisconnect.subscribe(_handleWalletEvent);
      _appKitModal!.onModalError.subscribe((event) {
        _lastError = event?.message ?? 'Wallet connection failed';
        notifyListeners();
      });

      await _appKitModal!.init();
      _ensureSepoliaLookupCompatibility();

      if (sepoliaNetwork != null) {
        await _appKitModal!.selectChain(sepoliaNetwork);
      }

      _isInitialized = true;
      print('EnhancedWalletService: Reown AppKit initialized.');
    } catch (e) {
      _lastError = 'Wallet initialization failed: $e';
      print('EnhancedWalletService: initialization failed - $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> openModal() async {
    final modal = _requireModal();
    await modal.openModalView();
  }

  Future<void> disconnect() async {
    final modal = _appKitModal;
    if (modal == null || !modal.isConnected) {
      return;
    }

    await modal.disconnect();
    notifyListeners();
  }

  Future<void> ensureSepoliaSelected() async {
    final modal = _requireModal();

    if (_isSepoliaApproved()) {
      return;
    }

    final sepoliaNetwork = _ensureSepoliaNetwork();
    if (sepoliaNetwork == null) {
      throw Exception('Sepolia network is not available in wallet configuration');
    }

    try {
      await modal.requestSwitchToChain(sepoliaNetwork);
    } catch (e) {
      if (_isSepoliaApproved()) {
        return;
      }
      throw Exception('Please switch MetaMask to Sepolia and try again. Details: $e');
    }
  }

  Future<String> signLoginMessage(String message) async {
    final modal = _requireConnectedModal();
    await ensureSepoliaSelected();

    final address = connectedAddress;
    if (address == null) {
      throw Exception('Unable to read connected wallet address');
    }

    final encodedMessage = hex.encode(utf8.encode(message));
    final result = await modal.request(
      topic: modal.session!.topic,
      chainId: _sepoliaChainId,
      request: SessionRequestParams(
        method: 'personal_sign',
        params: ['0x$encodedMessage', address],
      ),
    );

    return result.toString();
  }

  Future<String> registerUser(int roleIndex) async {
    final deployedContract = DeployedContract(
      ContractAbi.fromJson(_contractAbi, 'NutriGuard'),
      EthereumAddress.fromHex(AppConfig.nutriGuardContractAddress),
    );

    return writeContract(
      deployedContract: deployedContract,
      functionName: 'registerUser',
      parameters: [BigInt.from(roleIndex)],
    );
  }

  Future<String> writeContract({
    required DeployedContract deployedContract,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    final modal = _requireConnectedModal();
    await ensureSepoliaSelected();

    final address = connectedAddress;
    if (address == null) {
      throw Exception('Unable to read connected wallet address');
    }

    final result = await modal.requestWriteContract(
      topic: modal.session!.topic,
      chainId: _sepoliaChainId,
      deployedContract: deployedContract,
      functionName: functionName,
      transaction: Transaction(
        from: EthereumAddress.fromHex(address),
      ),
      parameters: parameters,
    );

    return result.toString();
  }
  
  // Kept for providing test credentials if needed elsewhere, though login logic now handles it.
  Credentials createTestCredentials(String privateKey) {
    return EthPrivateKey.fromHex(privateKey);
  }

  ReownAppKitModal _requireModal() {
    final modal = _appKitModal;
    if (modal == null || !_isInitialized) {
      throw Exception('Wallet service is not initialized');
    }
    return modal;
  }

  ReownAppKitModal _requireConnectedModal() {
    final modal = _requireModal();
    if (!modal.isConnected) {
      throw Exception('Please connect MetaMask first');
    }
    return modal;
  }

  ReownAppKitModalNetworkInfo? _ensureSepoliaNetwork() {
    const namespace = 'eip155';
    final networks = ReownAppKitModalNetworks.supported[namespace];
    if (networks == null) {
      return null;
    }

    final existingNetworks = networks.where(
      (network) => network.chainId == AppConfig.ethereumChainId,
    );
    if (existingNetworks.isNotEmpty) {
      return existingNetworks.first;
    }

    final sepoliaNetwork = ReownAppKitModalNetworkInfo(
      name: 'Sepolia',
      chainId: AppConfig.ethereumChainId,
      currency: 'SEP',
      rpcUrl: AppConfig.sepoliaRpcUrl,
      explorerUrl: 'https://sepolia.etherscan.io/',
      isTestNetwork: true,
    );
    networks.add(sepoliaNetwork);
    return sepoliaNetwork;
  }

  void _ensureSepoliaLookupCompatibility() {
    const namespace = 'eip155';
    final networks = ReownAppKitModalNetworks.supported[namespace];
    if (networks == null) {
      return;
    }

    final hasCaipEntry = networks.any(
      (network) => network.chainId == _sepoliaChainId,
    );
    if (hasCaipEntry) {
      return;
    }

    networks.add(
      ReownAppKitModalNetworkInfo(
        name: 'Sepolia',
        chainId: _sepoliaChainId,
        currency: 'SEP',
        rpcUrl: AppConfig.sepoliaRpcUrl,
        explorerUrl: 'https://sepolia.etherscan.io/',
        isTestNetwork: true,
      ),
    );
  }

  bool _isSepoliaApproved() {
    final modal = _appKitModal;
    final session = modal?.session;
    if (modal == null || session == null) {
      return false;
    }

    if (session.chainId == AppConfig.ethereumChainId ||
        session.chainId == _sepoliaChainId) {
      return true;
    }

    final approvedChains = modal.getApprovedChains() ?? session.getApprovedChains() ?? [];
    return approvedChains.any(
      (chain) => chain == AppConfig.ethereumChainId || chain == _sepoliaChainId,
    );
  }

  void _handleWalletEvent(dynamic event) {
    _ensureSepoliaLookupCompatibility();
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    final modal = _appKitModal;
    if (modal != null) {
      unawaited(modal.dispose());
    }
    super.dispose();
  }
}
