# TensorFlow Lite Model Setup

## Problem Solved

The original Google Cloud Storage URL for the TensorFlow Lite activity recognition model is no longer publicly accessible, returning an "Access Denied" error. This has been resolved with multiple alternative approaches.

## Solutions Provided

### 1. Updated Download Script (`download_model.sh`)

The script now:
- Attempts to download from multiple alternative sources
- Validates downloaded files to ensure they're actual TensorFlow Lite models (not HTML error pages)
- Creates a helpful placeholder with instructions if automatic download fails

### 2. Python Model Creator (`create_model.py`)

A comprehensive Python script that can:
- Download pre-trained models from alternative sources
- Create a demo TensorFlow Lite model for testing (with `--demo` flag)
- Generate detailed placeholder instructions

## Quick Setup Options

### Option A: Use the Shell Script
```bash
./download_model.sh
```

### Option B: Use Python Script for Demo Model
```bash
# Install TensorFlow first
pip install tensorflow

# Create a demo model
python3 create_model.py --demo
```

### Option C: Manual Download
1. Visit: https://github.com/tensorflow/examples/tree/master/lite/examples/activity_recognition/android/app/src/main/assets
2. Download `lstm_activity_recognition.tflite`
3. Save as `assets/models/activity_classification.tflite`

### Option D: Train Your Own Model
Follow the TensorFlow Lite Model Maker tutorial:
https://www.tensorflow.org/lite/tutorials/model_maker_activity_recognition

## Model Requirements

Your TensorFlow Lite model should:
- Accept sensor data input (accelerometer + gyroscope)
- Output activity classifications
- Be in `.tflite` format
- Support activities like: sitting, standing, walking, running, stairs_up, stairs_down

## Expected Model Size

A typical activity recognition TensorFlow Lite model should be:
- **50KB - 5MB** in size
- If your downloaded file is under 10KB, it's likely an error message

## Current Status

✅ **Fixed**: Download script handles access denied errors gracefully  
✅ **Added**: Multiple fallback options  
✅ **Added**: Python script for creating demo models  
✅ **Added**: Comprehensive instructions for manual setup  

The Flutter app can now proceed with development using either a demo model or a manually downloaded model.
