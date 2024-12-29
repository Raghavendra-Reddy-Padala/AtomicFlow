// ignore: file_names
// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habit_tracker/services/coludinary_services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Uint8List? _imageFile;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let\'s Set Up\nYour Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      background: Paint()
                        ..strokeWidth = 24
                        ..color = colorScheme.primary.withOpacity(0.1)
                        ..style = PaintingStyle.stroke
                        ..strokeJoin = StrokeJoin.round,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Enhanced Profile Image Picker
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.2),
                                colorScheme.secondary.withOpacity(0.2),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 64,
                            backgroundColor: Colors.transparent,
                            backgroundImage: _imageFile != null
                                ? MemoryImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: colorScheme.primary,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Enhanced Username Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Enhanced Description Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'About Me',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        prefixIcon: Icon(
                          Icons.edit_note_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Enhanced Save Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              'Complete Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _imageFile = Uint8List.fromList(bytes); // Use Uint8List
    });
  }
}

 Future<void> _handleSave() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);
  try {
    String? imageUrl;
   imageUrl = await ref.read(cloudinaryServiceProvider).uploadImage(
  _imageFile!,
  
);
    await ref.read(userServiceProvider).createUserProfile(
      username: _usernameController.text,
      description: _descriptionController.text,
      profileImageUrl: imageUrl,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving profile: $e')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
}