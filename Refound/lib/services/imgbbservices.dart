import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
class ImgbbService {
  static const _apiKey = '9f2374aeb028270aab9a5df60e039f19';
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