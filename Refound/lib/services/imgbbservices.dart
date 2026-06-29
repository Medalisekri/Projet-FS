import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImgbbService {
  static String get _apiKey => dotenv.env['IMGBB_API_KEY'] ?? '';
  // ── Mobile upload ─────────────────────────────────────
  static Future<String?> uploadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return _upload(bytes);
  }

  // ── Web upload ────────────────────────────────────────
  static Future<String?> uploadImageBytes(Uint8List bytes) async {
    return _upload(bytes);
  }
  static Future<String?> _upload(List<int> bytes) async {
    try {
      final base64Image = base64Encode(bytes);
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
        body: {'image': base64Image},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}