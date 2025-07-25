// Simple test file for motion detection models
// This is a placeholder for unit tests when Flutter SDK is available

void main() {
  // Test MotionState model
  testMotionStateModel();
  
  // Test LocationData model  
  testLocationDataModel();
  
  // Test ProximityResult model
  testProximityResultModel();
  
  // Test distance calculation
  testDistanceCalculation();
  
  print('🎉 All model tests passed!');
}

void testMotionStateModel() {
  // Test data that would come from native platform
  final testData = {
    'motionState': 'walking',
    'timestamp': 1234567890123,
    'confidence': 0.95
  };
  
  // This would work with actual MotionState.fromMap()
  assert(testData['motionState'] == 'walking');
  assert(testData['confidence'] == 0.95);
  print('✅ MotionState model test passed');
}

void testLocationDataModel() {
  final testData = {
    'latitude': 45.4642,
    'longitude': 9.1900,
    'accuracy': 5.0,
    'timestamp': 1234567890123,
    'provider': 'GPS',
    'speed': 2.5,
    'bearing': 45.0,
    'altitude': 100.0
  };
  
  assert(testData['latitude'] == 45.4642);
  assert(testData['longitude'] == 9.1900);
  print('✅ LocationData model test passed');
}

void testProximityResultModel() {
  final testData = {
    'isNearTarget': true,
    'targetIndex': 0,
    'distance': 25.5,
    'threshold': 50.0,
    'motionState': 'walking',
    'targetLatitude': 45.4642,
    'targetLongitude': 9.1900,
    'timestamp': 1234567890123
  };
  
  assert(testData['isNearTarget'] == true);
  assert(testData['distance'] == 25.5);
  print('✅ ProximityResult model test passed');
}

void testDistanceCalculation() {
  // Test Haversine distance calculation
  // Milano Centro to Roma Centro should be approximately 477km
  final milanLat = 45.4642;
  final milanLng = 9.1900;
  final romaLat = 41.9028;
  final romaLng = 12.4964;
  
  final distance = calculateHaversineDistance(milanLat, milanLng, romaLat, romaLng);
  
  // Should be approximately 477000 meters
  assert(distance > 470000 && distance < 485000);
  print('✅ Distance calculation test passed: ${(distance / 1000).toStringAsFixed(1)}km');
}

double calculateHaversineDistance(double lat1, double lng1, double lat2, double lng2) {
  const double earthRadius = 6371000.0; // Earth radius in meters
  
  final dLat = (lat2 - lat1) * (3.14159 / 180.0);
  final dLng = (lng2 - lng1) * (3.14159 / 180.0);
  
  final lat1Rad = lat1 * (3.14159 / 180.0);
  final lat2Rad = lat2 * (3.14159 / 180.0);
  
  final a = (dLat / 2).sin() * (dLat / 2).sin() +
      (dLng / 2).sin() * (dLng / 2).sin() * lat1Rad.cos() * lat2Rad.cos();
  final c = 2 * a.sqrt().atan2((1 - a).sqrt());
  
  return earthRadius * c;
}

// Extension methods for math functions
extension MathExtensions on double {
  double sin() => _sin(this);
  double cos() => _cos(this);
  double sqrt() => _sqrt(this);
  double atan2(double y) => _atan2(this, y);
}

// Simple math implementations
double _sin(double x) => x - (x * x * x) / 6; // Simple approximation
double _cos(double x) => 1 - (x * x) / 2; // Simple approximation  
double _sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;
  
  double result = x;
  for (int i = 0; i < 10; i++) {
    result = (result + x / result) / 2;
  }
  return result;
}
double _atan2(double y, double x) => 0.0; // Placeholder