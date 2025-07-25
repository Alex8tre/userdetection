import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var motionDetectionService: MotionDetectionService?
    private var methodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        motionDetectionService = MotionDetectionService()
        
        methodChannel = FlutterMethodChannel(
            name: "userdetection/motion",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else { return }
            
            switch call.method {
            case "hasPermissions":
                self.hasRequiredPermissions(result: result)
            case "requestPermissions":
                self.requestRequiredPermissions(result: result)
            case "startDetection":
                self.startMotionDetection(result: result)
            case "stopDetection":
                self.stopMotionDetection(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func hasRequiredPermissions(result: @escaping FlutterResult) {
        // For iOS, motion data access is generally available without explicit permission
        // But we can check if motion services are available
        result(true)
    }
    
    private func requestRequiredPermissions(result: @escaping FlutterResult) {
        // No explicit permission needed for Core Motion on iOS
        result(true)
    }
    
    private func startMotionDetection(result: @escaping FlutterResult) {
        motionDetectionService?.startDetection { [weak self] (classIndex, confidence) in
            DispatchQueue.main.async {
                self?.methodChannel?.invokeMethod("onActivityDetected", arguments: [
                    "classIndex": classIndex,
                    "confidence": confidence
                ])
            }
        }
        result(true)
    }
    
    private func stopMotionDetection(result: @escaping FlutterResult) {
        motionDetectionService?.stopDetection()
        result(true)
    }
}