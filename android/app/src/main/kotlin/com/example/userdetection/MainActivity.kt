package com.example.userdetection

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "userdetection/motion"
    private val PERMISSIONS_REQUEST_CODE = 1001
    
    private var motionDetectionService: MotionDetectionService? = null
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        motionDetectionService = MotionDetectionService(this)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermissions" -> {
                    result.success(hasRequiredPermissions())
                }
                "requestPermissions" -> {
                    requestRequiredPermissions()
                    result.success(true)
                }
                "startDetection" -> {
                    if (hasRequiredPermissions()) {
                        startMotionDetection()
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopDetection" -> {
                    stopMotionDetection()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun hasRequiredPermissions(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.BODY_SENSORS) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestRequiredPermissions() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.BODY_SENSORS),
            PERMISSIONS_REQUEST_CODE
        )
    }
    
    private fun startMotionDetection() {
        motionDetectionService?.startDetection { classIndex, confidence ->
            runOnUiThread {
                methodChannel?.invokeMethod("onActivityDetected", mapOf(
                    "classIndex" to classIndex,
                    "confidence" to confidence
                ))
            }
        }
    }
    
    private fun stopMotionDetection() {
        motionDetectionService?.stopDetection()
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            PERMISSIONS_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                
                methodChannel?.invokeMethod("onPermissionsResult", mapOf(
                    "granted" to granted
                ))
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        motionDetectionService?.cleanup()
    }
}