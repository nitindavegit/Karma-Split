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

    final takePhotoButton = OutlinedButton.icon(
      style: buttonStyle,
      onPressed: onTakePhoto,
      icon: const Icon(Icons.camera_alt, color: Colors.blue),
      label: const Text(
        'Take Photo',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );

    final chooseFromGalleryButton = OutlinedButton.icon(
      style: buttonStyle,
      onPressed: onChooseFromGallery,
      icon: const Icon(Icons.photo_library, color: Colors.blue),
      label: const Text(
        'Choose from Gallery',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
    );

    const gap = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Proof Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // On narrow screens, stacking prevents RenderFlex overflow.
            // On wider screens, keep a 2-column layout.
            final isNarrow = constraints.maxWidth < 420;

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  takePhotoButton,
                  const SizedBox(height: gap),
                  chooseFromGalleryButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: takePhotoButton),
                const SizedBox(width: gap),
                Expanded(child: chooseFromGalleryButton),
              ],
            );
          },
        ),
      ],
    );
  }
}
