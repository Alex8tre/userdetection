package com.example.motionlocation

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.Manifest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.motionlocation/native"
    private lateinit var motionDetectionService: MotionDetectionService
    private lateinit var locationService: LocationService
    private lateinit var proximityDetector: ProximityDetector
    
    private val PERMISSION_REQUEST_CODE = 123

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize services
        motionDetectionService = MotionDetectionService(this)
        locationService = LocationService(this)
        proximityDetector = ProximityDetector()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestPermissions()
                    result.success(null)
                }
                "startMotionDetection" -> {
                    motionDetectionService.startDetection { motionState ->
                        runOnUiThread {
                            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("onMotionStateChanged", motionState)
                        }
                    }
                    result.success(null)
                }
                "stopMotionDetection" -> {
                    motionDetectionService.stopDetection()
                    result.success(null)
                }
                "startLocationTracking" -> {
                    locationService.startTracking { locationData ->
                        runOnUiThread {
                            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("onLocationChanged", locationData)
                        }
                    }
                    result.success(null)
                }
                "stopLocationTracking" -> {
                    locationService.stopTracking()
                    result.success(null)
                }
                "setTargetLocations" -> {
                    val locations = call.argument<List<Map<String, Double>>>("locations")
                    proximityDetector.setTargetLocations(locations ?: emptyList())
                    result.success(null)
                }
                "checkProximity" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    val motionState = call.argument<String>("motionState") ?: "stationary"
                    
                    val proximityResult = proximityDetector.checkProximity(lat, lng, motionState)
                    if (proximityResult != null) {
                        runOnUiThread {
                            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                                .invokeMethod("onProximityDetected", proximityResult)
                        }
                    }
                    result.success(proximityResult)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.BODY_SENSORS,
            Manifest.permission.HIGH_SAMPLING_RATE_SENSORS
        )
        
        val permissionsToRequest = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }
}