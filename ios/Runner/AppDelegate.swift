import UIKit
import Flutter
import CoreMotion
import CoreLocation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var motionDetectionService: MotionDetectionService?
    private var locationService: LocationService?
    private var proximityDetector: ProximityDetector?
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }
        
        let channelName = "com.example.motionlocation/native"
        methodChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)
        
        // Initialize services
        motionDetectionService = MotionDetectionService()
        locationService = LocationService()
        proximityDetector = ProximityDetector()
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call: call, result: result)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermissions":
            requestPermissions()
            result(nil)
            
        case "startMotionDetection":
            motionDetectionService?.startDetection { [weak self] motionState in
                DispatchQueue.main.async {
                    self?.methodChannel?.invokeMethod("onMotionStateChanged", arguments: motionState)
                }
            }
            result(nil)
            
        case "stopMotionDetection":
            motionDetectionService?.stopDetection()
            result(nil)
            
        case "startLocationTracking":
            locationService?.startTracking { [weak self] locationData in
                DispatchQueue.main.async {
                    self?.methodChannel?.invokeMethod("onLocationChanged", arguments: locationData)
                }
            }
            result(nil)
            
        case "stopLocationTracking":
            locationService?.stopTracking()
            result(nil)
            
        case "setTargetLocations":
            if let locations = call.arguments as? [[String: Double]] {
                proximityDetector?.setTargetLocations(locations)
            }
            result(nil)
            
        case "checkProximity":
            guard let args = call.arguments as? [String: Any],
                  let latitude = args["latitude"] as? Double,
                  let longitude = args["longitude"] as? Double,
                  let motionState = args["motionState"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                return
            }
            
            let proximityResult = proximityDetector?.checkProximity(latitude: latitude, longitude: longitude, motionState: motionState)
            if let proximityResult = proximityResult {
                DispatchQueue.main.async {
                    self.methodChannel?.invokeMethod("onProximityDetected", arguments: proximityResult)
                }
            }
            result(proximityResult)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestPermissions() {
        // Location permissions
        locationService?.requestLocationPermission()
        
        // Motion permissions are handled automatically by CoreMotion when first accessed
    }
}