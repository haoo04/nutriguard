import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// 边缘网关 `/sensor/latest` 返回的数据契约.
///
/// 契约定义见 `docx/树莓派_DHT11_自动化开发文档.md` 第 6 节.
class SensorReading {
  final String deviceId;
  final int timestamp;
  final double? temperatureC;
  final double? humidityPct;
  final int sampleCount;
  final String quality;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.temperatureC,
    required this.humidityPct,
    required this.sampleCount,
    required this.quality,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: json['device_id'] as String? ?? 'unknown',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPct: (json['humidity_pct'] as num?)?.toDouble(),
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      quality: json['quality'] as String? ?? 'error',
    );
  }

  /// 返回人类可读的采样时间 (本地时区).
  DateTime get sampledAt =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: false);

  /// 数据是否可用于自动填表 / 上链.
  bool get isUsable =>
      quality == 'ok' && temperatureC != null && humidityPct != null;
}

/// 封装对边缘网关 (Raspberry Pi) 的 HTTP 访问.
class IoTSensorService {
  IoTSensorService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.iotGatewayBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// 拉取最新一次滑窗平均读数.
  ///
  /// 网络错误或非 200 响应都会抛出 [IoTGatewayException].
  Future<SensorReading> fetchLatest() async {
    final uri = Uri.parse('$_baseUrl/sensor/latest');
    try {
      final resp = await _client.get(uri).timeout(AppConfig.iotFetchTimeout);
      if (resp.statusCode != 200) {
        throw IoTGatewayException(
          '网关响应异常: HTTP ${resp.statusCode}',
          statusCode: resp.statusCode,
        );
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw IoTGatewayException('网关返回的 JSON 结构无法解析');
      }
      return SensorReading.fromJson(decoded);
    } on IoTGatewayException {
      rethrow;
    } catch (err) {
      throw IoTGatewayException('无法连接到 IoT 网关 $uri: $err');
    }
  }

  /// 简单健康检查, 供「设置」页面诊断用.
  Future<bool> ping() async {
    final uri = Uri.parse('$_baseUrl/health');
    try {
      final resp = await _client.get(uri).timeout(AppConfig.iotFetchTimeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

class IoTGatewayException implements Exception {
  final String message;
  final int? statusCode;

  const IoTGatewayException(this.message, {this.statusCode});

  @override
  String toString() => 'IoTGatewayException: $message';
}
