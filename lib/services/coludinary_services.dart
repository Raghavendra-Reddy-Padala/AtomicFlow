import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) => CloudinaryService());

class CloudinaryService {
  final cloudinary = CloudinaryPublic('your-cloud-name', 'your-upload-preset');

  Future<String> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'habit_tracker_profiles',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }
}