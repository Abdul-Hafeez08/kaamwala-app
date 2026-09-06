import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get _uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> pickImageFromCamera() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String> uploadImage({File? imageFile, Uint8List? webBytes}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = _uploadPreset;

      if (webBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webBytes,
            filename: 'web_image.jpg',
          ),
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', imageFile.path),
        );
      } else {
        throw 'No image provided for upload.';
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        final imageUrl = jsonResponse['secure_url'] as String;
        return imageUrl;
      } else {
        throw 'Failed to upload image. Please try again.';
      }
    } catch (error) {
      if (error is String) rethrow;
      throw 'Failed to upload image. Check your internet connection.';
    }
  }
}
