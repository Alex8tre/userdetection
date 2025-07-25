#!/usr/bin/env python3
"""
Test script to validate the TensorFlow Lite motion classification model.
This script verifies that the model can be loaded and used for inference.
"""

import numpy as np

try:
    import tensorflow as tf
    
    def test_motion_model():
        """Test the motion classification model."""
        
        model_path = "assets/models/motion_classifier.tflite"
        
        # Load the TensorFlow Lite model
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print("=== TensorFlow Lite Motion Model Test ===")
        print(f"Model path: {model_path}")
        print(f"Input shape: {input_details[0]['shape']}")
        print(f"Input type: {input_details[0]['dtype']}")
        print(f"Output shape: {output_details[0]['shape']}")
        print(f"Output type: {output_details[0]['dtype']}")
        
        # Test with different motion patterns
        motion_classes = ["stationary", "walking", "running", "vehicle"]
        
        # Test case 1: Low motion (stationary)
        low_motion = np.array([[
            0.2, 0.5, 0.1, 0.1,  # magnitude features
            0.1, 0.1, 0.0,       # average accelerations
            0.05, 0.05, 0.05     # variances
        ]], dtype=np.float32)
        
        # Test case 2: Medium motion (walking) 
        medium_motion = np.array([[
            0.5, 1.0, 0.2, 0.3,  # magnitude features
            0.3, 0.2, 0.1,       # average accelerations
            0.15, 0.10, 0.08     # variances
        ]], dtype=np.float32)
        
        # Test case 3: High motion (running)
        high_motion = np.array([[
            0.8, 1.5, 0.3, 0.5,  # magnitude features
            0.6, 0.4, 0.2,       # average accelerations
            0.25, 0.20, 0.15     # variances
        ]], dtype=np.float32)
        
        # Test case 4: Very high motion (vehicle)
        vehicle_motion = np.array([[
            1.2, 2.0, 0.5, 0.8,  # magnitude features
            0.8, 0.6, 0.4,       # average accelerations
            0.35, 0.30, 0.25     # variances
        ]], dtype=np.float32)
        
        test_cases = [
            ("Low motion (stationary)", low_motion),
            ("Medium motion (walking)", medium_motion),
            ("High motion (running)", high_motion),
            ("Very high motion (vehicle)", vehicle_motion)
        ]
        
        print("\n=== Test Cases ===")
        for test_name, test_input in test_cases:
            # Set input tensor
            interpreter.set_tensor(input_details[0]['index'], test_input)
            
            # Run inference
            interpreter.invoke()
            
            # Get output
            output = interpreter.get_tensor(output_details[0]['index'])
            predicted_class_idx = np.argmax(output[0])
            confidence = output[0][predicted_class_idx]
            
            print(f"\n{test_name}:")
            print(f"  Input features: {test_input[0]}")
            print(f"  Predicted class: {motion_classes[predicted_class_idx]}")
            print(f"  Confidence: {confidence:.3f}")
            print(f"  All probabilities: {[f'{prob:.3f}' for prob in output[0]]}")
        
        print("\n=== Test Completed Successfully ===")
        return True
        
    if __name__ == "__main__":
        test_motion_model()
        
except ImportError:
    print("TensorFlow not available. Model testing skipped.")
    print("To test the model, install TensorFlow: pip install tensorflow")