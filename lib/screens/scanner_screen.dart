import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../backend/detection_service.dart';
import 'ingredients_result_screen.dart';
import 'package:chefbot_app/utils/image_utils.dart'; // Ensure this path is correct

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

enum UploadStage { idle, picking, resizing, detecting }

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? controller;
  UploadStage _stage = UploadStage.idle;
  double _progress = 0.0;
  String? _stageMessage;
  bool _isModelLoaded = false;
  
  // Flash state
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    initCamera();
    initModel();
  }

  @override
  void dispose() {
    controller?.dispose();
    DetectionService.closeModel();
    super.dispose();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      // UPGRADE 1: Use ResolutionPreset.max for highest possible quality
      controller = CameraController(
        cameras.first,
        ResolutionPreset.max, 
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg // Better compatibility for older Androids
            : ImageFormatGroup.bgra8888,
      );

      try {
        await controller!.initialize();
        // Set initial flash mode
        await controller!.setFlashMode(_currentFlashMode);
        // Turn off exposure locking initially
        await controller!.setExposureMode(ExposureMode.auto);
      } catch (e) {
        debugPrint("Camera init error: $e");
      }

      if (mounted) setState(() {});
    }
  }

  Future<void> initModel() async {
    try {
      await DetectionService.loadModel();
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading model: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load AI model: $e")),
        );
      }
    }
  }

  // Helper to toggle flash
  Future<void> _toggleFlash() async {
    if (controller == null || !controller!.value.isInitialized) return;

    FlashMode newMode;
    IconData icon;
    
    // Cycle: Off -> Auto -> Torch -> Off
    if (_currentFlashMode == FlashMode.off) {
      newMode = FlashMode.auto;
    } else if (_currentFlashMode == FlashMode.auto) {
      newMode = FlashMode.torch;
    } else {
      newMode = FlashMode.off;
    }

    try {
      await controller!.setFlashMode(newMode);
      setState(() {
        _currentFlashMode = newMode;
      });
    } catch (e) {
      debugPrint("Error changing flash mode: $e");
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off: return Icons.flash_off;
      case FlashMode.auto: return Icons.flash_auto;
      case FlashMode.torch: return Icons.highlight; // Torch/Always On
      default: return Icons.flash_off;
    }
  }

  Future<void> snap() async {
    if (!_isModelLoaded || controller == null || !controller!.value.isInitialized) return;

    if (controller!.value.isTakingPicture) return;

    try {
      // UPGRADE 2: Focus Lock Logic
      // Older cameras struggle to focus instantly. We force a focus lock before capture.
      try {
        await controller!.setFocusMode(FocusMode.locked);
        await controller!.setExposureMode(ExposureMode.locked);
      } catch (e) {
        // Some very old cameras might not support locking, ignore error
        debugPrint("Focus lock not supported: $e");
      }

      // 1. Take the picture
      final image = await controller!.takePicture();
      
      // Unlock focus immediately after snap
      try {
        await controller!.setFocusMode(FocusMode.auto);
        await controller!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      final originalFile = File(image.path);

      // 2. Show loading state
      setState(() {
        _stage = UploadStage.resizing;
        _progress = 0.3;
        _stageMessage = 'Preparing image...';
      });

      // 3. Resize/Normalize
      final processedFile = await resizeImage(originalFile);

      // 4. Run detection
      processImage(processedFile); 

    } catch (e) {
      debugPrint("Camera error: $e");
      resetState();
    }
  }

  // ... (Keep existing upload() method exactly as is) ...
  Future<void> upload() async {
    if (!_isModelLoaded) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Model is still loading...")),
       );
       return;
    }

    try {
      setState(() {
        _stage = UploadStage.picking;
        _progress = 0.05;
        _stageMessage = 'Picking image...';
      });

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // Ensure max quality from gallery
      );

      if (picked == null) {
        resetState();
        return;
      }

      setState(() {
        _stage = UploadStage.resizing;
        _progress = 0.25;
        _stageMessage = 'Preparing image...';
      });

      final originalFile = File(picked.path);
      final processedFile = await resizeImage(originalFile); 

      setState(() {
        _stage = UploadStage.detecting;
        _progress = 0.6;
        _stageMessage = 'Scanning ingredients...';
      });

      final result = await DetectionService.detect(processedFile);

      setState(() {
        _progress = 1.0;
        _stageMessage = 'Done';
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientResultPage(
            image: processedFile,
            detections: result['detections'],
            imageWidth: result['width'],
            imageHeight: result['height'],
          ),
        ),
      );
    } catch (e) {
      debugPrint("Processing error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Failed to process image")));
      }
    } finally {
      if (mounted) resetState();
    }
  }

  // ... (Keep existing processImage() method exactly as is) ...
  Future<void> processImage(File image) async {
    try {
      setState(() {
        _stage = UploadStage.detecting;
        _progress = 0.6;
        _stageMessage = 'Scanning ingredients...';
      });

      final result = await DetectionService.detect(image);

      setState(() {
        _progress = 1.0;
        _stageMessage = 'Done';
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IngredientResultPage(
            image: image,
            detections: result['detections'],
            imageWidth: result['width'],
            imageHeight: result['height'],
          ),
        ),
      );
    } catch(e) {
        debugPrint("Error: $e");
    } finally {
        if(mounted) resetState();
    }
  }

  void resetState() {
    setState(() {
      _stage = UploadStage.idle;
      _progress = 0.0;
      _stageMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Getting screen size to position elements correctly
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(controller!),
          
          // Flash Button (Top Right)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(_getFlashIcon(), color: Colors.white, size: 28),
                onPressed: _toggleFlash,
              ),
            ),
          ),

          // Loading/Processing Overlay
          if (_isModelLoaded == false)
             const Positioned(
               top: 50, left: 0, right: 0,
               child: Center(child: Text("Loading AI Model...", style: TextStyle(color: Colors.white, backgroundColor: Colors.black54))),
             ),

          if (_stage != UploadStage.idle)
            Positioned.fill(
              child: Container(
                color: Colors.black54, // Darker overlay for better visibility
                child: Center(
                  child: SizedBox(
                    width: 320,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 20),
                            Text(
                              _stageMessage ?? "Processing...",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            if (_progress > 0)
                              LinearProgressIndicator(value: _progress),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Controls Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Stack(
                children: [
                  // Gallery Upload Button (Left)
                  Positioned(
                    left: 40,
                    bottom: 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                          onPressed: _isModelLoaded ? upload : null,
                        ),
                        const Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 12))
                      ],
                    ),
                  ),

                  // Snap Button (Center)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: GestureDetector(
                        onTap: _isModelLoaded ? snap : null,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isModelLoaded ? Colors.white : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
                            ]
                          ),
                          child: Center(
                            child: Container(
                              width: 70, 
                              height: 70,
                              decoration: BoxDecoration(
                                color: _isModelLoaded ? Colors.white : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.black, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}