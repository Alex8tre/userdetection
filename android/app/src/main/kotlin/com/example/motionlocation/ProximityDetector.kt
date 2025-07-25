package com.example.motionlocation

import kotlin.math.*

class ProximityDetector {
    
    private var targetLocations: List<Map<String, Double>> = emptyList()
    
    // Threshold distances in meters
    private val walkingThreshold = 50.0
    private val vehicleThreshold = 200.0
    
    fun setTargetLocations(locations: List<Map<String, Double>>) {
        targetLocations = locations
    }
    
    fun checkProximity(latitude: Double, longitude: Double, motionState: String): Map<String, Any>? {
        if (targetLocations.isEmpty()) return null
        
        val threshold = when (motionState) {
            "walking", "running" -> walkingThreshold
            "vehicle" -> vehicleThreshold
            else -> walkingThreshold
        }
        
        for ((index, target) in targetLocations.withIndex()) {
            val targetLat = target["latitude"] ?: continue
            val targetLng = target["longitude"] ?: continue
            
            val distance = calculateHaversineDistance(latitude, longitude, targetLat, targetLng)
            
            if (distance <= threshold) {
                return mapOf(
                    "isNearTarget" to true,
                    "targetIndex" to index,
                    "distance" to distance,
                    "threshold" to threshold,
                    "motionState" to motionState,
                    "targetLatitude" to targetLat,
                    "targetLongitude" to targetLng,
                    "timestamp" to System.currentTimeMillis()
                )
            }
        }
        
        return null
    }
    
    private fun calculateHaversineDistance(
        lat1: Double, lng1: Double,
        lat2: Double, lng2: Double
    ): Double {
        val earthRadius = 6371000.0 // Earth radius in meters
        
        val dLat = Math.toRadians(lat2 - lat1)
        val dLng = Math.toRadians(lng2 - lng1)
        
        val lat1Rad = Math.toRadians(lat1)
        val lat2Rad = Math.toRadians(lat2)
        
        val a = sin(dLat / 2).pow(2) + 
                sin(dLng / 2).pow(2) * cos(lat1Rad) * cos(lat2Rad)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    fun getAllDistances(latitude: Double, longitude: Double): List<Map<String, Any>> {
        return targetLocations.mapIndexed { index, target ->
            val targetLat = target["latitude"] ?: 0.0
            val targetLng = target["longitude"] ?: 0.0
            val distance = calculateHaversineDistance(latitude, longitude, targetLat, targetLng)
            
            mapOf(
                "targetIndex" to index,
                "distance" to distance,
                "targetLatitude" to targetLat,
                "targetLongitude" to targetLng
            )
        }
    }
}