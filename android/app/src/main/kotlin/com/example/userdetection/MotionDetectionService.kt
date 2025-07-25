package com.example.userdetection

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlinx.coroutines.*
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.util.*
import kotlin.collections.ArrayList

class MotionDetectionService(private val context: Context) : SensorEventListener {
    
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var gyroscope: Sensor? = null
    
    private var tfliteInterpreter: Interpreter? = null
    private val sensorDataBuffer = ArrayList<FloatArray>()
    private val maxBufferSize = 50 // 50 samples as required by the model
    
    private var onActivityDetected: ((Int, Float) -> Unit)? = null
    
    companion object {
        private const val MODEL_FILE = "activity_classification.tflite"
        private const val SAMPLING_RATE_US = 20000 // 50Hz sampling rate
    }
    
    init {
        initializeSensors()
        initializeTensorFlow()
    }
    
    private fun initializeSensors() {
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        gyroscope = sensorManager?.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    }
    
    private fun initializeTensorFlow() {
        try {
            val modelBuffer = loadModelFile()
            tfliteInterpreter = Interpreter(modelBuffer)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun loadModelFile(): MappedByteBuffer {
        val fileDescriptor = context.assets.openFd(MODEL_FILE)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        val startOffset = fileDescriptor.startOffset
        val declaredLength = fileDescriptor.declaredLength
        return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }
    
    fun startDetection(onActivityDetected: (Int, Float) -> Unit) {
        this.onActivityDetected = onActivityDetected
        
        accelerometer?.let { sensor ->
            sensorManager?.registerListener(this, sensor, SAMPLING_RATE_US)
        }
        
        gyroscope?.let { sensor ->
            sensorManager?.registerListener(this, sensor, SAMPLING_RATE_US)
        }
    }
    
    fun stopDetection() {
        sensorManager?.unregisterListener(this)
        onActivityDetected = null
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            when (it.sensor.type) {
                Sensor.TYPE_ACCELEROMETER -> {
                    processAccelerometerData(it.values)
                }
                Sensor.TYPE_GYROSCOPE -> {
                    processGyroscopeData(it.values)
                }
            }
        }
    }
    
    private var lastAccelerometerData: FloatArray? = null
    private var lastGyroscopeData: FloatArray? = null
    
    private fun processAccelerometerData(values: FloatArray) {
        lastAccelerometerData = values.clone()
        tryAddSensorSample()
    }
    
    private fun processGyroscopeData(values: FloatArray) {
        lastGyroscopeData = values.clone()
        tryAddSensorSample()
    }
    
    private fun tryAddSensorSample() {
        val accel = lastAccelerometerData
        val gyro = lastGyroscopeData
        
        if (accel != null && gyro != null) {
            // Combine accelerometer and gyroscope data into 6-feature array
            val sample = FloatArray(6)
            
            // Normalize accelerometer data to [-1, 1] range
            sample[0] = normalizeAcceleration(accel[0])
            sample[1] = normalizeAcceleration(accel[1])
            sample[2] = normalizeAcceleration(accel[2])
            
            // Normalize gyroscope data to [-1, 1] range
            sample[3] = normalizeGyroscope(gyro[0])
            sample[4] = normalizeGyroscope(gyro[1])
            sample[5] = normalizeGyroscope(gyro[2])
            
            addSample(sample)
        }
    }
    
    private fun normalizeAcceleration(value: Float): Float {
        // Normalize acceleration from typical range [-20, 20] m/s² to [-1, 1]
        return (value / 20.0f).coerceIn(-1.0f, 1.0f)
    }
    
    private fun normalizeGyroscope(value: Float): Float {
        // Normalize gyroscope from typical range [-10, 10] rad/s to [-1, 1]
        return (value / 10.0f).coerceIn(-1.0f, 1.0f)
    }
    
    private fun addSample(sample: FloatArray) {
        synchronized(sensorDataBuffer) {
            sensorDataBuffer.add(sample)
            
            if (sensorDataBuffer.size > maxBufferSize) {
                sensorDataBuffer.removeAt(0)
            }
            
            if (sensorDataBuffer.size == maxBufferSize) {
                runClassification()
            }
        }
    }
    
    private fun runClassification() {
        tfliteInterpreter?.let { interpreter ->
            try {
                // Prepare input tensor [1, 50, 6]
                val input = Array(1) { Array(maxBufferSize) { FloatArray(6) } }
                
                synchronized(sensorDataBuffer) {
                    for (i in 0 until maxBufferSize) {
                        for (j in 0 until 6) {
                            input[0][i][j] = sensorDataBuffer[i][j]
                        }
                    }
                }
                
                // Prepare output tensor [1, 5]
                val output = Array(1) { FloatArray(5) }
                
                // Run inference
                interpreter.run(input, output)
                
                // Find the class with highest confidence
                val probabilities = output[0]
                var maxIndex = 0
                var maxConfidence = probabilities[0]
                
                for (i in 1 until probabilities.size) {
                    if (probabilities[i] > maxConfidence) {
                        maxConfidence = probabilities[i]
                        maxIndex = i
                    }
                }
                
                // Callback with result
                onActivityDetected?.invoke(maxIndex, maxConfidence)
                
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used
    }
    
    fun cleanup() {
        stopDetection()
        tfliteInterpreter?.close()
    }
}