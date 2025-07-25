#!/bin/bash

# Download Google TensorFlow Lite Activity Recognition Model
echo "Downloading TensorFlow Lite Activity Recognition model..."

MODEL_URL="https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/activity_classification/rnn_classifier.tflite"
MODEL_PATH="assets/models/activity_classification.tflite"

# Create models directory if it doesn't exist
mkdir -p assets/models

# Download the model
curl -L "$MODEL_URL" -o "$MODEL_PATH"

if [ $? -eq 0 ]; then
    echo "Model downloaded successfully to $MODEL_PATH"
    
    # Check file size to verify download
    SIZE=$(stat -c%s "$MODEL_PATH" 2>/dev/null || stat -f%z "$MODEL_PATH" 2>/dev/null)
    if [ "$SIZE" -gt 1000 ]; then
        echo "Download verified - file size: $SIZE bytes"
    else
        echo "Warning: Downloaded file seems too small ($SIZE bytes). Check your internet connection."
    fi
else
    echo "Failed to download model. Please check your internet connection."
    echo "You can try again later by running: $0"
fi