class MotionState {
  final String activity;
  final double confidence;
  final DateTime timestamp;

  const MotionState({
    required this.activity,
    required this.confidence,
    required this.timestamp,
  });

  static const Map<int, String> activityMapping = {
    0: 'Fermo',
    1: 'Camminando',
    2: 'Correndo',
    3: 'In Veicolo',
    4: 'In Bicicletta',
  };

  static const Map<int, String> englishActivityMapping = {
    0: 'Still',
    1: 'Walking',
    2: 'Running',
    3: 'In Vehicle',
    4: 'On Bicycle',
  };

  factory MotionState.fromClassification(int classIndex, double confidence) {
    return MotionState(
      activity: activityMapping[classIndex] ?? 'Sconosciuto',
      confidence: confidence,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MotionState(activity: $activity, confidence: ${(confidence * 100).toStringAsFixed(1)}%, timestamp: $timestamp)';
  }
}