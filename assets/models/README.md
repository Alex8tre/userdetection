# TensorFlow Lite Motion Classification Model

This directory should contain the `motion_classifier.tflite` model file.

The model should be trained to classify motion states based on accelerometer data:
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