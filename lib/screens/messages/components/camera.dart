import 'dart:typed_data';

import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isInitialized = false;
  imglib.Image? memoryImage;
  Uint8List? jpgBytes;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      _controller = CameraController(
          cameras[0], // Use the first available camera
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.jpeg);

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  imglib.Image imageFromBGRA8888(CameraImage image) {
    return imglib.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: imglib.ChannelOrder.bgra,
    );
  }

  imglib.Image imageFromYUV420(CameraImage image) {
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 0;
    final img = imglib.Image(width: image.width, height: image.height);
    for (final p in img) {
      final x = p.x;
      final y = p.y;
      final uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
      final index = y * uvRowStride +
          x; // Use the row stride instead of the image width as some devices pad the image data, and in those cases the image width != bytesPerRow. Using width will give you a distored image.
      final yp = image.planes[0].bytes[index];
      final up = image.planes[1].bytes[uvIndex];
      final vp = image.planes[2].bytes[uvIndex];
      p.r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
      p.g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
          .round()
          .clamp(0, 255)
          .toInt();
      p.b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();
    }

    return img;
  }

  imglib.Image imageFromNV21(CameraImage image) {
    final img = imglib.Image(width: image.width, height: image.height);
    final yPlane = image.planes[0].bytes;
    final vuPlane = image.planes[1].bytes;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 0;

    for (final p in img) {
      final x = p.x;
      final y = p.y;
      final yIndex = y * image.width + x;
      final uvIndex =
          uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();

      final yp = yPlane[yIndex];
      final v = vuPlane[uvIndex];
      final u = vuPlane[uvIndex + 1];

      // YUV to RGB conversion
      p.r = (yp + 1.370705 * (v - 128)).round().clamp(0, 255).toInt();
      p.g = (yp - 0.337633 * (u - 128) - 0.698001 * (v - 128))
          .round()
          .clamp(0, 255)
          .toInt();
      p.b = (yp + 1.732446 * (u - 128)).round().clamp(0, 255).toInt();
    }

    return img;
  }

  imglib.Image imageFromJPEG(CameraImage image) {
    return imglib.decodeJpg(image.planes[0].bytes)!;
  }

  imglib.Image? imageFromCameraImage(CameraImage image) {
    try {
      imglib.Image img;
      switch (image.format.group) {
        case ImageFormatGroup.yuv420:
          img = imageFromYUV420(image);
          break;
        case ImageFormatGroup.bgra8888:
          img = imageFromBGRA8888(image);
          break;
        case ImageFormatGroup.jpeg:
          img = imageFromJPEG(image);
          break;
        case ImageFormatGroup.nv21:
          img = imageFromNV21(image);
          break;
        default:
          return null;
      }
      return img;
    } catch (e) {
      debugPrint(">>>>>>>>>>>> ERROR:$e");
    }
    return null;
  }

  void saveToMem(CameraImage image) async {
    try {
      memoryImage = imageFromCameraImage(image);
      if (memoryImage != null) {
        setState(() {
          _showPreview = true;
          jpgBytes = imglib.encodeJpg(memoryImage!);
        });
      } else {
        debugPrint('Failed to convert camera image');
      }
    } catch (e) {
      debugPrint('Error saving image to memory: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (!_controller!.value.isInitialized) {
      return;
    }
    try {
      _controller!.startImageStream((CameraImage image) {
        _controller!.stopImageStream();
        saveToMem(image);
      });
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _acceptImage() {
    // Handle the accepted image here
    Navigator.pop(context, jpgBytes);
  }

  void _declineImage() {
    setState(() {
      _showPreview = false;
      memoryImage = null;
      jpgBytes = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          if (_showPreview && jpgBytes != null)
            Expanded(child: Image.memory(jpgBytes!))
          else
            Expanded(
              child: CameraPreview(_controller!),
            ),
          Container(
            width: double.infinity,
            color: primaryColor,
            padding: const EdgeInsets.only(
                left: defaultPadding,
                right: defaultPadding,
                top: defaultPadding,
                bottom: defaultPadding * 2),
            child: _showPreview && memoryImage != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        ElevatedButton.icon(
                          onPressed: _declineImage,
                          icon: const Icon(
                            Icons.close,
                            size: 32,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Decline',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            padding: EdgeInsets.only(
                                left: defaultPadding / 2,
                                right: defaultPadding),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: defaultPadding * 4),
                        ElevatedButton.icon(
                          onPressed: _acceptImage,
                          icon: const Icon(
                            Icons.send,
                            size: 24,
                            color: primaryColor,
                          ),
                          label: const Text(
                            'Send',
                            style: TextStyle(fontSize: 18),
                          ),
                          iconAlignment: IconAlignment.end,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.only(
                                left: defaultPadding,
                                right: defaultPadding / 1.5),
                          ),
                        ),
                      ])
                : Center(
                    child: IconButton(
                      onPressed: _takePhoto,
                      icon: const Icon(
                        Icons.camera,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
