"""NutriGuard 直连上链脚本 (M3, 方案 B 全自动模式).

职责:
    - 从边缘网关 ``latest_payload()`` 读取最新温湿度
    - 按合约 ``submitProductionData`` 接口构造交易并广播
    - 交易管理: nonce / gas 估算 / 失败重试

使用:
    # 手动触发一次 (productId=1, weight=200g, ph=0)
    python chain_agent.py 1 200 0

    # 通过网关 POST 接口触发 (见 edge_gateway.py 的 /sensor/submit/<pid>)

配置 (见 .env.example):
    ETH_RPC_URL, CHAIN_ID, MERCHANT_PRIVATE_KEY,
    CONTRACT_ADDRESS, ABI_PATH

注意:
    合约约定 temperature 为 int256 (℃), humidity/weight/phValue 为 uint256.
    DHT11 精度仅 ±2℃/±5% RH, 上链前四舍五入为整数.
    同一 productId 只能提交一次生产数据 (合约校验), 重复调用会回滚.
"""

from __future__ import annotations

import json
import logging
import os
import sys
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from web3 import Web3
from web3.exceptions import ContractLogicError

from edge_gateway import latest_payload

load_dotenv()

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
log = logging.getLogger("chain_agent")


def _load_contract() -> tuple[Web3, Any, Any]:
    rpc = os.environ["ETH_RPC_URL"]
    chain_id = int(os.environ["CHAIN_ID"])
    pk = os.environ["MERCHANT_PRIVATE_KEY"]
    addr = os.environ["CONTRACT_ADDRESS"]
    abi_path = Path(os.environ["ABI_PATH"])

    w3 = Web3(Web3.HTTPProvider(rpc))
    if not w3.is_connected():
        raise RuntimeError(f"无法连接到 RPC 节点: {rpc}")

    if not abi_path.exists():
        raise FileNotFoundError(
            f"ABI 文件不存在: {abi_path}\n"
            f"请从开发机执行: scp Blockchain/artifacts/contracts/NutriGuard.sol/"
            f"NutriGuard.json pi@<rpi>:~/nutriguard_iot/abi/"
        )

    artifact = json.loads(abi_path.read_text(encoding="utf-8"))
    abi = artifact["abi"] if "abi" in artifact else artifact

    contract = w3.eth.contract(address=Web3.to_checksum_address(addr), abi=abi)
    acct = w3.eth.account.from_key(pk)
    log.info(f"chain agent ready: signer={acct.address} chainId={chain_id}")
    return w3, contract, acct


def submit_production_data(
    product_id: int,
    weight_g: int = 100,
    ph_x100: int = 0,
    *,
    max_retries: int = 3,
) -> dict[str, Any]:
    """读取最新 DHT11 数据并调用 ``submitProductionData``.

    Returns:
        结果字典, 包含 ``status`` 字段:
            ``"ok"``       上链成功, 额外返回 ``tx_hash`` / ``block``
            ``"stale"``    传感器数据过期, 已跳过
            ``"failed"``   交易失败, 额外返回 ``error``
    """
    payload = latest_payload()
    if payload["quality"] != "ok":
        log.warning(f"sensor stale, skip: {payload}")
        return {"status": "stale", "payload": payload}

    t_int = int(round(payload["temperature_c"]))
    h_int = int(round(payload["humidity_pct"]))

    w3, contract, acct = _load_contract()
    chain_id = int(os.environ["CHAIN_ID"])

    log.info(
        f"submit product_id={product_id} T={t_int}°C H={h_int}% "
        f"W={weight_g}g pH={ph_x100}"
    )

    last_err: str | None = None
    for attempt in range(1, max_retries + 1):
        try:
            nonce = w3.eth.get_transaction_count(acct.address, "pending")
            fn = contract.functions.submitProductionData(
                product_id, t_int, h_int, weight_g, ph_x100
            )
            # 先估算 gas, 失败则按固定上限兜底
            try:
                gas_estimate = fn.estimate_gas({"from": acct.address})
                gas_limit = int(gas_estimate * 1.2)
            except Exception as err:  # noqa: BLE001
                log.warning(f"estimate_gas failed, fallback to 500k: {err}")
                gas_limit = 500_000

            tx = fn.build_transaction(
                {
                    "from": acct.address,
                    "nonce": nonce,
                    "chainId": chain_id,
                    "gas": gas_limit,
                    "gasPrice": w3.to_wei("1", "gwei"),
                }
            )
            signed = acct.sign_transaction(tx)
            raw = getattr(signed, "rawTransaction", None) or signed.raw_transaction
            tx_hash = w3.eth.send_raw_transaction(raw)
            receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)
            log.info(
                f"tx mined: block={receipt.blockNumber} "
                f"status={receipt.status} hash={tx_hash.hex()}"
            )
            if receipt.status != 1:
                last_err = f"tx reverted in block {receipt.blockNumber}"
                continue
            return {
                "status": "ok",
                "tx_hash": tx_hash.hex(),
                "block": receipt.blockNumber,
                "temperature": t_int,
                "humidity": h_int,
                "weight": weight_g,
                "ph_value": ph_x100,
                "device_id": payload["device_id"],
                "sampled_at": payload["timestamp"],
            }
        except ContractLogicError as err:
            # 合约层 require 失败通常不该重试, 如 "Production data already submitted"
            log.error(f"contract revert: {err}")
            return {"status": "failed", "error": f"contract revert: {err}"}
        except Exception as err:  # noqa: BLE001
            last_err = str(err)
            log.warning(f"attempt {attempt}/{max_retries} failed: {err}")

    return {"status": "failed", "error": last_err or "unknown"}


def main() -> None:
    product_id = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    weight = int(sys.argv[2]) if len(sys.argv) > 2 else 100
    ph = int(sys.argv[3]) if len(sys.argv) > 3 else 0
    result = submit_production_data(product_id, weight, ph)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0 if result["status"] == "ok" else 1)


if __name__ == "__main__":
    main()
