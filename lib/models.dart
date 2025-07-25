class MotionState {
  final String state;
  final DateTime timestamp;
  final double confidence;

  MotionState({
    required this.state,
    required this.timestamp,
    required this.confidence,
  });

  factory MotionState.fromMap(Map<String, dynamic> map) {
    return MotionState(
      state: map['motionState'] ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
    );
  }

  String get displayName {
    switch (state) {
      case 'stationary':
        return 'Fermo';
      case 'walking':
        return 'Camminando';
      case 'running':
        return 'Correndo';
      case 'vehicle':
        return 'In Veicolo';
      default:
        return 'Sconosciuto';
    }
  }
}

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final String provider;
  final double speed;
  final double bearing;
  final double altitude;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.provider,
    required this.speed,
    required this.bearing,
    required this.altitude,
  });

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      provider: map['provider'] ?? 'unknown',
      speed: (map['speed'] ?? 0.0).toDouble(),
      bearing: (map['bearing'] ?? 0.0).toDouble(),
      altitude: (map['altitude'] ?? 0.0).toDouble(),
    );
  }
}

class ProximityResult {
  final bool isNearTarget;
  final int targetIndex;
  final double distance;
  final double threshold;
  final String motionState;
  final double targetLatitude;
  final double targetLongitude;
  final DateTime timestamp;

  ProximityResult({
    required this.isNearTarget,
    required this.targetIndex,
    required this.distance,
    required this.threshold,
    required this.motionState,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.timestamp,
  });

  factory ProximityResult.fromMap(Map<String, dynamic> map) {
    return ProximityResult(
      isNearTarget: map['isNearTarget'] ?? false,
      targetIndex: map['targetIndex'] ?? 0,
      distance: (map['distance'] ?? 0.0).toDouble(),
      threshold: (map['threshold'] ?? 0.0).toDouble(),
      motionState: map['motionState'] ?? 'unknown',
      targetLatitude: (map['targetLatitude'] ?? 0.0).toDouble(),
      targetLongitude: (map['targetLongitude'] ?? 0.0).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}

class TargetLocation {
  final double latitude;
  final double longitude;
  final String name;

  TargetLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  Map<String, double> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}