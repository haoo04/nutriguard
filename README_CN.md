# NutriGuard

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Network-Sepolia-627EEA?style=flat-square" alt="Sepolia">
  <img src="https://img.shields.io/badge/Contract-Solidity-red?style=flat-square" alt="Solidity">
  <img src="https://img.shields.io/badge/App-Flutter-02569B?style=flat-square" alt="Flutter">
  <img src="https://img.shields.io/badge/IoT-Raspberry%20Pi-C51A4A?style=flat-square" alt="Raspberry Pi">
  <img src="https://img.shields.io/badge/Version-1.0.0-green?style=flat-square" alt="Version">
</p>

基于区块链的食品追溯系统，面向西餐厅等餐饮企业，覆盖**原料采购 → HACCP 生产质控 → 二维码销售 → 消费者验证与召回**全链路。数据写入 Ethereum 智能合约，产品图片与证书存储于 IPFS，可选接入树莓派 DHT11 传感器实现温湿度自动采集。

> **当前状态：** `NutriGuard` 智能合约已部署至 **Sepolia 测试网**，Flutter 移动端可通过 MetaMask（WalletConnect / Reown AppKit）连接同一合约完成链上操作。

---

## 在线合约

| 项目 | 值 |
|------|-----|
| 网络 | Ethereum Sepolia Testnet |
| Chain ID | `11155111` |
| 合约地址 | [`0xC1707AAa3b0dc69438c0122E4985586A811011c1`](https://sepolia.etherscan.io/address/0xC1707AAa3b0dc69438c0122E4985586A811011c1) |
| 浏览器 | [Sepolia Etherscan](https://sepolia.etherscan.io/address/0xC1707AAa3b0dc69438c0122E4985586A811011c1) |

合约地址同步保存在 [`nutri_guard/lib/config/contract_addresses.json`](nutri_guard/lib/config/contract_addresses.json)。

---

## 系统架构

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Flutter App     │     │  NutriGuard.sol  │     │  Pinata / IPFS   │
│  (商家 / 消费者)   │◄───►│  (Sepolia 链上)   │◄───►│  (图片 / 证书)    │
└────────┬─────────┘     └──────────────────┘     └──────────────────┘
         │                        ▲
         │ MetaMask               │ 可选直连上链
         ▼                        │
┌──────────────────┐     ┌──────────────────┐
│  Reown AppKit    │     │  Raspberry Pi    │
│  (WalletConnect) │     │  DHT11 + Flask   │
└──────────────────┘     └──────────────────┘
```

**数据流概要：**

1. 商家通过钱包注册身份，链上录入供应商、原料与产品，并设定 HACCP 质控规则。
2. 提交生产数据时，智能合约自动校验温湿度、重量、pH 等是否合规。
3. 仅合规产品可生成销售二维码；消费者扫码可查看完整追溯信息并注册召回告警。
4. 原料污染时触发级联召回，关联产品状态自动更新。

---

## 仓库结构

```
nutriguard/
├── Blockchain/          # Hardhat 智能合约（Solidity + 测试 + 部署脚本）
├── nutri_guard/         # Flutter 跨平台移动应用
├── nutriguard_iot/      # 树莓派边缘网关（DHT11 温湿度 + 可选直连上链）
└── docx/                # 开发与论文文档（Sepolia 部署、IoT 联调等）
```

| 模块 | 说明 | 详细文档 |
|------|------|----------|
| `Blockchain/` | `NutriGuard.sol` 主合约，Hardhat 编译 / 测试 / Sepolia 部署 | 见下文「区块链开发」 |
| `nutri_guard/` | 商家端与消费者端 UI，Web3 交互，二维码，IPFS 上传 | [`nutri_guard/README.md`](nutri_guard/README.md) |
| `nutriguard_iot/` | Flask REST 网关，`/sensor/latest` 供 App 拉取传感器数据 | [`nutriguard_iot/README.md`](nutriguard_iot/README.md) |

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 智能合约 | Solidity 0.8.28 · OpenZeppelin 5.x · Hardhat 2.x |
| 区块链网络 | Sepolia 测试网（生产演示）；Hardhat 本地链（开发调试） |
| 移动应用 | Flutter 3.8+ · Provider · GoRouter · Web3Dart |
| 钱包 | Reown AppKit（WalletConnect）· MetaMask Mobile |
| 存储 | Pinata IPFS（产品图片 / 证书） |
| IoT | Raspberry Pi 3B+ · DHT11 · Flask · Python 3 |

---

## 核心功能

### 商家

- 钱包身份注册（Merchant 角色）
- 供应商 / 原料 / 产品 CRUD，原料储存环境设定
- HACCP 质控规则（温度、湿度、重量、pH）
- 生产数据提交与链上自动合规校验
- 合规产品二维码生成；原料污染标记与召回级联
- 消费者反馈查看与处理

### 消费者

- 钱包身份注册（Consumer 角色）
- 扫描二维码验证产品状态与追溯信息
- 注册产品召回邮件告警
- 链上提交 1–5 星评价与文字反馈

### IoT（可选）

- 树莓派 DHT11 采集温湿度，Flask 暴露 REST 接口
- Flutter「质量控制」页面一键从 IoT 设备读取并填充生产数据
- 可选 `chain_agent.py` 从边缘节点直连提交链上交易

---

## 快速开始

### 前置要求

- [Node.js](https://nodejs.org/) ≥ 18
- [Flutter SDK](https://flutter.dev/) ≥ 3.8
- [MetaMask](https://metamask.io/) Mobile（Sepolia 网络 + 测试 ETH）
- （可选）Raspberry Pi 3B+ 与 DHT11 传感器

### 1. 克隆仓库

```bash
git clone https://github.com/haoo04/nutriguard.git
cd nutriguard
```

### 2. 配置 Flutter 应用

```bash
cd nutri_guard
flutter pub get
```

编辑 [`nutri_guard/lib/config/app_config.dart`](nutri_guard/lib/config/app_config.dart)，填入以下**必填项**：

```dart
// Sepolia RPC（Infura / Alchemy 等）
static const String sepoliaRpcUrl = 'https://sepolia.infura.io/v3/YOUR_KEY';

// Reown / WalletConnect Project ID（https://cloud.reown.com）
static const String walletConnectProjectId = 'YOUR_PROJECT_ID';

// 合约地址（已部署，一般无需修改）
static const String nutriGuardContractAddress = '0xC1707AAa3b0dc69438c0122E4985586A811011c1';

// 使用 Sepolia 测试网
static const bool useLocalBlockchain = false;
```

**IPFS 图片上传（可选）：** 运行时传入 Pinata JWT：

```bash
flutter run --dart-define=PINATA_JWT=your_pinata_jwt
```

并在 `app_config.dart` 中配置 `pinataGatewayBaseUrl`。

**IoT 网关（可选）：** 将 `iotGatewayBaseUrl` 改为树莓派局域网地址，例如 `http://192.168.1.210:5000`。

### 3. 运行应用

```bash
cd nutri_guard
flutter run
```

### 4. MetaMask 连接 Sepolia

1. 在 MetaMask 中添加 **Sepolia Test Network**（Chain ID `11155111`）。
2. 从 [Sepolia Faucet](https://sepoliafaucet.com/) 领取测试 ETH。
3. 在 App 登录页选择角色（商家 / 消费者）→ **Connect Wallet** → 在 MetaMask 中确认连接与签名。
4. 首次登录需完成链上 `registerUser` 注册。

> 开发模式下（`AppConfig.isDevelopment = true`）登录页仍保留 Hardhat 预设账户快捷入口，便于本地联调。

---

## 区块链开发

### 安装与测试

```bash
cd Blockchain
npm install
npm test
```

### 本地 Hardhat 联调

```bash
# 终端 1：启动本地链
npx hardhat node

# 终端 2：部署到 localhost
npx hardhat run scripts/deploy.js --network localhost
```

部署脚本会自动更新 [`nutri_guard/lib/config/contract_addresses.json`](nutri_guard/lib/config/contract_addresses.json)。本地联调时将 `app_config.dart` 中 `useLocalBlockchain` 设为 `true`，并更新 `ethereumRpcUrl` 与合约地址。

### 重新部署到 Sepolia

```bash
cd Blockchain
cp .env.example .env
# 编辑 .env：SEPOLIA_RPC_URL、PRIVATE_KEY、ETHERSCAN_API_KEY
npm run deploy:sepolia
```

`.env` 示例：

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your_project_id
PRIVATE_KEY=your_deployer_private_key_without_0x
ETHERSCAN_API_KEY=your_etherscan_api_key
```

部署成功后，将新合约地址同步到 `app_config.dart` 与 `contract_addresses.json`。可选验证合约：

```bash
npm run verify:sepolia -- <CONTRACT_ADDRESS>
```

### 智能合约要点

- **角色：** Merchant / Consumer
- **HACCP 校验：** `submitProductionData` 在链上比对实际温湿度、重量、pH 与产品规则
- **召回级联：** 原料标记污染后，关联产品自动变为 Contaminated，禁止生成 QR
- **安全：** OpenZeppelin `Ownable` + `ReentrancyGuard`

合约源码：[`Blockchain/contracts/NutriGuard.sol`](Blockchain/contracts/NutriGuard.sol)

---

## IoT 模块

树莓派边缘网关提供 `/health` 与 `/sensor/latest` 接口，Flutter App 在「质量控制」页面可一键读取 DHT11 数据。

```bash
cd nutriguard_iot
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
python edge_gateway.py
```

完整硬件接线、systemd 自启、Mock 模式与端到端 Demo 剧本见 [`nutriguard_iot/README.md`](nutriguard_iot/README.md)。

---

## 测试

```bash
# 智能合约单元测试
cd Blockchain && npm test

# Flutter Widget 测试
cd nutri_guard && flutter test
```

---

## 配置参考

| 配置项 | 文件 | 说明 |
|--------|------|------|
| RPC / 合约 / 钱包 / IPFS / IoT | `nutri_guard/lib/config/app_config.dart` | App 主配置 |
| 部署产物 | `nutri_guard/lib/config/contract_addresses.json` | 由 `deploy.js` 自动写入 |
| Sepolia 部署密钥 | `Blockchain/.env` | **勿提交 Git** |
| IoT 环境变量 | `nutriguard_iot/.env` | 传感器 GPIO、RPC、合约地址等 |

---

## 安全说明

- **测试网环境：** 当前合约部署在 Sepolia，仅供演示与毕业设计验证，未经专业安全审计。
- **私钥管理：** 部署私钥、Pinata JWT、WalletConnect Project ID 均不应提交到版本库。
- **Hardhat 预设账户：** 仅用于本地开发，切勿在公网使用其私钥。
- **链上 Gas：** Sepolia 上每笔写操作需消耗测试 ETH；`submitProductionData` 约 80k gas。

---

## 相关文档
- [Flutter 模块说明](nutri_guard/README.md)
- [IoT 模块说明](nutriguard_iot/README.md)

---

## 免责声明

本项目为学术演示与概念验证用途。在生产环境或处理真实食品安全数据前，请进行完整的安全审计、合规评估与压力测试。

---

<p align="center">
  <sub>NutriGuard · Blockchain Food Traceability · FYP</sub>
</p>
