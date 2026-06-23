import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';

class PinataIpfsService {
  static final PinataIpfsService _instance = PinataIpfsService._internal();
  factory PinataIpfsService() => _instance;
  PinataIpfsService._internal();

  bool get isConfigured => AppConfig.pinataJwt.trim().isNotEmpty;

  String gatewayUrl(String ipfsHash) {
    return '${AppConfig.pinataGatewayBaseUrl}/$ipfsHash';
  }

  Future<String> uploadImage({
    required XFile image,
    required String name,
  }) async {
    final jwt = AppConfig.pinataJwt.trim();
    if (jwt.isEmpty) {
      throw Exception(
        'Pinata JWT is not configured. Run with --dart-define=PINATA_JWT=your_token',
      );
    }

    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected image is empty');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.pinataUploadUrl),
    )
      ..headers['Authorization'] = 'Bearer $jwt'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name.isEmpty ? '$name.jpg' : image.name,
        ),
      )
      ..fields['pinataMetadata'] = jsonEncode({
        'name': name,
        'keyvalues': {
          'app': AppConfig.appName,
          'type': 'merchant-image',
        },
      });

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Pinata upload failed (${response.statusCode}): $responseBody');
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final ipfsHash = data['IpfsHash'] as String?;
    if (ipfsHash == null || ipfsHash.isEmpty) {
      throw Exception('Pinata response did not include IpfsHash');
    }

    return ipfsHash;
  }
}
