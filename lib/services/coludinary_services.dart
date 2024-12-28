import 'dart:typed_data';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Define the provider
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});


class CloudinaryService {
  final cloudinary = Cloudinary.full(
    apiKey: "962566458489927", // Replace with your Cloudinary API Key
    apiSecret: "_MNwZNtNcslZ8xTdurUmqI3a2IA", // Replace with your Cloudinary API Secret
    cloudName: "dg4k2yqku", // Replace with your Cloudinary Cloud Name
  );
  final ImagePicker _picker = ImagePicker();

  // Method to pick image from gallery or camera
  Future<Uint8List?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
  Future<String> uploadImage(Uint8List imageBytes, ) async {
    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          fileBytes: imageBytes,
          resourceType: CloudinaryResourceType.image,
          folder: 'habit_tracker_profiles',
        ),
      );

      if (response.isSuccessful) {
        return response.secureUrl!;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }
}
