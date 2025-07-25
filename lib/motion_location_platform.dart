import 'package:flutter/services.dart';
import 'models.dart';

class MotionLocationPlatform {
  static const MethodChannel _channel = MethodChannel('com.example.motionlocation/native');

  // Callbacks
  static Function(MotionState)? _onMotionStateChanged;
  static Function(LocationData)? _onLocationChanged;
  static Function(ProximityResult)? _onProximityDetected;

  static void _initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMotionStateChanged':
          if (_onMotionStateChanged != null) {
            final motionState = MotionState.fromMap(
              Map<String, dynamic>.from(call.arguments),
            );
            _onMotionStateChanged!(motionState);
          }
          break;
        case 'onLocationChanged':
          if (_onLocationChanged != null) {
            final locationData = LocationData.fromMap(
              Map<String, dynamic>.from(call.arguments),
            );
            _onLocationChanged!(locationData);
          }
          break;
        case 'onProximityDetected':
          if (_onProximityDetected != null) {
            final proximityResult = ProximityResult.fromMap(
              Map<String, dynamic>.from(call.arguments),
            );
            _onProximityDetected!(proximityResult);
          }
          break;
      }
    });
  }

  static Future<void> requestPermissions() async {
    _initialize();
    try {
      await _channel.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      print('Error requesting permissions: ${e.message}');
    }
  }

  static Future<void> startMotionDetection({
    required Function(MotionState) onMotionStateChanged,
  }) async {
    _onMotionStateChanged = onMotionStateChanged;
    try {
      await _channel.invokeMethod('startMotionDetection');
    } on PlatformException catch (e) {
      print('Error starting motion detection: ${e.message}');
    }
  }

  static Future<void> stopMotionDetection() async {
    try {
      await _channel.invokeMethod('stopMotionDetection');
      _onMotionStateChanged = null;
    } on PlatformException catch (e) {
      print('Error stopping motion detection: ${e.message}');
    }
  }

  static Future<void> startLocationTracking({
    required Function(LocationData) onLocationChanged,
  }) async {
    _onLocationChanged = onLocationChanged;
    try {
      await _channel.invokeMethod('startLocationTracking');
    } on PlatformException catch (e) {
      print('Error starting location tracking: ${e.message}');
    }
  }

  static Future<void> stopLocationTracking() async {
    try {
      await _channel.invokeMethod('stopLocationTracking');
      _onLocationChanged = null;
    } on PlatformException catch (e) {
      print('Error stopping location tracking: ${e.message}');
    }
  }

  static Future<void> setTargetLocations(List<TargetLocation> locations) async {
    try {
      final locationMaps = locations.map((loc) => loc.toMap()).toList();
      await _channel.invokeMethod('setTargetLocations', {
        'locations': locationMaps,
      });
    } on PlatformException catch (e) {
      print('Error setting target locations: ${e.message}');
    }
  }

  static Future<ProximityResult?> checkProximity({
    required double latitude,
    required double longitude,
    required String motionState,
    Function(ProximityResult)? onProximityDetected,
  }) async {
    _onProximityDetected = onProximityDetected;
    try {
      final result = await _channel.invokeMethod('checkProximity', {
        'latitude': latitude,
        'longitude': longitude,
        'motionState': motionState,
      });
      
      if (result != null) {
        return ProximityResult.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      print('Error checking proximity: ${e.message}');
      return null;
    }
  }
}