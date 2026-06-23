# NutriGuard - Blockchain Food Traceability System

<p align="center">
  <a href="README.md">中文</a> | <strong>English</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Blockchain-Ethereum-blue?style=flat-square" alt="Blockchain">
  <img src="https://img.shields.io/badge/Frontend-Flutter-blue?style=flat-square" alt="Frontend">
  <img src="https://img.shields.io/badge/Smart%20Contract-Solidity-red?style=flat-square" alt="Smart Contract">
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Version">
</p>

## Project Overview

**NutriGuard** is a blockchain-based food traceability application designed to enable merchants to quickly recall contaminated food from the market and from consumers, while allowing consumers to check product status by scanning a QR code. The system leverages the transparency, immutability, and decentralized nature of blockchain technology to enhance food safety and consumer trust.

This project is specifically designed for **restaurants** and similar food businesses, providing an end-to-end food safety traceability solution from ingredient procurement to final sale.

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Smart Contract │    │      IPFS       │
│  (Mobile UI)    │◄──►│ (Blockchain     │◄──►│ (File Storage)  │
│                 │    │  Logic)         │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MetaMask      │    │   Ethereum      │    │  Quality Control│
│ (Wallet Auth)   │    │ (Blockchain     │    │  System (HACCP) │
│                 │    │  Network)       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Tech Stack

### Blockchain Layer
- **Smart Contract**: Solidity ^0.8.28
- **Development Framework**: Hardhat ^2.26.3
- **Blockchain Network**: Ethereum (supports local testnet and Sepolia testnet)
- **Security Library**: OpenZeppelin Contracts ^5.4.0

### Frontend Application
- **Framework**: Flutter ^3.8.1
- **State Management**: Provider ^6.1.1
- **Routing**: GoRouter ^12.1.3
- **Blockchain Interaction**: Web3Dart ^2.7.3
- **QR Code**: QR Flutter ^4.1.0, Mobile Scanner ^3.5.6
- **Wallet Integration**: Reown AppKit ^1.0.1

### Storage & Integration
- **Decentralized Storage**: IPFS (for product images and certificates)
- **Local Storage**: SharedPreferences ^2.2.2
- **Data Format**: JSON

## Core Features

### Merchant Features

#### 1. Identity Verification & Management
- Decentralized identity authentication via MetaMask wallet
- Supports Merchant and Consumer role registration
- Secure private key management

#### 2. Supplier Management
- Register and manage supplier information
- Record supplier certification documents
- Maintain supplier contact information and active status

#### 3. Ingredient Traceability System
- **Ingredient Data Entry:**
  - Ingredient name, category, UPC code
  - Production date, expiry date, batch number
  - Associated supplier information
  - Storage environment requirements (temperature and humidity ranges)
  - Weight information
- **Status Management:**
  - Real-time ingredient status updates (Safe / Contaminated / Recalled)
  - Support for manual contamination marking
  - Automatic linking of affected products

#### 4. Food Production Management
- **Product Creation:**
  - Basic product information (name, description, UPC code)
  - Product category (Entree / Side / Beverage)
  - Associated ingredient list
  - Upload product images and certificates to IPFS
- **HACCP Quality Control:**
  - Set quality control rules based on international standards
  - Temperature range control (min/max temperature)
  - Humidity environment monitoring
  - Weight usage range
  - pH value control (for beverage products)
- **Production Data Validation:**
  - Real-time entry of production process data
  - Smart contract automatically verifies compliance
  - Non-compliant products automatically marked as "Alert" status

#### 5. Sales & QR Code Management
- **QR Code Generation:**
  - Only compliant products can generate QR codes
  - Unique product identifier
  - Contains complete traceability information
- **Sales Records:**
  - Record sale time and status
  - Link to registered consumer information

#### 6. Smart Alert System
- **Automatic Recall Mechanism:**
  - Automatically mark related products when ingredients are contaminated
  - Send alert emails to registered consumers
  - Prevent contaminated products from generating QR codes
- **Quality Warnings:**
  - Send alerts when production data is non-compliant
  - Detailed explanation of non-compliance reasons

### Consumer Features

#### 1. Product Verification & Traceability
- **QR Code Scanning:**
  - Scan product QR codes using the phone camera
  - Instantly retrieve complete product traceability information
- **Information Visualization:**
  - Product status display (Safe / Alert / Contaminated)
  - Production date and expiry date information
  - Ingredient source and supplier information
  - Production process quality data

#### 2. Safety Alert Registration
- **Product Registration:**
  - Option to register a product after scanning
  - Bind personal email address
  - Establish product-consumer association
- **Automatic Notifications:**
  - Automatically receive email notifications when product ingredients have issues
  - Recall information and safety recommendations
  - Merchant contact information

#### 3. Feedback System
- **Product Reviews:**
  - Submit product quality feedback
  - 1–5 star rating system
  - Detailed text description
- **Issue Reporting:**
  - Quickly report issues to merchants
  - Feedback stored on the blockchain
  - Ensures authenticity and immutability of feedback

## Business Flow

### Phase 1: Ingredient Collection

1. **Supplier Registration**: Merchants register detailed supplier information in the system
2. **Ingredient Entry**: Record ingredient name, UPC code, production date, expiry date, batch number, etc.
3. **Environment Setup**: Set storage temperature and humidity requirements
4. **Blockchain Record**: All information written to the blockchain, forming an immutable record

### Phase 2: Production Process

1. **Product Creation**: Enter product information and select ingredients used
2. **Rule Setting**: Set quality control rules based on HACCP standards
3. **Data Entry**: Manually enter actual production process data
4. **Automatic Validation**: Smart contract verifies whether data meets preset standards
5. **Status Update**: Update product status based on validation results

### Phase 3: Sales & Traceability

1. **Compliance Check**: Verify product and ingredient status
2. **QR Code Generation**: Only compliant products can generate sales QR codes
3. **Consumer Scanning**: Obtain complete product traceability information
4. **Alert Registration**: Consumers can register to receive safety alerts

## App Screens

### Merchant Interface
- **Dashboard**: System overview and key metrics
- **Supplier Management**: Supplier list, details, and creation pages
- **Ingredient Management**: Ingredient list, status monitoring, and add functionality
- **Product Management**: Product list, production status, and quality control
- **Quality Control**: HACCP rule setting and production data entry
- **QR Code Generator**: Generate sales QR codes for compliant products
- **Feedback Management**: View and manage consumer feedback

### Consumer Interface
- **QR Code Scanner**: Quickly scan product QR codes
- **Product Details**: Complete product traceability information display
- **My Alerts**: Registered products and received safety notifications
- **Submit Feedback**: Product ratings and issue reports
- **Profile**: Account information and settings

## Installation & Deployment

### Prerequisites
- Node.js >= 16.0.0
- Flutter SDK >= 3.8.1
- Git
- MetaMask browser extension or mobile app

### 1. Clone the Project
```bash
git clone <repository-url>
cd nutriguard
```

### 2. Blockchain Environment Setup
```bash
cd Blockchain
npm install
```

#### Start Local Blockchain Network
```bash
npx hardhat node
```

#### Deploy Smart Contract
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### 3. Flutter App Setup
```bash
cd nutri_guard
flutter pub get
```

#### Configure Network Address
Edit `lib/config/app_config.dart` and update the following:
```dart
static const String ethereumRpcUrl = 'http://YOUR_IP:8545';
static const String nutriGuardContractAddress = 'DEPLOYED_CONTRACT_ADDRESS';
```

#### Run the App
```bash
flutter run
```

### 4. MetaMask Configuration
1. Add local network:
   - Network Name: Hardhat Local
   - RPC URL: http://localhost:8545
   - Chain ID: 1337
   - Currency Symbol: ETH

2. Import test accounts:
   - Merchant account private key: `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d`
   - Consumer account private key: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

## Testing

### Smart Contract Tests
```bash
cd Blockchain
npx hardhat test
```

### Flutter App Tests
```bash
cd nutri_guard
flutter test
```

## Usage Guide

### Merchant Workflow
1. **Initial Setup:**
   - Connect merchant account using MetaMask
   - Register as Merchant role
   - Add supplier information

2. **Ingredient Management:**
   - Enter newly received ingredient information
   - Set storage environment requirements
   - Monitor ingredient status

3. **Product Production:**
   - Create new products and associate ingredients
   - Set HACCP quality control rules
   - Enter actual production data
   - Wait for smart contract validation

4. **Sales Preparation:**
   - Check product compliance status
   - Generate QR codes for compliant products
   - Print QR code labels

5. **Issue Handling:**
   - When notified of supplier contamination, mark related ingredients
   - View list of affected products
   - System automatically sends alerts to consumers

### Consumer Workflow
1. **Product Verification:**
   - Open the app and select the scan function
   - Scan the product QR code
   - View complete traceability information

2. **Safety Registration:**
   - Select "Register" on the product details page
   - Enter email address
   - Confirm registration

3. **Submit Feedback:**
   - Select "Feedback" on the product page
   - Fill in rating and issue description
   - Submit feedback

## Security Features

### Blockchain Security
- **Immutability**: All data written to the blockchain cannot be modified
- **Transparency**: All transactions and status changes are publicly verifiable
- **Decentralization**: No single point of failure, improved system reliability

### Smart Contract Security
- **Access Control**: Strict permission management to prevent unauthorized operations
- **Reentrancy Protection**: Uses OpenZeppelin's ReentrancyGuard
- **Input Validation**: Comprehensive parameter validation and boundary checks
- **Event Logging**: Detailed operation logs for auditing

### Application Security
- **Wallet Authentication**: Secure identity verification based on MetaMask
- **Data Encryption**: Sensitive data encrypted in local storage
- **Network Security**: HTTPS communication and API security

## Core Advantages

1. **Food Safety Assurance:**
   - End-to-end food traceability
   - Real-time quality monitoring
   - Rapid recall mechanism

2. **Technical Innovation:**
   - Blockchain technology ensures data authenticity
   - Smart contract automated validation
   - IPFS decentralized storage

3. **User Experience:**
   - Clean and intuitive mobile app interface
   - One-scan access to complete information
   - Automated alert system

4. **Compliance:**
   - Meets HACCP international standards
   - Supports food safety regulatory requirements
   - Complete audit trail

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork this project
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

Thanks to the following open source projects and communities:
- [OpenZeppelin](https://openzeppelin.com/) - Smart contract security library
- [Flutter](https://flutter.dev/) - Cross-platform mobile development framework
- [Hardhat](https://hardhat.org/) - Ethereum development environment
- [IPFS](https://ipfs.io/) - Decentralized storage network

---

**Disclaimer**: This project is for demonstration and educational purposes only. Please conduct thorough security auditing and testing before use in a production environment.
