# TensorFlow Lite Motion Classification Model

This directory contains the `motion_classifier.tflite` model file for motion classification.

The model is trained to classify motion states based on accelerometer data:
- Input: Feature vector of 10 elements (statistical features from 50-sample window)
- Output: 4 classes [stationary, walking, running, vehicle]

## Model Features Expected:
1. Average magnitude
2. Max magnitude  
3. Min magnitude
4. Magnitude variance
5. Average X acceleration
6. Average Y acceleration
7. Average Z acceleration
8. X variance
9. Y variance
10. Z variance

## Training Data Requirements:
- Window size: 50 samples
- Sampling rate: 50Hz
- Features extracted from accelerometer data
- Labels: 0=stationary, 1=walking, 2=running, 3=vehicle

For now, the application will use fallback threshold-based classification if the model is not present.

## Model Implementation

The included `motion_classifier.tflite` model is a simple neural network with:
- Input layer: 10 features (as described above)
- Hidden layer 1: 16 neurons with ReLU activation
- Hidden layer 2: 8 neurons with ReLU activation  
- Output layer: 4 neurons with softmax activation (probability distribution)

The model outputs probabilities for each class:
- Index 0: stationary
- Index 1: walking
- Index 2: running  
- Index 3: vehicle

## Usage in Code

The model is automatically loaded by both Android and iOS implementations:
- Android: `MotionDetectionService.kt` loads the model from assets
- iOS: `MotionDetectionService.swift` loads the model from app bundle

If the model fails to load, the system gracefully falls back to threshold-based detection.