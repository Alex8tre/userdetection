#!/usr/bin/env python3
"""
Script to create or download a TensorFlow Lite activity recognition model.

This script provides multiple options:
1. Download a pre-trained model from available sources
2. Create a simple demo model for testing
3. Guide for training your own model

Usage: python3 create_model.py [--demo]
"""

import os
import sys
import urllib.request
import urllib.error

def download_from_url(url, filename, description):
    """Download a file from URL with progress indication."""
    print(f"Downloading {description}...")
    try:
        def progress_hook(block_num, block_size, total_size):
            downloaded = block_num * block_size
            if total_size > 0:
                percent = min(100, (downloaded * 100) // total_size)
                print(f"\rProgress: {percent}% ({downloaded}/{total_size} bytes)", end='')
            else:
                print(f"\rDownloaded: {downloaded} bytes", end='')
        
        urllib.request.urlretrieve(url, filename, progress_hook)
        print()  # New line after progress
        
        # Verify download
        size = os.path.getsize(filename)
        if size > 50000:  # Reasonable minimum for a TFLite model
            print(f"Successfully downloaded {description}")
            print(f"File size: {size} bytes")
            return True
        else:
            print(f"Downloaded file seems too small ({size} bytes)")
            os.remove(filename)
            return False
            
    except Exception as e:
        print(f"Failed to download {description}: {e}")
        return False

def create_demo_model():
    """Create a minimal demo TensorFlow Lite model for testing."""
    try:
        import tensorflow as tf
        import numpy as np
        
        print("Creating a simple demo TensorFlow Lite model...")
        
        # Create a simple sequential model
        model = tf.keras.Sequential([
            tf.keras.layers.Input(shape=(100, 6)),  # 100 timesteps, 6 features (accel + gyro)
            tf.keras.layers.LSTM(64, return_sequences=True),
            tf.keras.layers.LSTM(32),
            tf.keras.layers.Dense(16, activation='relu'),
            tf.keras.layers.Dense(6, activation='softmax')  # 6 activity classes
        ])
        
        # Compile the model
        model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
        
        # Generate some dummy data for training
        X_dummy = np.random.random((100, 100, 6))
        y_dummy = tf.keras.utils.to_categorical(np.random.randint(0, 6, 100), 6)
        
        # Train for a few epochs with dummy data
        print("Training demo model with dummy data...")
        model.fit(X_dummy, y_dummy, epochs=1, verbose=0)
        
        # Convert to TensorFlow Lite
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        tflite_model = converter.convert()
        
        # Save the model
        model_path = "assets/models/activity_classification.tflite"
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        
        with open(model_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Demo model created successfully: {model_path}")
        print(f"Model size: {len(tflite_model)} bytes")
        
        # Print model info
        print("\nModel Information:")
        print("- Input: 100 timesteps of 6 sensor values (accelerometer + gyroscope)")
        print("- Output: 6 activity classes")
        print("- Classes: [0=sitting, 1=standing, 2=walking, 3=running, 4=stairs_up, 5=stairs_down]")
        print("\nNote: This is a demo model trained on random data. For production use,")
        print("train with real activity recognition data.")
        
        return True
        
    except ImportError:
        print("TensorFlow not found. Install with: pip install tensorflow")
        return False
    except Exception as e:
        print(f"Failed to create demo model: {e}")
        return False

def main():
    model_path = "assets/models/activity_classification.tflite"
    
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    
    # Check if --demo flag is provided
    create_demo = "--demo" in sys.argv
    
    if create_demo:
        print("Creating demo model...")
        if create_demo_model():
            return
    else:
        print("Attempting to download pre-trained models...")
        
        # Try different sources
        sources = [
            (
                "https://github.com/tensorflow/examples/raw/master/lite/examples/activity_recognition/android/app/src/main/assets/lstm_activity_recognition.tflite",
                "TensorFlow Examples LSTM Activity Recognition"
            ),
            # Add more sources here as they become available
        ]
        
        for url, description in sources:
            if download_from_url(url, model_path, description):
                return
        
        print("\nAll download attempts failed.")
        print("Creating demo model as fallback...")
        if create_demo_model():
            return
    
    # If all else fails, create placeholder
    print("\nCreating placeholder file...")
    with open(model_path, 'w') as f:
        f.write("""This is a placeholder for TensorFlow Lite activity classification model.

To get a working model:

1. Run this script with --demo flag to create a basic demo model:
   python3 create_model.py --demo

2. Download manually from:
   https://github.com/tensorflow/examples/tree/master/lite/examples/activity_recognition

3. Train your own model using TensorFlow Lite Model Maker:
   https://www.tensorflow.org/lite/tutorials/model_maker_activity_recognition

The model should:
- Accept sensor data (accelerometer/gyroscope)
- Output activity classifications (sitting, standing, walking, etc.)
- Be in TensorFlow Lite (.tflite) format
""")
    
    print(f"Placeholder created: {model_path}")
    print("Run 'python3 create_model.py --demo' to create a working demo model")

if __name__ == "__main__":
    main()
