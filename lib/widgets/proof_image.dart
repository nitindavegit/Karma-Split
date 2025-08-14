import 'package:flutter/material.dart';

class ProofImage extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;
  const ProofImage({
    super.key,
    required this.onTakePhoto,
    required this.onChooseFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = OutlinedButton.styleFrom(
      side: BorderSide(
        color: Colors.blue.shade400,
        width: 1.5,
        style: BorderStyle.solid,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Proof Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              style: buttonStyle,
              onPressed: onTakePhoto,
              icon: const Icon(Icons.camera_alt, color: Colors.blue),
              label: const Text(
                'Take Photo',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              style: buttonStyle,
              onPressed: onChooseFromGallery,
              icon: const Icon(Icons.photo_library, color: Colors.blue),
              label: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
