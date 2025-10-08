import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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

  @override
  void initState() {
    super.initState();
    final rearCam = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(
      rearCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            return Center(child: SvgPicture.asset('assets/anims/loading.json'));
          }
        },
      ),
    );
  }
}
