import 'dart:typed_data';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Define the provider
final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});


class CloudinaryService {


final cloudinary = Cloudinary.full(
apiKey: dotenv.env['CLOUDINARY_API_KEY']!, 
apiSecret: dotenv.env['CLOUDINARY_API_SECRET']!,
cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME']!,
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
      rethrow;
    }
  }
}
