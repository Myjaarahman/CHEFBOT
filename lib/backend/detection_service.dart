import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:chefbot_app/models/detection_model.dart';
import 'package:flutter/material.dart'; // Needed for decodeImageFromList

class DetectionService {
  // Initialize the vision tool
  static final FlutterVision _vision = FlutterVision();

  // Load the model (Called once on app start or screen init)
  static Future<void> loadModel() async {
    await _vision.loadYoloModel(
      modelPath: 'assets/best_food_detector_float16.tflite', // Make sure this matches your file
      labels: 'assets/labels.txt',
      modelVersion: "yolov8", // Tells the library how to parse output
      numThreads: 2,
      useGpu: true, // Use GPU for faster detection
    );
  }

  // Close resources to prevent leaks
  static Future<void> closeModel() async {
    await _vision.closeYoloModel();
  }

  static Future<Map<String, dynamic>> detect(File image) async {
    final imageBytes = await image.readAsBytes();
    final decodedImage = await decodeImageFromList(imageBytes);
    final double imgWidth = decodedImage.width.toDouble();
    final double imgHeight = decodedImage.height.toDouble();

    final result = await _vision.yoloOnImage(
      bytesList: imageBytes,
      imageHeight: decodedImage.height,
      imageWidth: decodedImage.width,
      iouThreshold: 0.45,
      confThreshold: 0.4,
      classThreshold: 0.5,
    );

    final detections = result.map((res) {
      final box = res['box']; // [x1, y1, x2, y2, confidence]
      
      return Detection.fromJson({
        // 1. Use "label" to match your Detection model (not "class")
        // 2. Use a fallback "Unknown" if the tag is missing
        "label": res['tag']?.toString() ?? "Unknown", 
        
        "confidence": box[4],
        
        // 3. Pass coordinates directly (Flattened), not inside a "box" map
        "x1": box[0],
        "y1": box[1],
        "x2": box[2],
        "y2": box[3],
      });
    }).toList();

    return {
      "width": imgWidth,
      "height": imgHeight,
      "detections": detections,
    };
  }
}