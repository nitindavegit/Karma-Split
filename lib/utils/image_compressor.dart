import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Compresses an image file to reduce its size before uploading.
///
/// [imageFile] - The original image file to compress
/// [quality] - The compression quality (0-100), default is 80
/// Returns a [File] containing the compressed image
Future<File> compressImage(File imageFile, {int quality = 80}) async {
  try {
    // Get the file path
    final filePath = imageFile.absolute.path;

    // Generate a new file path for the compressed image
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath =
        '${dir.absolute.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Compress the image
    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      targetPath,
      quality: quality,
    );

    if (result == null) {
      // If compression fails, return the original file
      return imageFile;
    }

    // Return the compressed file
    return File(result.path);
  } catch (e) {
    // If any error occurs, return the original file
    return imageFile;
  }
}

/// Compresses image bytes directly.
///
/// [imageBytes] - The original image bytes
/// [quality] - The compression quality (0-100), default is 80
/// Returns compressed [Uint8List]
Future<Uint8List> compressImageBytes(
  Uint8List imageBytes, {
  int quality = 80,
}) async {
  try {
    // Create a temporary file from the bytes
    final dir = await path_provider.getTemporaryDirectory();
    final tempFile = File(
      '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(imageBytes);

    // Compress the image
    final compressedFile = await compressImage(tempFile, quality: quality);
    final compressedBytes = await compressedFile.readAsBytes();

    // Clean up the temporary file
    try {
      await tempFile.delete();
    } catch (_) {}

    return compressedBytes;
  } catch (e) {
    // If any error occurs, return the original bytes
    return imageBytes;
  }
}
