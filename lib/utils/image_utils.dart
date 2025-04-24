// lib/utils/image_utils.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Utility class for image operations
class ImageUtils {
  static final _picker = ImagePicker();
  
  /// Pick image from camera
  static Future<File?> pickImageFromCamera({int maxWidth = 800, int maxHeight = 800}) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
  
  /// Pick image from gallery
  static Future<File?> pickImageFromGallery({int maxWidth = 800, int maxHeight = 800}) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
  
  /// Compress image file
  static Future<File> compressImage(File file, {int quality = 85}) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image == null) {
      return file;
    }
    
    // Resize if image is too large
    img.Image resized;
    if (image.width > 1024 || image.height > 1024) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1024 : null,
        height: image.height >= image.width ? 1024 : null,
      );
    } else {
      resized = image;
    }
    
    // Encode the image to JPEG with the specified quality
    final compressedBytes = img.encodeJpg(resized, quality: quality);
    
    // Create a new file for the compressed image
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressedFile = File(targetPath);
    
    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
  }
  
  /// Convert File to Base64 string
  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64.encode(bytes);
  }
  
  /// Convert Base64 string to File
  static Future<File> base64ToFile(String base64String, String fileName) async {
    final bytes = base64.decode(base64String);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    
    await file.writeAsBytes(bytes);
    return file;
  }
  
  /// Get image dimensions
  static Future<Size> getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image != null) {
      return Size(image.width.toDouble(), image.height.toDouble());
    }
    
    return Size.zero;
  }
  
  /// Generate a placeholder image with text
  static Future<File> generatePlaceholderImage(
    String text, 
    {int width = 300, int height = 300, Color backgroundColor = Colors.grey}
  ) async {
    // Create a blank image with the specified dimensions
    final image = img.Image(width: width, height: height);
    
    // Fill the image with the background color
    img.fill(image, color: img.ColorRgb8(
      backgroundColor.r.toInt(), 
      backgroundColor.g.toInt(),
      backgroundColor.b.toInt()
    ));
        
    // Encode the image to PNG
    final pngBytes = img.encodePng(image);
    
    // Save the image to a file
    final dir = await getTemporaryDirectory();
    final targetPath = '${dir.path}/placeholder_${DateTime.now().millisecondsSinceEpoch}.png';
    final placeholderFile = File(targetPath);
    
    await placeholderFile.writeAsBytes(pngBytes);
    return placeholderFile;
  }
}