package com.example.motionlocation

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.sqrt

class MotionDetectionService(private val context: Context) : SensorEventListener {
    
    private val sensorManager: SensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    
    private var tflite: Interpreter? = null
    private val sensorData = CopyOnWriteArrayList<FloatArray>()
    private val windowSize = 50
    private val samplingRate = SensorManager.SENSOR_DELAY_UI
    
    private var motionCallback: ((Map<String, Any>) -> Unit)? = null
    private var isDetecting = false
    
    // Motion states
    private val motionStates = arrayOf("stationary", "walking", "running", "vehicle")
    
    init {
        loadModel()
    }
    
    private fun loadModel() {
        try {
            val modelPath = "motion_classifier.tflite"
            val assetFileDescriptor = context.assets.openFd(modelPath)
            val fileInputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
            val fileChannel = fileInputStream.channel
            val startOffset = assetFileDescriptor.startOffset
            val declaredLength = assetFileDescriptor.declaredLength
            val modelByteBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
            
            tflite = Interpreter(modelByteBuffer)
        } catch (e: Exception) {
            // Model not found, will use basic threshold-based detection
            android.util.Log.w("MotionDetection", "TensorFlow Lite model not found, using fallback detection: ${e.message}")
        }
    }
    
    fun startDetection(callback: (Map<String, Any>) -> Unit) {
        motionCallback = callback
        isDetecting = true
        sensorData.clear()
        
        accelerometer?.let {
            sensorManager.registerListener(this, it, samplingRate)
        }
        gyroscope?.let {
            sensorManager.registerListener(this, it, samplingRate)
        }
    }
    
    fun stopDetection() {
        isDetecting = false
        sensorManager.unregisterListener(this)
        motionCallback = null
    }
    
    override fun onSensorChanged(event: SensorEvent) {
        if (!isDetecting) return
        
        when (event.sensor.type) {
            Sensor.TYPE_ACCELEROMETER -> {
                val magnitude = sqrt(
                    event.values[0] * event.values[0] +
                    event.values[1] * event.values[1] +
                    event.values[2] * event.values[2]
                )
                
                // Store sensor data for windowing
                val dataPoint = floatArrayOf(
                    event.values[0], event.values[1], event.values[2], magnitude
                )
                
                synchronized(sensorData) {
                    sensorData.add(dataPoint)
                    if (sensorData.size > windowSize) {
                        sensorData.removeAt(0)
                    }
                    
                    // Process data when window is full
                    if (sensorData.size == windowSize) {
                        processMotionData()
                    }
                }
            }
        }
    }
    
    private fun processMotionData() {
        try {
            val motionState = if (tflite != null) {
                classifyWithTensorFlow()
            } else {
                classifyWithThreshold()
            }
            
            val result = mapOf(
                "motionState" to motionState,
                "timestamp" to System.currentTimeMillis(),
                "confidence" to 1.0
            )
            
            motionCallback?.invoke(result)
        } catch (e: Exception) {
            android.util.Log.e("MotionDetection", "Error processing motion data: ${e.message}")
        }
    }
    
    private fun classifyWithTensorFlow(): String {
        // Prepare input data
        val inputFeatures = extractFeatures()
        val input = Array(1) { inputFeatures }
        val output = Array(1) { FloatArray(motionStates.size) }
        
        // Run inference
        tflite?.run(input, output)
        
        // Find the class with highest probability
        val predictions = output[0]
        val maxIndex = predictions.indices.maxByOrNull { predictions[it] } ?: 0
        
        return motionStates[maxIndex]
    }
    
    private fun classifyWithThreshold(): String {
        // Simple threshold-based classification as fallback
        val magnitudes = sensorData.map { it[3] } // magnitude is at index 3
        val avgMagnitude = magnitudes.average()
        val variance = magnitudes.map { (it - avgMagnitude) * (it - avgMagnitude) }.average()
        
        return when {
            avgMagnitude < 9.0 -> "stationary"
            avgMagnitude < 11.0 && variance < 2.0 -> "walking"
            avgMagnitude < 15.0 && variance > 2.0 -> "running"
            else -> "vehicle"
        }
    }
    
    private fun extractFeatures(): FloatArray {
        // Extract statistical features from the sensor data window
        val magnitudes = sensorData.map { it[3] }
        val xValues = sensorData.map { it[0] }
        val yValues = sensorData.map { it[1] }
        val zValues = sensorData.map { it[2] }
        
        return floatArrayOf(
            magnitudes.average().toFloat(),
            magnitudes.maxOrNull() ?: 0f,
            magnitudes.minOrNull() ?: 0f,
            calculateVariance(magnitudes).toFloat(),
            xValues.average().toFloat(),
            yValues.average().toFloat(),
            zValues.average().toFloat(),
            calculateVariance(xValues).toFloat(),
            calculateVariance(yValues).toFloat(),
            calculateVariance(zValues).toFloat()
        )
    }
    
    private fun calculateVariance(values: List<Float>): Double {
        val mean = values.average()
        return values.map { (it - mean) * (it - mean) }.average()
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used
    }
}