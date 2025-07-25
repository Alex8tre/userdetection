import CoreLocation
import Foundation

class LocationService: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    private var locationCallback: (([String: Any]) -> Void)?
    private var isTracking = false
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // 5 meters
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            print("Location always authorized")
        @unknown default:
            break
        }
    }
    
    func startTracking(callback: @escaping ([String: Any]) -> Void) {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            print("Location permission not granted")
            return
        }
        
        locationCallback = callback
        isTracking = true
        
        locationManager.startUpdatingLocation()
        
        // Get last known location immediately if available
        if let lastLocation = locationManager.location {
            locationManager(locationManager, didUpdateLocations: [lastLocation])
        }
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        locationCallback = nil
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let location = locations.last else { return }
        
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": Int64(location.timestamp.timeIntervalSince1970 * 1000),
            "provider": "CoreLocation",
            "speed": max(0, location.speed), // Ensure non-negative speed
            "bearing": location.course >= 0 ? location.course : 0,
            "altitude": location.altitude
        ]
        
        locationCallback?(locationData)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            break
        case .denied, .restricted:
            print("Location access denied or restricted")
        case .authorizedWhenInUse:
            print("Location authorized when in use")
        case .authorizedAlways:
            print("Location always authorized")
        @unknown default:
            break
        }
    }
}