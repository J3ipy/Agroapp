import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CloudinaryService {
  static const _cloudName = 'j3ipy';
  static const _uploadPreset = 'agroapp_preset'; // O nome do preset Unsigned que criou

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // Retorna o link direto da imagem na nuvem!
      } else {
        debugPrint('Erro no upload do Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro excepção upload: $e');
      return null;
    }
  }
}