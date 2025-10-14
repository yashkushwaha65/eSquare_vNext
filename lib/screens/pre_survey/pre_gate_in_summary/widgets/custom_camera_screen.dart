import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CustomCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CustomCameraScreen({super.key, required this.cameras});

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  final List<XFile> _capturedPhotos = [];
  FlashMode _currentFlashMode = FlashMode.off;
  int _selectedCameraIndex = 0;
  bool _canSwitchCameras = false;

  @override
  void initState() {
    super.initState();
    _canSwitchCameras = widget.cameras.length > 1;
    _selectedCameraIndex = widget.cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0;
    }
    _initializeCamera(_selectedCameraIndex);
  }

  void _initializeCamera(int cameraIndex) {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setFlashMode(_currentFlashMode);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_controller.value.isInitialized) {
      setState(() {
        switch (_currentFlashMode) {
          case FlashMode.off:
            _currentFlashMode = FlashMode.auto;
            break;
          case FlashMode.auto:
            _currentFlashMode = FlashMode.torch;
            break;
          case FlashMode.torch:
            _currentFlashMode = FlashMode.off;
            break;
          default:
            _currentFlashMode = FlashMode.off;
        }
      });
      await _controller.setFlashMode(_currentFlashMode);
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.torch:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  Future<void> _switchCamera() async {
    if (!_canSwitchCameras) return;

    // Simple toggle: if current is 0, switch to 1, and vice-versa.
    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;

    await _controller.dispose();
    setState(() {
      _currentFlashMode = FlashMode.off; // Reset flash on camera switch
      _initializeCamera(_selectedCameraIndex);
    });
  }

  Future<void> _takePhoto() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      // Move to app temp directory for consistent access
      final dir = await getTemporaryDirectory();
      final newPath = p.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final saved = await File(image.path).copy(newPath);

      setState(() {
        _capturedPhotos.add(XFile(saved.path));
      });
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  void _finish() {
    Navigator.pop(context, _capturedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                // Camera Switch button top left
                if (_canSwitchCameras)
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.flip_camera_ios_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _switchCamera,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                // Flash button top right
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: Icon(_getFlashIcon(), color: Colors.white, size: 30),
                    onPressed: _toggleFlash,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // preview strip
                        if (_capturedPhotos.isNotEmpty)
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _capturedPhotos.length,
                              itemBuilder: (context, i) => Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Image.file(
                                      File(_capturedPhotos[i].path),
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _capturedPhotos.removeAt(i);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const CircleBorder(),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(20),
                              ),
                              onPressed: _takePhoto,
                              child: const Icon(
                                Icons.camera,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.done,
                                color: Colors.greenAccent,
                                size: 30,
                              ),
                              onPressed: _capturedPhotos.isEmpty
                                  ? null
                                  : _finish,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
