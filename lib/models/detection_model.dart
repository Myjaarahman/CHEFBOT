class Detection {
  final String label;
  final double confidence;
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  Detection({
    required this.label,
    required this.confidence,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'],
      confidence: (json['confidence'] as num).toDouble(),
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }
}