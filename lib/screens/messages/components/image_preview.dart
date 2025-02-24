import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  final Uint8List imageData;

  const ImagePreview({
    super.key,
    required this.imageData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(
            imageData,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
