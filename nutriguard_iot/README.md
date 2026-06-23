# NutriGuard IoT (Raspberry Pi 3B+ × DHT11)

<p align="center">
  <strong>中文</strong> | <a href="README_EN.md">English</a>
</p>

边缘网关 + 可选直连上链脚本, 配合主仓库 Flutter App 与 Hardhat 智能合约, 实现「温湿度自动采集 → 上链 → App 可视化」端到端 Demo.

---

## 目录结构

```
nutriguard_iot/
├── sensor_test.py            # M0 硬件连通性验收
├── edge_gateway.py           # M1 边缘网关 (Flask REST)
├── chain_agent.py            # M3 直连上链 (方案 B)
├── abi/
│   └── NutriGuard.json       # 从 Blockchain/artifacts 拷贝, 由 scripts/sync_abi.ps1 生成
├── scripts/
│   └── sync_abi.ps1          # Windows 开发机 → RPi 的 ABI 同步脚本
├── nutriguard-iot.service    # systemd 自启单元
├── .env.example              # 环境变量模板
├── requirements.txt
└── README.md
```

## 实施阶段对照

| 阶段 | 交付物 | 本仓库对应文件 |
|------|--------|---------------|
| M0 硬件打通 | DHT11 终端输出温湿度 | `sensor_test.py` |
| M1 边缘网关 | `/health`, `/sensor/latest` REST 接口 | `edge_gateway.py`, `nutriguard-iot.service` |
| M2 App 拉取 | Flutter 「从 IoT 设备读取」按钮 | `../nutri_guard/lib/services/iot_sensor_service.dart`, `../nutri_guard/lib/screens/quality/quality_control_screen.dart` |
| M3 直连上链 | `python chain_agent.py <pid>` 自动上链 | `chain_agent.py`, `/sensor/submit/<pid>` 接口 |
| M4 Demo 彩排 | 本 README 下方「端到端联调」一节 | 见 §7 |

---

## M1 快速开始

### 1. 在树莓派上拉取代码

```bash
cd ~
git clone <repo-url> nutriguard
cd nutriguard/nutriguard_iot
```

### 2. 创建虚拟环境并安装依赖

```bash
sudo apt install -y libgpiod-dev
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. 准备环境变量

```bash
cp .env.example .env
chmod 600 .env
# 按需修改 DEVICE_ID / DHT_GPIO 等
```

### 4. 验收传感器 (M0 已完成可跳过)

```bash
python sensor_test.py
```

期望连续 30 秒内 ≥ 80% 读取成功.

### 5. 启动边缘网关

```bash
python edge_gateway.py
```

另开终端:

```bash
curl http://localhost:5000/health
curl http://localhost:5000/sensor/latest
```

成功返回示例:

```json
{
  "device_id": "rpi-nutriguard-01",
  "timestamp": 1713312345,
  "temperature_c": 24.0,
  "humidity_pct": 57.5,
  "sample_count": 10,
  "quality": "ok"
}
```

### 6. 注册为 systemd 服务 (开机自启)

```bash
sudo cp nutriguard-iot.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nutriguard-iot
sudo systemctl status nutriguard-iot
journalctl -u nutriguard-iot -f
```

> 如果你不是以 `pi` 用户运行, 或项目路径不是 `/home/pi/nutriguard_iot/`, 请同步修改 `nutriguard-iot.service` 中的 `User` 与路径.

---

## 在非 RPi 环境调试 (Mock 模式)

Windows / macOS 开发机上没有 `adafruit_dht` 和 `board` 模块, 直接运行会报错.
设置 `MOCK_SENSOR=1` 即可用伪随机数据启动, 方便 Flutter 端并行开发:

```powershell
# PowerShell
$env:MOCK_SENSOR="1"; python edge_gateway.py
```

```bash
# Linux/macOS
MOCK_SENSOR=1 python edge_gateway.py
```

Flutter App 在手机端可通过 `http://<开发机局域网 IP>:5000/sensor/latest` 访问.

---

## M1 验收清单

- [ ] `curl :5000/health` 返回 `{"status": "up", ...}`
- [ ] `curl :5000/sensor/latest` 返回 `quality=ok` 的合理读数
- [ ] 用手心捂住 DHT11 5 秒, 再次请求温度/湿度显著变化
- [ ] 拔掉 DHT11 数据线, 20 秒后请求返回 `quality=stale`
- [ ] `systemctl restart nutriguard-iot` 后服务继续正常工作

全部通过即可进入 M2: Flutter App 侧的 `IoTSensorService` 集成.

---

## M2 Flutter 端改造摘要

已完成文件:

- `../nutri_guard/lib/config/app_config.dart` — 新增 `iotGatewayBaseUrl`, `iotFetchTimeout`
- `../nutri_guard/lib/services/iot_sensor_service.dart` — `SensorReading` 模型 + `IoTSensorService` HTTP 客户端
- `../nutri_guard/lib/screens/quality/quality_control_screen.dart` — 「提交生产数据」对话框新增 **「从 IoT 设备读取」** 按钮 + 状态展示
- `../nutri_guard/android/app/src/main/AndroidManifest.xml` — 添加 `INTERNET` 权限与 `usesCleartextTraffic`

**需要按实际部署修改的配置项**: `AppConfig.iotGatewayBaseUrl` 需改成树莓派局域网 IP (例如 `http://192.168.1.210:5000`).

**M2 验收**:

- [ ] Flutter 进入「质量控制」→ 选中未提交产品 → 对话框中出现 `从 IoT 设备读取` 按钮
- [ ] 点击后 Temperature / Humidity 字段自动填充为整数
- [ ] 按钮下方显示 `设备: rpi-nutriguard-01 · 采样时间: ... · 质量: ok` 绿色卡片
- [ ] 停掉树莓派网关后, 点击按钮显示红色错误卡片 (不 crash)

---

## M3 直连上链 (方案 B)

### 3.1 准备 ABI

```powershell
# Windows 开发机, 确保已执行过 npx hardhat compile
cd D:\nutriguard\nutriguard_iot
.\scripts\sync_abi.ps1 -RpiHost pi@nutriguard-rpi.local
```

### 3.2 配置 .env

```bash
# RPi 上
cd ~/nutriguard_iot
nano .env

# 重点修改:
#   ETH_RPC_URL=http://<开发机局域网 IP>:8545
#   CONTRACT_ADDRESS=<最新部署合约地址>
#   MERCHANT_PRIVATE_KEY=<商家账户私钥>
chmod 600 .env
```

### 3.3 手动触发

```bash
source .venv/bin/activate
# 参数: productId weight_g ph_x100
python chain_agent.py 1 200 0
```

成功输出示例:

```json
{
  "status": "ok",
  "tx_hash": "0xabc...",
  "block": 42,
  "temperature": 24,
  "humidity": 58,
  "weight": 200,
  "ph_value": 0,
  "device_id": "rpi-nutriguard-01",
  "sampled_at": 1713312345
}
```

### 3.4 通过 HTTP 触发

若边缘网关已启动:

```bash
curl -X POST http://localhost:5000/sensor/submit/1 \
     -H "Content-Type: application/json" \
     -d '{"weight": 200, "ph": 0}'
```

**M3 验收**:

- [ ] 首次提交某 `productId` 返回 `status=ok`
- [ ] 重复提交同一 `productId` 返回 `status=failed` 且 error 含 `already submitted`
- [ ] 传感器拔线时返回 `status=stale`
- [ ] 关闭 Hardhat 节点后返回 `status=failed` 且 error 指向 RPC 连接问题

---

## §7 端到端联调 (M4)

### 7.1 三端启动顺序

**1. 开发机 (Windows PowerShell)**

```powershell
cd D:\nutriguard\Blockchain
npx hardhat node --hostname 0.0.0.0

# 另开终端
cd D:\nutriguard\Blockchain
npx hardhat run scripts\deploy.js --network localhost
# 记下合约地址, 更新:
#   - D:\nutriguard\nutri_guard\lib\config\app_config.dart (nutriGuardContractAddress)
#   - RPi ~/nutriguard_iot/.env (CONTRACT_ADDRESS)

# 同步 ABI 到 RPi
cd D:\nutriguard\nutriguard_iot
.\scripts\sync_abi.ps1 -RpiHost pi@nutriguard-rpi.local
```

**2. 树莓派**

```bash
sudo systemctl restart nutriguard-iot
journalctl -u nutriguard-iot -f
# 另一个终端验证
curl http://localhost:5000/sensor/latest
```

**3. Flutter App**

```powershell
cd D:\nutriguard\nutri_guard
flutter run
# 以商家账户登录
```

### 7.2 Demo 剧本

| 时间 | 动作 | 预期现象 |
|------|------|---------|
| 0:00 | App 创建产品「冷藏沙拉」, HACCP 温度 2–8℃、湿度 85–95% | 产品状态 Pending |
| 0:30 | 「提交生产数据」→ 点击「从 IoT 设备读取」 | 温湿度自动填入 (室温 24℃ 不合规) |
| 0:45 | Weight 输入 200, Submit | 合约事件 ProductionDataSubmitted, compliant=false |
| 1:00 | 返回产品详情 | 状态 `Alert`, QR 按钮灰显 |
| 1:30 | 在 RPi 上 `python chain_agent.py 2 200 0` (对另一产品) | 命令行输出 `status=ok`, App 刷新看到自动上链数据 |
| 2:00 | 把 DHT11 捂在冰袋上 20 秒, 再次测试合规产品 | 状态 `Safe`, QR 按钮可点 |

### 7.3 典型故障速查

| 症状 | 检查点 |
|------|-------|
| Flutter 按钮点击后提示 `Connection refused` | `curl <RPi IP>:5000/health` 是否通; 手机和 RPi 是否同网段 |
| `curl` 能通但 App 报 `Cleartext HTTP not permitted` | AndroidManifest 的 `usesCleartextTraffic="true"` 是否生效, 重装 APK |
| `chain_agent.py` 报 `无法连接到 RPC 节点` | `hardhat node` 是否带 `--hostname 0.0.0.0`; 防火墙是否放行 8545 |
| 上链报 `Production data already submitted` | 该 productId 本合约只允许提交一次, 重启 hardhat 节点或新建产品 |
| `estimate_gas failed` | 多数因合约 require 失败 (如 productId 不存在或非本商家产品) |
| `attribute 'rawTransaction' not found` | web3.py 7.x 字段改为 `raw_transaction`; 脚本已做双兼容 |
