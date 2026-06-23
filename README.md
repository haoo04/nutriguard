# NutriGuard

<p align="center">
  <strong>English</strong> | <a href="README_CN.md">中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Network-Sepolia-627EEA?style=flat-square" alt="Sepolia">
  <img src="https://img.shields.io/badge/Contract-Solidity-red?style=flat-square" alt="Solidity">
  <img src="https://img.shields.io/badge/App-Flutter-02569B?style=flat-square" alt="Flutter">
  <img src="https://img.shields.io/badge/IoT-Raspberry%20Pi-C51A4A?style=flat-square" alt="Raspberry Pi">
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Version">
</p>

Blockchain-based food traceability system for restaurants and food businesses, covering the full chain of **ingredient procurement → HACCP quality control → QR code sales → consumer verification and recall**. Data is written to Ethereum smart contracts, product images and certificates are stored on IPFS, with optional Raspberry Pi DHT11 sensor integration for automated temperature/humidity collection.

> **Current status:** The `NutriGuard` smart contract is deployed on the **Sepolia testnet**. The Flutter mobile app can connect to the same contract via MetaMask (WalletConnect / Reown AppKit) to perform on-chain operations.

---

## Live Contract

| Item | Value |
|------|-------|
| Network | Ethereum Sepolia Testnet |
| Chain ID | `11155111` |
| Contract Address | [`0xC1707AAa3b0dc69438c0122E4985586A811011c1`](https://sepolia.etherscan.io/address/0xC1707AAa3b0dc69438c0122E4985586A811011c1) |
| Explorer | [Sepolia Etherscan](https://sepolia.etherscan.io/address/0xC1707AAa3b0dc69438c0122E4985586A811011c1) |

The contract address is also saved in [`nutri_guard/lib/config/contract_addresses.json`](nutri_guard/lib/config/contract_addresses.json).

---

## System Architecture

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Flutter App     │     │  NutriGuard.sol  │     │  Pinata / IPFS   │
│  (Merchant /     │◄───►│  (Sepolia Chain) │◄───►│  (Images / Certs)│
│   Consumer)      │     │                  │     │                  │
└────────┬─────────┘     └──────────────────┘     └──────────────────┘
         │                        ▲
         │ MetaMask               │ Optional direct on-chain
         ▼                        │
┌──────────────────┐     ┌──────────────────┐
│  Reown AppKit    │     │  Raspberry Pi    │
│  (WalletConnect) │     │  DHT11 + Flask   │
└──────────────────┘     └──────────────────┘
```

**Data flow summary:**

1. Merchants register their identity via wallet, record suppliers, ingredients, and products on-chain, and set HACCP quality control rules.
2. When submitting production data, the smart contract automatically validates temperature, humidity, weight, pH, and other parameters for compliance.
3. Only compliant products can generate sales QR codes; consumers can scan to view full traceability information and register for recall alerts.
4. When an ingredient is contaminated, a cascading recall is triggered and related product statuses are automatically updated.

---

## Repository Structure

```
nutriguard/
├── Blockchain/          # Hardhat smart contracts (Solidity + tests + deployment scripts)
├── nutri_guard/         # Flutter cross-platform mobile application
├── nutriguard_iot/      # Raspberry Pi edge gateway (DHT11 temp/humidity + optional on-chain)
└── docx/                # Development and thesis documentation (Sepolia deployment, IoT integration, etc.)
```

| Module | Description | Detailed Docs |
|--------|-------------|---------------|
| `Blockchain/` | `NutriGuard.sol` main contract, Hardhat compile / test / Sepolia deploy | See "Blockchain Development" below |
| `nutri_guard/` | Merchant and consumer UI, Web3 interactions, QR codes, IPFS upload | [`nutri_guard/README_EN.md`](nutri_guard/README_EN.md) |
| `nutriguard_iot/` | Flask REST gateway, `/sensor/latest` for App to fetch sensor data | [`nutriguard_iot/README_EN.md`](nutriguard_iot/README_EN.md) |

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Smart Contract | Solidity 0.8.28 · OpenZeppelin 5.x · Hardhat 2.x |
| Blockchain Network | Sepolia Testnet (production demo); Hardhat local chain (development) |
| Mobile App | Flutter 3.8+ · Provider · GoRouter · Web3Dart |
| Wallet | Reown AppKit (WalletConnect) · MetaMask Mobile |
| Storage | Pinata IPFS (product images / certificates) |
| IoT | Raspberry Pi 3B+ · DHT11 · Flask · Python 3 |

---

## Core Features

### Merchant

- Wallet identity registration (Merchant role)
- Supplier / ingredient / product CRUD, ingredient storage environment settings
- HACCP quality control rules (temperature, humidity, weight, pH)
- Production data submission with automatic on-chain compliance verification
- QR code generation for compliant products; ingredient contamination marking and cascading recall
- Consumer feedback viewing and management

### Consumer

- Wallet identity registration (Consumer role)
- QR code scanning to verify product status and traceability information
- Register for product recall email alerts
- Submit 1–5 star ratings and text feedback on-chain

### IoT (Optional)

- Raspberry Pi DHT11 collects temperature/humidity, Flask exposes a REST API
- Flutter "Quality Control" page reads and populates production data from IoT device with one click
- Optional `chain_agent.py` for direct on-chain transaction submission from the edge node

---

## Quick Start

### Prerequisites

- [Node.js](https://nodejs.org/) ≥ 18
- [Flutter SDK](https://flutter.dev/) ≥ 3.8
- [MetaMask](https://metamask.io/) Mobile (Sepolia network + test ETH)
- (Optional) Raspberry Pi 3B+ and DHT11 sensor

### 1. Clone the Repository

```bash
git clone https://github.com/haoo04/nutriguard.git
cd nutriguard
```

### 2. Configure the Flutter App

```bash
cd nutri_guard
flutter pub get
```

Edit [`nutri_guard/lib/config/app_config.dart`](nutri_guard/lib/config/app_config.dart) and fill in the **required fields**:

```dart
// Sepolia RPC (Infura / Alchemy, etc.)
static const String sepoliaRpcUrl = 'https://sepolia.infura.io/v3/YOUR_KEY';

// Reown / WalletConnect Project ID (https://cloud.reown.com)
static const String walletConnectProjectId = 'YOUR_PROJECT_ID';

// Contract address (already deployed, usually no changes needed)
static const String nutriGuardContractAddress = '0xC1707AAa3b0dc69438c0122E4985586A811011c1';

// Use Sepolia testnet
static const bool useLocalBlockchain = false;
```

**IPFS image upload (optional):** Pass the Pinata JWT at runtime:

```bash
flutter run --dart-define=PINATA_JWT=your_pinata_jwt
```

And configure `pinataGatewayBaseUrl` in `app_config.dart`.

**IoT gateway (optional):** Change `iotGatewayBaseUrl` to the Raspberry Pi LAN address, e.g., `http://192.168.1.210:5000`.

### 3. Run the App

```bash
cd nutri_guard
flutter run
```

### 4. Connect MetaMask to Sepolia

1. Add **Sepolia Test Network** in MetaMask (Chain ID `11155111`).
2. Get test ETH from the [Sepolia Faucet](https://sepoliafaucet.com/).
3. On the App login page, select a role (Merchant / Consumer) → **Connect Wallet** → confirm connection and signature in MetaMask.
4. First-time login requires completing on-chain `registerUser` registration.

> In development mode (`AppConfig.isDevelopment = true`), the login page retains quick-access buttons for Hardhat preset accounts, convenient for local testing.

---

## Blockchain Development

### Install and Test

```bash
cd Blockchain
npm install
npm test
```

### Local Hardhat Testing

```bash
# Terminal 1: Start local chain
npx hardhat node

# Terminal 2: Deploy to localhost
npx hardhat run scripts/deploy.js --network localhost
```

The deployment script automatically updates [`nutri_guard/lib/config/contract_addresses.json`](nutri_guard/lib/config/contract_addresses.json). For local testing, set `useLocalBlockchain` to `true` in `app_config.dart` and update `ethereumRpcUrl` and the contract address.

### Redeploy to Sepolia

```bash
cd Blockchain
cp .env.example .env
# Edit .env: SEPOLIA_RPC_URL, PRIVATE_KEY, ETHERSCAN_API_KEY
npm run deploy:sepolia
```

`.env` example:

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
PRIVATE_KEY=your_deployer_private_key_without_0x
ETHERSCAN_API_KEY=your_etherscan_api_key
```

After successful deployment, sync the new contract address to `app_config.dart` and `contract_addresses.json`. Optional contract verification:

```bash
npm run verify:sepolia -- <CONTRACT_ADDRESS>
```

### Smart Contract Highlights

- **Roles:** Merchant / Consumer
- **HACCP Validation:** `submitProductionData` compares actual temperature, humidity, weight, and pH against product rules on-chain
- **Cascading Recall:** When an ingredient is marked contaminated, related products automatically become Contaminated and QR code generation is blocked
- **Security:** OpenZeppelin `Ownable` + `ReentrancyGuard`

Contract source: [`Blockchain/contracts/NutriGuard.sol`](Blockchain/contracts/NutriGuard.sol)

---

## IoT Module

The Raspberry Pi edge gateway provides `/health` and `/sensor/latest` endpoints. The Flutter App can read DHT11 data with one click on the "Quality Control" page.

```bash
cd nutriguard_iot
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python edge_gateway.py
```

Full hardware wiring, systemd auto-start, Mock mode, and end-to-end demo scripts are in [`nutriguard_iot/README_EN.md`](nutriguard_iot/README_EN.md).

---

## Testing

```bash
# Smart contract unit tests
cd Blockchain && npm test

# Flutter widget tests
cd nutri_guard && flutter test
```

---

## Configuration Reference

| Config Item | File | Description |
|-------------|------|-------------|
| RPC / Contract / Wallet / IPFS / IoT | `nutri_guard/lib/config/app_config.dart` | App main configuration |
| Deployment artifacts | `nutri_guard/lib/config/contract_addresses.json` | Auto-written by `deploy.js` |
| Sepolia deployment keys | `Blockchain/.env` | **Do not commit to Git** |
| IoT environment variables | `nutriguard_iot/.env` | Sensor GPIO, RPC, contract address, etc. |

---

## Security Notes

- **Testnet environment:** The current contract is deployed on Sepolia for demonstration and graduation project verification only; it has not undergone professional security audit.
- **Private key management:** Deployment private keys, Pinata JWT, and WalletConnect Project IDs should never be committed to the repository.
- **Hardhat preset accounts:** For local development only; never use these private keys on public networks.
- **On-chain gas:** Each write operation on Sepolia consumes test ETH; `submitProductionData` costs approximately 80k gas.

---

## Related Documentation
- [Flutter Module Documentation](nutri_guard/README_EN.md)
- [IoT Module Documentation](nutriguard_iot/README_EN.md)

---

## Disclaimer

This project is for academic demonstration and proof-of-concept purposes. Before using in a production environment or handling real food safety data, please conduct a thorough security audit, compliance assessment, and stress testing.

---

<p align="center">
  <sub>NutriGuard · Blockchain Food Traceability · FYP</sub>
</p>
