import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meassagesapp/screens/story_preview_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class StoryCameraScreen extends StatefulWidget {
  @override
  _StoryCameraScreenState createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<StoryCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _cameras = await availableCameras();
      _cameraController = CameraController(_cameras![0], ResolutionPreset.high);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } else {
      Get.snackbar("صلاحية مرفوضة", "يرجى منح صلاحية الكاميرا.");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;

    final XFile file = await _cameraController!.takePicture();
    Get.to(() => StoryEditorScreen(imageFile: File(file.path)));
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      Get.to(() => StoryEditorScreen(imageFile: File(picked.path)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر فتح المعرض
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white30,
                    child: Icon(Icons.photo_library, color: Colors.white),
                  ),
                ),
                SizedBox(width: 30),
                // زر التصوير
                GestureDetector(
                  onTap: _takePicture,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, size: 28, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
