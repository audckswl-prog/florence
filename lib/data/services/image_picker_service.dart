import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 92,
      );
      return image;
    } catch (e) {
      // Handle permission errors or other exceptions
      debugPrint('Error picking image: $e');
      return null;
    }
  }
}
