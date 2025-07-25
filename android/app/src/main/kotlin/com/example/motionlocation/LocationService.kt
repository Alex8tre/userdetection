package com.example.motionlocation

import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.Manifest

class LocationService(private val context: Context) : LocationListener {
    
    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    private var locationCallback: ((Map<String, Any>) -> Unit)? = null
    private var isTracking = false
    
    // Location update parameters
    private val minTimeMs = 5000L // 5 seconds
    private val minDistanceM = 5.0f // 5 meters
    
    fun startTracking(callback: (Map<String, Any>) -> Unit) {
        if (!hasLocationPermission()) {
            android.util.Log.e("LocationService", "Location permission not granted")
            return
        }
        
        locationCallback = callback
        isTracking = true
        
        try {
            // Request location updates from both GPS and Network providers
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    minTimeMs,
                    minDistanceM,
                    this
                )
            }
            
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    minTimeMs,
                    minDistanceM,
                    this
                )
            }
            
            // Get last known location immediately
            getLastKnownLocation()?.let { location ->
                onLocationChanged(location)
            }
            
        } catch (e: SecurityException) {
            android.util.Log.e("LocationService", "Security exception: ${e.message}")
        }
    }
    
    fun stopTracking() {
        isTracking = false
        try {
            locationManager.removeUpdates(this)
        } catch (e: SecurityException) {
            android.util.Log.e("LocationService", "Security exception when stopping: ${e.message}")
        }
        locationCallback = null
    }
    
    override fun onLocationChanged(location: Location) {
        if (!isTracking) return
        
        val locationData = mapOf(
            "latitude" to location.latitude,
            "longitude" to location.longitude,
            "accuracy" to location.accuracy.toDouble(),
            "timestamp" to System.currentTimeMillis(),
            "provider" to (location.provider ?: "unknown"),
            "speed" to location.speed.toDouble(),
            "bearing" to location.bearing.toDouble(),
            "altitude" to location.altitude
        )
        
        locationCallback?.invoke(locationData)
    }
    
    private fun getLastKnownLocation(): Location? {
        if (!hasLocationPermission()) return null
        
        try {
            val gpsLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            
            return when {
                gpsLocation != null && networkLocation != null -> {
                    if (gpsLocation.time > networkLocation.time) gpsLocation else networkLocation
                }
                gpsLocation != null -> gpsLocation
                networkLocation != null -> networkLocation
                else -> null
            }
        } catch (e: SecurityException) {
            android.util.Log.e("LocationService", "Security exception getting last known location: ${e.message}")
            return null
        }
    }
    
    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    override fun onProviderEnabled(provider: String) {
        android.util.Log.i("LocationService", "Provider enabled: $provider")
    }
    
    override fun onProviderDisabled(provider: String) {
        android.util.Log.w("LocationService", "Provider disabled: $provider")
    }
    
    @Deprecated("Deprecated in API level 29")
    override fun onStatusChanged(provider: String?, status: Int, extras: android.os.Bundle?) {
        android.util.Log.i("LocationService", "Provider status changed: $provider, status: $status")
    }
}