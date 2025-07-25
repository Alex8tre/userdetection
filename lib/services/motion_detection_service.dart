import 'dart:async';
import 'package:flutter/services.dart';
import '../models/motion_state.dart';

class MotionDetectionService {
  static const MethodChannel _channel = MethodChannel('userdetection/motion');
  
  StreamController<MotionState>? _motionStateController;
  Stream<MotionState>? _motionStateStream;
  
  static MotionDetectionService? _instance;
  
  factory MotionDetectionService() {
    _instance ??= MotionDetectionService._internal();
    return _instance!;
  }
  
  MotionDetectionService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  Stream<MotionState> get motionStateStream {
    _motionStateStream ??= _motionStateController?.stream ?? _createStream();
    return _motionStateStream!;
  }
  
  Stream<MotionState> _createStream() {
    _motionStateController = StreamController<MotionState>.broadcast();
    return _motionStateController!.stream;
  }
  
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onActivityDetected':
        final arguments = call.arguments as Map<dynamic, dynamic>;
        final classIndex = arguments['classIndex'] as int;
        final confidence = arguments['confidence'] as double;
        
        final motionState = MotionState.fromClassification(classIndex, confidence);
        _motionStateController?.add(motionState);
        break;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          details: 'Method ${call.method} not implemented',
        );
    }
  }
  
  Future<bool> startDetection() async {
    try {
      final result = await _channel.invokeMethod<bool>('startDetection');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to start motion detection: ${e.message}');
      return false;
    }
  }
  
  Future<bool> stopDetection() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopDetection');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to stop motion detection: ${e.message}');
      return false;
    }
  }
  
  Future<bool> hasPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to check permissions: ${e.message}');
      return false;
    }
  }
  
  Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to request permissions: ${e.message}');
      return false;
    }
  }
  
  void dispose() {
    _motionStateController?.close();
    _motionStateController = null;
    _motionStateStream = null;
  }
}