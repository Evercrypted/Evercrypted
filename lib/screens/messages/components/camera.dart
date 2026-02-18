import 'dart:typed_data';

import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  String? _errorMessage;
  bool _permissionPermanentlyDenied = false;
  Uint8List? jpgBytes;
  bool _showPreview = false;

  FlashMode _flashMode = FlashMode.off;

  int _currentCameraIndex = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _permissionPermanentlyDenied = true;
            _errorMessage =
                'Camera permission was denied. Please enable it in Settings.';
          });
        }
        return;
      }
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Camera permission is required to take photos.';
          });
        }
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No cameras found on this device.';
          });
        }
        return;
      }

      // Ensure index is valid
      if (_currentCameraIndex >= cameras.length) {
        _currentCameraIndex = 0;
      }

      await _initController(cameras[_currentCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not access camera. Please check camera permissions in Settings.';
        });
      }
    }
  }

  Future<void> _initController(CameraDescription cameraDescription) async {
    // Dispose the previous controller properly *before* initializing the new one
    // to avoid resource contention (some devices only support one active camera).
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.jpeg,
      enableAudio: false,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      // Set initial flash mode
      await cameraController.setFlashMode(_flashMode);

      // Initialize zoom levels
      _maxAvailableZoom = await cameraController.getMaxZoomLevel();
      _minAvailableZoom = await cameraController.getMinZoomLevel();
      _currentScale = _minAvailableZoom;

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not start camera. Please check camera permissions in Settings.';
        });
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
    });

    await _initController(cameras[_currentCameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    FlashMode newMode;
    if (_flashMode == FlashMode.off) {
      newMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      newMode = FlashMode.always;
    } else {
      newMode = FlashMode.off;
    }

    await _controller!.setFlashMode(newMode);
    setState(() {
      _flashMode = newMode;
    });
  }

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  Future<void> _takePhoto() async {
    if (!_controller!.value.isInitialized || _isTakingPicture) {
      return;
    }
    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();

      if (mounted) {
        setState(() {
          jpgBytes = bytes;
          _showPreview = true;
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  void _acceptImage() {
    // Handle the accepted image here
    Navigator.pop(context, jpgBytes);
  }

  void _declineImage() {
    setState(() {
      _showPreview = false;
      jpgBytes = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    // Return if not initialized
    if (_controller == null || !_isInitialized) {
      return;
    }

    double currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await _controller!.setZoomLevel(currentScale);

    // Update state to track current scale for next pinch
    setState(() {
      _currentScale = currentScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(defaultPadding * 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt,
                          color: Colors.white54, size: 64),
                      const SizedBox(height: defaultPadding),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: defaultPadding * 2),
                      ElevatedButton(
                        onPressed: _permissionPermanentlyDenied
                            ? () => openAppSettings()
                            : () {
                                setState(() {
                                  _errorMessage = null;
                                  _permissionPermanentlyDenied = false;
                                });
                                _initializeCamera();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        child: Text(
                            _permissionPermanentlyDenied
                                ? 'Open Settings'
                                : 'Try Again',
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_showPreview) ...[
            if (cameras.length > 1)
              IconButton(
                onPressed: _toggleCamera,
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
            IconButton(
              onPressed: _toggleFlash,
              icon: Icon(_getFlashIcon(), color: Colors.white),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showPreview && jpgBytes != null
                ? Image.memory(jpgBytes!, fit: BoxFit.contain)
                : Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: _onScaleUpdate,
                      child: CameraPreview(_controller!),
                    ),
                  ),
          ),
          Container(
            color: Colors.black,
            width: double.infinity,
            padding: const EdgeInsets.only(
                left: defaultPadding,
                right: defaultPadding,
                top: defaultPadding,
                bottom: defaultPadding * 2),
            child: _showPreview && jpgBytes != null
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
                            'Retake',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            padding: const EdgeInsets.only(
                                left: defaultPadding / 2,
                                right: defaultPadding),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: defaultPadding * 4),
                        ElevatedButton.icon(
                          onPressed: _acceptImage,
                          icon: const Icon(
                            Icons.send,
                            size: 24,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Send',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.only(
                                top: defaultPadding / 2,
                                bottom: defaultPadding / 2,
                                left: defaultPadding,
                                right: defaultPadding / 1.5),
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ])
                : Center(
                    child: _isTakingPicture
                        ? const CircularProgressIndicator(color: Colors.white)
                        : IconButton(
                            onPressed: _takePhoto,
                            icon: const Icon(
                              Icons.camera,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
