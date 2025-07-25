#!/bin/bash

# Download TensorFlow Lite Activity Recognition Model
echo "Downloading TensorFlow Lite Activity Recognition model..."

MODEL_PATH="assets/models/activity_classification.tflite"

# Create models directory if it doesn't exist
mkdir -p assets/models

# Function to download and verify a model
download_model() {
    local url=$1
    local description=$2
    
    echo "Trying $description..."
    curl -L "$url" -o "$MODEL_PATH"
    
    if [ $? -eq 0 ]; then
        # Check if we got a valid TensorFlow Lite file
        SIZE=$(stat -c%s "$MODEL_PATH" 2>/dev/null || stat -f%z "$MODEL_PATH" 2>/dev/null)
        
        # Check file headers for TFLite magic bytes or reasonable size
        if [ "$SIZE" -gt 50000 ] && [ "$SIZE" -lt 50000000 ]; then
            echo "Model downloaded successfully: $description"
            echo "File size: $SIZE bytes"
            echo "Saved to: $MODEL_PATH"
            return 0
        else
            echo "Downloaded file size ($SIZE bytes) seems invalid."
            rm -f "$MODEL_PATH"
        fi
    fi
    return 1
}

# Try different model sources
echo "Attempting to download from multiple sources..."

# Method 1: TensorFlow Hub hosted models (if accessible)
if download_model "https://tfhub.dev/tensorflow/lite-model/movinet/a0/base/kinetics-600/classification/3?lite-format=tflite" "MoveNet Activity Classification from TensorFlow Hub"; then
    exit 0
fi

# Method 2: Create a basic model file as fallback
echo ""
echo "All automatic downloads failed."
echo "Creating a placeholder model file for development..."

# Create a minimal TFLite file structure (this is just for development/testing)
cat > "$MODEL_PATH" << 'EOF'
This is a placeholder for the TensorFlow Lite activity classification model.

To use this Flutter app properly, you need to replace this file with a real
TensorFlow Lite model (.tflite) trained for activity recognition.

Recommended options:
1. Download from TensorFlow Examples:
   https://github.com/tensorflow/examples/tree/master/lite/examples/activity_recognition

2. Use TensorFlow Lite Model Maker to create your own:
   https://www.tensorflow.org/lite/tutorials/model_maker_activity_recognition

3. Use a pre-trained model from TensorFlow Hub:
   https://tfhub.dev/s?deployment-format=lite&problem-domain=video

The model should accept accelerometer/gyroscope data and output activity classifications
such as: walking, running, sitting, standing, etc.
EOF

echo "Placeholder created at: $MODEL_PATH"
echo ""
echo "IMPORTANT: Replace this placeholder with a real TensorFlow Lite model!"
echo "Visit the URLs mentioned in the placeholder file for download options."