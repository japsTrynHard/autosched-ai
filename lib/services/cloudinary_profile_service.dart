import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
  });

  final String secureUrl;
  final String publicId;
}

class CloudinaryProfileService {
  Future<CloudinaryUploadResult> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryUploadException(
        'Profile image backup is not configured yet. Add your Cloudinary cloud name and upload preset before saving a new photo.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final safeName = fileName.trim().isEmpty
        ? 'autosched_profile_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : fileName.trim();

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = CloudinaryConfig.profileFolder
      ..fields['tags'] = 'autosched_ai,profile_photo'
      ..fields['context'] = 'userId=$userId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
        ),
      );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final cloudinaryMessage = _readCloudinaryError(body);
      throw CloudinaryUploadException(
        _friendlyCloudinaryMessage(cloudinaryMessage) ??
            'Image upload failed. Please check your internet connection and Cloudinary upload preset.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const CloudinaryUploadException('Image upload returned an invalid response.');
    }

    final secureUrl = decoded['secure_url'];
    final publicId = decoded['public_id'];
    if (secureUrl is! String || secureUrl.trim().isEmpty) {
      throw const CloudinaryUploadException('Image upload succeeded, but no image link was returned.');
    }

    return CloudinaryUploadResult(
      secureUrl: secureUrl.trim(),
      publicId: publicId is String ? publicId.trim() : '',
    );
  }

  String? _friendlyCloudinaryMessage(String? message) {
    if (message == null || message.trim().isEmpty) return null;
    final lower = message.toLowerCase();
    if (lower.contains('unknown api key') || lower.contains('upload preset') || lower.contains('must supply api_key')) {
      return 'Image upload is not connected correctly. Current Cloudinary setup uses cloud name ${CloudinaryConfig.cloudName} and unsigned preset ${CloudinaryConfig.uploadPreset}. Make sure the preset exists and is unsigned.';
    }
    return message;
  }

  String? _readCloudinaryError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) return message.trim();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
