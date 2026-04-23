"""NutriGuard 边缘网关 (M1).

负责:
    - 在后台线程按 ``SAMPLE_INTERVAL_S`` 周期采样 DHT11 温湿度
    - 用 ``collections.deque`` 做 ``WINDOW_SECONDS`` 滑动窗口缓冲
    - 通过 Flask 对外暴露 /health 与 /sensor/latest REST 接口
    - 读取失败不污染缓冲, 超过 ``STALE_THRESHOLD_S`` 无新样本标记 ``quality=stale``

环境变量:
    DEVICE_ID          设备唯一标识, 默认 ``rpi-nutriguard-01``
    PORT               监听端口, 默认 ``5000``
    SAMPLE_INTERVAL_S  采样间隔 (秒), 默认 ``2``
    WINDOW_SECONDS     滑窗长度 (秒), 默认 ``20``
    DHT_GPIO           DHT11 数据线使用的 BCM 编号, 默认 ``4``
    MOCK_SENSOR        设为 ``1`` 时用伪数据替代真实传感器, 方便在非 RPi 环境开发

运行:
    python edge_gateway.py
    # 或
    MOCK_SENSOR=1 python edge_gateway.py
"""

from __future__ import annotations

import logging
import os
import random
import threading
import time
from collections import deque
from statistics import mean
from typing import Any

from flask import Flask, jsonify, request
from flask_cors import CORS

DEVICE_ID = os.getenv("DEVICE_ID", "rpi-nutriguard-01")
PORT = int(os.getenv("PORT", "5000"))
SAMPLE_INTERVAL_S = float(os.getenv("SAMPLE_INTERVAL_S", "2"))
WINDOW_SECONDS = int(os.getenv("WINDOW_SECONDS", "20"))
STALE_THRESHOLD_S = WINDOW_SECONDS
DHT_GPIO = int(os.getenv("DHT_GPIO", "4"))
MOCK_SENSOR = os.getenv("MOCK_SENSOR", "0") == "1"

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
log = logging.getLogger("edge_gateway")


def _build_sensor() -> Any:
    """构造 DHT 读取对象. 当 ``MOCK_SENSOR=1`` 或导入失败时回退到伪实现."""
    if MOCK_SENSOR:
        log.warning("MOCK_SENSOR=1, 使用伪随机数据 (请仅用于非 RPi 环境调试)")
        return _MockDHT()

    try:
        import adafruit_dht
        import board
    except (ImportError, NotImplementedError) as err:
        log.error(f"导入 adafruit_dht/board 失败, 回退到 Mock: {err}")
        return _MockDHT()

    pin = getattr(board, f"D{DHT_GPIO}")
    return adafruit_dht.DHT11(pin, use_pulseio=False)


class _MockDHT:
    """开发环境伪传感器. 以 23°C / 55% 为基准做小幅漂移."""

    def __init__(self) -> None:
        self._t = 23.0
        self._h = 55.0

    @property
    def temperature(self) -> float:
        self._t += random.uniform(-0.3, 0.3)
        return round(self._t, 1)

    @property
    def humidity(self) -> float:
        self._h += random.uniform(-0.5, 0.5)
        return round(max(20.0, min(80.0, self._h)), 1)


dht = _build_sensor()
_buffer: deque[tuple[float, float, float]] = deque(
    maxlen=max(1, int(WINDOW_SECONDS / SAMPLE_INTERVAL_S))
)
_buffer_lock = threading.Lock()


def _sampler_loop() -> None:
    log.info(
        f"sampler start: device_id={DEVICE_ID} gpio=D{DHT_GPIO} "
        f"interval={SAMPLE_INTERVAL_S}s window={WINDOW_SECONDS}s mock={MOCK_SENSOR}"
    )
    while True:
        try:
            t = dht.temperature
            h = dht.humidity
            if t is not None and h is not None:
                with _buffer_lock:
                    _buffer.append((time.time(), float(t), float(h)))
                log.info(f"sample ok t={t} h={h}")
            else:
                log.debug("sample none, skip")
        except RuntimeError as err:
            # DHT11 时序偶发失败, 调试级别即可
            log.debug(f"sample retry: {err}")
        except Exception as err:  # noqa: BLE001
            log.exception(f"sampler fatal: {err}")
        time.sleep(SAMPLE_INTERVAL_S)


def latest_payload() -> dict[str, Any]:
    """返回滑窗平均后的最新读数. 供 REST 与直连上链脚本共用."""
    now = time.time()
    with _buffer_lock:
        fresh = [
            (ts, tc, hc)
            for (ts, tc, hc) in _buffer
            if now - ts <= STALE_THRESHOLD_S
        ]

    if not fresh:
        return {
            "device_id": DEVICE_ID,
            "timestamp": int(now),
            "temperature_c": None,
            "humidity_pct": None,
            "sample_count": 0,
            "quality": "stale",
        }

    return {
        "device_id": DEVICE_ID,
        "timestamp": int(now),
        "temperature_c": round(mean(tc for _, tc, _ in fresh), 1),
        "humidity_pct": round(mean(hc for _, _, hc in fresh), 1),
        "sample_count": len(fresh),
        "quality": "ok",
    }


app = Flask(__name__)
CORS(app)


@app.get("/health")
def health() -> Any:
    return {"status": "up", "device_id": DEVICE_ID, "mock": MOCK_SENSOR}


@app.get("/sensor/latest")
def sensor_latest() -> Any:
    return jsonify(latest_payload())


@app.post("/sensor/submit/<int:product_id>")
def sensor_submit(product_id: int) -> Any:
    """方案 B: 网关内直接触发 submitProductionData 上链.

    请求体 (可选):
        { "weight": 200, "ph": 0 }

    返回 chain_agent.submit_production_data 的结果字典.
    """
    # 延迟导入, 避免在未配置 .env 时启动网关也失败
    try:
        from chain_agent import submit_production_data
    except ImportError as err:
        return jsonify({"status": "failed", "error": f"chain_agent 不可用: {err}"}), 500

    body = request.get_json(silent=True) or {}
    weight = int(body.get("weight", 100))
    ph = int(body.get("ph", 0))

    try:
        result = submit_production_data(product_id, weight, ph)
    except Exception as err:  # noqa: BLE001
        log.exception("submit failed")
        return jsonify({"status": "failed", "error": str(err)}), 500

    http_code = 200 if result.get("status") == "ok" else 202
    return jsonify(result), http_code


def main() -> None:
    sampler = threading.Thread(target=_sampler_loop, daemon=True)
    sampler.start()
    log.info(f"edge gateway listening on 0.0.0.0:{PORT}")
    app.run(host="0.0.0.0", port=PORT, threaded=True)


if __name__ == "__main__":
    main()
