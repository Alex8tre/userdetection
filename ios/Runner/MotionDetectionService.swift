import CoreMotion
import Foundation
import TensorFlowLite

class MotionDetectionService {
    
    private let motionManager = CMMotionManager()
    private var motionCallback: (([String: Any]) -> Void)?
    private var isDetecting = false
    
    private var interpreter: Interpreter?
    private var sensorData: [[Float]] = []
    private let windowSize = 50
    private let samplingRate = 0.02 // 50Hz
    
    // Motion states
    private let motionStates = ["stationary", "walking", "running", "vehicle"]
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelPath = Bundle.main.path(forResource: "motion_classifier", ofType: "tflite") else {
            print("TensorFlow Lite model not found, using fallback detection")
            return
        }
        
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
        } catch {
            print("Failed to create TensorFlow Lite interpreter: \(error)")
        }
    }
    
    func startDetection(callback: @escaping ([String: Any]) -> Void) {
        motionCallback = callback
        isDetecting = true
        sensorData.removeAll()
        
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = samplingRate
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let accelerometerData = data, self.isDetecting else { return }
            
            let magnitude = sqrt(
                accelerometerData.acceleration.x * accelerometerData.acceleration.x +
                accelerometerData.acceleration.y * accelerometerData.acceleration.y +
                accelerometerData.acceleration.z * accelerometerData.acceleration.z
            )
            
            let dataPoint = [
                Float(accelerometerData.acceleration.x),
                Float(accelerometerData.acceleration.y),
                Float(accelerometerData.acceleration.z),
                Float(magnitude)
            ]
            
            self.sensorData.append(dataPoint)
            
            if self.sensorData.count > self.windowSize {
                self.sensorData.removeFirst()
            }
            
            if self.sensorData.count == self.windowSize {
                self.processMotionData()
            }
        }
    }
    
    func stopDetection() {
        isDetecting = false
        motionManager.stopAccelerometerUpdates()
        motionCallback = nil
    }
    
    private func processMotionData() {
        let motionState: String
        
        if interpreter != nil {
            motionState = classifyWithTensorFlow()
        } else {
            motionState = classifyWithThreshold()
        }
        
        let result: [String: Any] = [
            "motionState": motionState,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "confidence": 1.0
        ]
        
        motionCallback?(result)
    }
    
    private func classifyWithTensorFlow() -> String {
        guard let interpreter = interpreter else {
            return classifyWithThreshold()
        }
        
        do {
            // Prepare input data
            let inputFeatures = extractFeatures()
            let inputData = Data(bytes: inputFeatures, count: inputFeatures.count * MemoryLayout<Float>.size)
            
            // Run inference
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            
            // Get output
            let outputTensor = try interpreter.output(at: 0)
            let outputData = outputTensor.data
            let outputArray = outputData.withUnsafeBytes { bytes in
                Array(bytes.bindMemory(to: Float.self))
            }
            
            // Find class with highest probability
            if let maxIndex = outputArray.enumerated().max(by: { $0.element < $1.element })?.offset,
               maxIndex < motionStates.count {
                return motionStates[maxIndex]
            }
            
        } catch {
            print("Error during TensorFlow inference: \(error)")
        }
        
        return classifyWithThreshold()
    }
    
    private func classifyWithThreshold() -> String {
        let magnitudes = sensorData.map { $0[3] }
        let avgMagnitude = magnitudes.reduce(0, +) / Float(magnitudes.count)
        let variance = magnitudes.map { pow($0 - avgMagnitude, 2) }.reduce(0, +) / Float(magnitudes.count)
        
        switch avgMagnitude {
        case ..<9.0:
            return "stationary"
        case 9.0..<11.0 where variance < 2.0:
            return "walking"
        case 11.0..<15.0 where variance > 2.0:
            return "running"
        default:
            return "vehicle"
        }
    }
    
    private func extractFeatures() -> [Float] {
        let magnitudes = sensorData.map { $0[3] }
        let xValues = sensorData.map { $0[0] }
        let yValues = sensorData.map { $0[1] }
        let zValues = sensorData.map { $0[2] }
        
        return [
            magnitudes.reduce(0, +) / Float(magnitudes.count), // avg magnitude
            magnitudes.max() ?? 0, // max magnitude
            magnitudes.min() ?? 0, // min magnitude
            calculateVariance(magnitudes), // magnitude variance
            xValues.reduce(0, +) / Float(xValues.count), // avg x
            yValues.reduce(0, +) / Float(yValues.count), // avg y
            zValues.reduce(0, +) / Float(zValues.count), // avg z
            calculateVariance(xValues), // x variance
            calculateVariance(yValues), // y variance
            calculateVariance(zValues)  // z variance
        ]
    }
    
    private func calculateVariance(_ values: [Float]) -> Float {
        let mean = values.reduce(0, +) / Float(values.count)
        let squaredDeviations = values.map { pow($0 - mean, 2) }
        return squaredDeviations.reduce(0, +) / Float(values.count)
    }
}