import Foundation
import CoreLocation

class ProximityDetector {
    
    private var targetLocations: [[String: Double]] = []
    
    // Threshold distances in meters
    private let walkingThreshold: Double = 50.0
    private let vehicleThreshold: Double = 200.0
    
    func setTargetLocations(_ locations: [[String: Double]]) {
        targetLocations = locations
    }
    
    func checkProximity(latitude: Double, longitude: Double, motionState: String) -> [String: Any]? {
        guard !targetLocations.isEmpty else { return nil }
        
        let threshold = (motionState == "walking" || motionState == "running") ? walkingThreshold : vehicleThreshold
        
        for (index, target) in targetLocations.enumerated() {
            guard let targetLat = target["latitude"],
                  let targetLng = target["longitude"] else { continue }
            
            let distance = calculateHaversineDistance(
                lat1: latitude, lng1: longitude,
                lat2: targetLat, lng2: targetLng
            )
            
            if distance <= threshold {
                return [
                    "isNearTarget": true,
                    "targetIndex": index,
                    "distance": distance,
                    "threshold": threshold,
                    "motionState": motionState,
                    "targetLatitude": targetLat,
                    "targetLongitude": targetLng,
                    "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
                ]
            }
        }
        
        return nil
    }
    
    private func calculateHaversineDistance(lat1: Double, lng1: Double, lat2: Double, lng2: Double) -> Double {
        let earthRadius = 6371000.0 // Earth radius in meters
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLng = (lng2 - lng1) * .pi / 180.0
        
        let lat1Rad = lat1 * .pi / 180.0
        let lat2Rad = lat2 * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                sin(dLng / 2) * sin(dLng / 2) * cos(lat1Rad) * cos(lat2Rad)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    func getAllDistances(latitude: Double, longitude: Double) -> [[String: Any]] {
        return targetLocations.enumerated().map { (index, target) in
            let targetLat = target["latitude"] ?? 0.0
            let targetLng = target["longitude"] ?? 0.0
            let distance = calculateHaversineDistance(
                lat1: latitude, lng1: longitude,
                lat2: targetLat, lng2: targetLng
            )
            
            return [
                "targetIndex": index,
                "distance": distance,
                "targetLatitude": targetLat,
                "targetLongitude": targetLng
            ]
        }
    }
}