import CoreMotion
import TensorFlowLite
import Foundation

class MotionDetectionService: NSObject {
    
    private let motionManager = CMMotionManager()
    private var interpreter: Interpreter?
    private var sensorDataBuffer: [[Float]] = []
    private let maxBufferSize = 50 // 50 samples as required by the model
    
    private var onActivityDetected: ((Int, Float) -> Void)?
    
    private let modelFileName = "activity_classification"
    private let samplingRate = 0.02 // 50Hz sampling rate (1/50 = 0.02 seconds)
    
    override init() {
        super.init()
        initializeTensorFlow()
    }
    
    private func initializeTensorFlow() {
        guard let modelPath = Bundle.main.path(forResource: modelFileName, ofType: "tflite") else {
            print("Failed to load model file")
            return
        }
        
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors()
        } catch {
            print("Failed to initialize TensorFlow Lite interpreter: \(error)")
        }
    }
    
    func startDetection(onActivityDetected: @escaping (Int, Float) -> Void) {
        self.onActivityDetected = onActivityDetected
        
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = samplingRate
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            self.processMotionData(motion)
        }
    }
    
    func stopDetection() {
        motionManager.stopDeviceMotionUpdates()
        onActivityDetected = nil
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) {
        let acceleration = motion.userAcceleration
        let rotationRate = motion.rotationRate
        
        // Create 6-feature sample: [acc_x, acc_y, acc_z, gyro_x, gyro_y, gyro_z]
        let sample: [Float] = [
            normalizeAcceleration(Float(acceleration.x)),
            normalizeAcceleration(Float(acceleration.y)),
            normalizeAcceleration(Float(acceleration.z)),
            normalizeGyroscope(Float(rotationRate.x)),
            normalizeGyroscope(Float(rotationRate.y)),
            normalizeGyroscope(Float(rotationRate.z))
        ]
        
        addSample(sample)
    }
    
    private func normalizeAcceleration(_ value: Float) -> Float {
        // Normalize acceleration from typical range [-20, 20] m/s² to [-1, 1]
        return max(-1.0, min(1.0, value / 20.0))
    }
    
    private func normalizeGyroscope(_ value: Float) -> Float {
        // Normalize gyroscope from typical range [-10, 10] rad/s to [-1, 1]
        return max(-1.0, min(1.0, value / 10.0))
    }
    
    private func addSample(_ sample: [Float]) {
        sensorDataBuffer.append(sample)
        
        if sensorDataBuffer.count > maxBufferSize {
            sensorDataBuffer.removeFirst()
        }
        
        if sensorDataBuffer.count == maxBufferSize {
            runClassification()
        }
    }
    
    private func runClassification() {
        guard let interpreter = interpreter else { return }
        
        do {
            // Prepare input tensor [1, 50, 6]
            let inputData = Data()
            var inputBuffer = inputData
            
            // Fill input buffer with sensor data
            for timeStep in 0..<maxBufferSize {
                for feature in 0..<6 {
                    let value = sensorDataBuffer[timeStep][feature]
                    var floatBytes = value.bitPattern.littleEndian
                    inputBuffer.append(Data(bytes: &floatBytes, count: MemoryLayout<Float>.size))
                }
            }
            
            // Copy input data to interpreter
            try interpreter.copy(inputBuffer, toInputAt: 0)
            
            // Run inference
            try interpreter.invoke()
            
            // Get output tensor
            let outputTensor = try interpreter.output(at: 0)
            
            // Parse output [1, 5] - 5 activity classes
            let outputData = outputTensor.data
            let probabilities = outputData.withUnsafeBytes { bytes in
                Array(bytes.bindMemory(to: Float.self))
            }
            
            // Find class with highest confidence
            var maxIndex = 0
            var maxConfidence = probabilities[0]
            
            for i in 1..<probabilities.count {
                if probabilities[i] > maxConfidence {
                    maxConfidence = probabilities[i]
                    maxIndex = i
                }
            }
            
            // Callback with result
            onActivityDetected?(maxIndex, maxConfidence)
            
        } catch {
            print("Failed to run classification: \(error)")
        }
    }
    
    deinit {
        stopDetection()
    }
}