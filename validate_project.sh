#!/bin/bash

# Validation script for Flutter motion detection project
echo "🔍 Validating Flutter Motion Detection Project..."

# Check project structure
echo "📁 Checking project structure..."

REQUIRED_FILES=(
    "pubspec.yaml"
    "lib/main.dart"
    "lib/models.dart"
    "lib/motion_location_platform.dart"
    "android/app/src/main/kotlin/com/example/motionlocation/MainActivity.kt"
    "android/app/src/main/kotlin/com/example/motionlocation/MotionDetectionService.kt"
    "android/app/src/main/kotlin/com/example/motionlocation/LocationService.kt"
    "android/app/src/main/kotlin/com/example/motionlocation/ProximityDetector.kt"
    "ios/Runner/AppDelegate.swift"
    "ios/Runner/MotionDetectionService.swift"
    "ios/Runner/LocationService.swift"
    "ios/Runner/ProximityDetector.swift"
    "android/app/src/main/AndroidManifest.xml"
    "ios/Runner/Info.plist"
)

MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        MISSING_FILES+=("$file")
    else
        echo "✅ $file"
    fi
done

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
    echo "✅ All required files present"
else
    echo "❌ Missing files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
fi

# Check for key features in source files
echo ""
echo "🔍 Checking implementation features..."

# Check Android MainActivity for MethodChannel
if grep -q "MethodChannel" android/app/src/main/kotlin/com/example/motionlocation/MainActivity.kt; then
    echo "✅ Android MethodChannel integration found"
else
    echo "❌ Android MethodChannel integration missing"
fi

# Check for TensorFlow Lite imports
if grep -q "tensorflow" android/app/src/main/kotlin/com/example/motionlocation/MotionDetectionService.kt; then
    echo "✅ Android TensorFlow Lite integration found"
else
    echo "❌ Android TensorFlow Lite integration missing"
fi

# Check iOS AppDelegate for Flutter integration
if grep -q "FlutterMethodChannel" ios/Runner/AppDelegate.swift; then
    echo "✅ iOS Flutter integration found"
else
    echo "❌ iOS Flutter integration missing"
fi

# Check for location permissions
if grep -q "ACCESS_FINE_LOCATION" android/app/src/main/AndroidManifest.xml; then
    echo "✅ Android location permissions found"
else
    echo "❌ Android location permissions missing"
fi

if grep -q "NSLocationWhenInUseUsageDescription" ios/Runner/Info.plist; then
    echo "✅ iOS location permissions found"
else
    echo "❌ iOS location permissions missing"
fi

# Check Flutter dependencies
if grep -q "permission_handler" pubspec.yaml && grep -q "geolocator" pubspec.yaml; then
    echo "✅ Flutter dependencies configured"
else
    echo "❌ Flutter dependencies missing"
fi

# Check for Italian UI strings
if grep -q "Rilevamento Movimento" lib/main.dart; then
    echo "✅ Italian UI localization found"
else
    echo "❌ Italian UI localization missing"
fi

# Count lines of code
echo ""
echo "📊 Code Statistics:"
echo "Dart files: $(find lib -name "*.dart" | wc -l)"
echo "Kotlin files: $(find android -name "*.kt" | wc -l)"
echo "Swift files: $(find ios -name "*.swift" | wc -l)"
echo "Total lines of code: $(find lib android/app/src/main/kotlin ios/Runner -name "*.dart" -o -name "*.kt" -o -name "*.swift" | xargs wc -l | tail -1 | awk '{print $1}')"

echo ""
echo "🎯 Validation complete!"

# Summary
TOTAL_REQUIRED=${#REQUIRED_FILES[@]}
TOTAL_PRESENT=$((TOTAL_REQUIRED - ${#MISSING_FILES[@]}))

echo "📈 Summary: $TOTAL_PRESENT/$TOTAL_REQUIRED required files present"

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
    echo "🎉 Project structure validation PASSED"
    exit 0
else
    echo "⚠️  Project structure validation FAILED"
    exit 1
fi