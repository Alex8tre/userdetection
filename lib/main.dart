import 'package:flutter/material.dart';
import 'motion_location_platform.dart';
import 'models.dart';

void main() {
  runApp(const UserDetectionApp());
}

class UserDetectionApp extends StatelessWidget {
  const UserDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rilevamento Movimento e Posizione',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MotionLocationScreen(),
    );
  }
}

class MotionLocationScreen extends StatefulWidget {
  const MotionLocationScreen({super.key});

  @override
  State<MotionLocationScreen> createState() => _MotionLocationScreenState();
}

class _MotionLocationScreenState extends State<MotionLocationScreen> {
  MotionState? _currentMotionState;
  LocationData? _currentLocation;
  ProximityResult? _lastProximityResult;
  bool _isMotionDetectionActive = false;
  bool _isLocationTrackingActive = false;

  // Punti di interesse di esempio (Milano, Roma, Firenze)
  final List<TargetLocation> _targetLocations = [
    TargetLocation(latitude: 45.4642, longitude: 9.1900, name: 'Milano Centro'),
    TargetLocation(latitude: 41.9028, longitude: 12.4964, name: 'Roma Centro'),
    TargetLocation(latitude: 43.7696, longitude: 11.2558, name: 'Firenze Centro'),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await MotionLocationPlatform.requestPermissions();
    await MotionLocationPlatform.setTargetLocations(_targetLocations);
  }

  Future<void> _toggleMotionDetection() async {
    if (_isMotionDetectionActive) {
      await MotionLocationPlatform.stopMotionDetection();
      setState(() {
        _isMotionDetectionActive = false;
      });
    } else {
      await MotionLocationPlatform.startMotionDetection(
        onMotionStateChanged: (motionState) {
          setState(() {
            _currentMotionState = motionState;
          });
          _checkProximityIfLocationAvailable();
        },
      );
      setState(() {
        _isMotionDetectionActive = true;
      });
    }
  }

  Future<void> _toggleLocationTracking() async {
    if (_isLocationTrackingActive) {
      await MotionLocationPlatform.stopLocationTracking();
      setState(() {
        _isLocationTrackingActive = false;
      });
    } else {
      await MotionLocationPlatform.startLocationTracking(
        onLocationChanged: (locationData) {
          setState(() {
            _currentLocation = locationData;
          });
          _checkProximityIfLocationAvailable();
        },
      );
      setState(() {
        _isLocationTrackingActive = true;
      });
    }
  }

  Future<void> _checkProximityIfLocationAvailable() async {
    if (_currentLocation != null && _currentMotionState != null) {
      final result = await MotionLocationPlatform.checkProximity(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        motionState: _currentMotionState!.state,
        onProximityDetected: (proximityResult) {
          setState(() {
            _lastProximityResult = proximityResult;
          });
          _showProximityNotification(proximityResult);
        },
      );

      if (result != null) {
        setState(() {
          _lastProximityResult = result;
        });
      }
    }
  }

  void _showProximityNotification(ProximityResult result) {
    final targetName = _targetLocations[result.targetIndex].name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vicino a $targetName (${result.distance.toStringAsFixed(0)}m)',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rilevamento Movimento e Posizione'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMotionDetectionCard(),
            const SizedBox(height: 16),
            _buildLocationTrackingCard(),
            const SizedBox(height: 16),
            _buildProximityCard(),
            const SizedBox(height: 16),
            _buildTargetLocationsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMotionDetectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rilevamento Movimento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isMotionDetectionActive,
                  onChanged: (_) => _toggleMotionDetection(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentMotionState != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMotionStateColor(_currentMotionState!.state),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentMotionState!.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${(_currentMotionState!.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_isMotionDetectionActive) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              const Text(
                'Attiva il rilevamento per iniziare',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monitoraggio Posizione',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isLocationTrackingActive,
                  onChanged: (_) => _toggleLocationTracking(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentLocation != null) ...[
              _buildLocationInfoRow('Latitudine', _currentLocation!.latitude.toStringAsFixed(6)),
              _buildLocationInfoRow('Longitudine', _currentLocation!.longitude.toStringAsFixed(6)),
              _buildLocationInfoRow('Precisione', '${_currentLocation!.accuracy.toStringAsFixed(1)}m'),
              _buildLocationInfoRow('Velocità', '${(_currentLocation!.speed * 3.6).toStringAsFixed(1)} km/h'),
              _buildLocationInfoRow('Provider', _currentLocation!.provider),
            ] else if (_isLocationTrackingActive) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              const Text(
                'Attiva il monitoraggio per iniziare',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildProximityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rilevamento Prossimità',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_lastProximityResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vicino a ${_targetLocations[_lastProximityResult!.targetIndex].name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Distanza: ${_lastProximityResult!.distance.toStringAsFixed(0)}m'),
                    Text('Soglia: ${_lastProximityResult!.threshold.toStringAsFixed(0)}m'),
                    Text('Stato movimento: ${MotionState(state: _lastProximityResult!.motionState, timestamp: DateTime.now(), confidence: 1.0).displayName}'),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Nessun punto di interesse nelle vicinanze',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLocationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Punti di Interesse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._targetLocations.asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('${index + 1}'),
                ),
                title: Text(location.name),
                subtitle: Text(
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                ),
                trailing: _currentLocation != null
                    ? Text(
                        '${_calculateDistance(_currentLocation!, location).toStringAsFixed(0)}m',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )
                    : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getMotionStateColor(String state) {
    switch (state) {
      case 'stationary':
        return Colors.grey;
      case 'walking':
        return Colors.green;
      case 'running':
        return Colors.orange;
      case 'vehicle':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  double _calculateDistance(LocationData currentLocation, TargetLocation target) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371000; // meters
    final lat1Rad = currentLocation.latitude * (3.14159 / 180);
    final lat2Rad = target.latitude * (3.14159 / 180);
    final deltaLatRad = (target.latitude - currentLocation.latitude) * (3.14159 / 180);
    final deltaLngRad = (target.longitude - currentLocation.longitude) * (3.14159 / 180);

    final a = (deltaLatRad / 2).sin() * (deltaLatRad / 2).sin() +
        lat1Rad.cos() * lat2Rad.cos() * (deltaLngRad / 2).sin() * (deltaLngRad / 2).sin();
    final c = 2 * a.sqrt().atan2((1 - a).sqrt());

    return earthRadius * c;
  }

  @override
  void dispose() {
    MotionLocationPlatform.stopMotionDetection();
    MotionLocationPlatform.stopLocationTracking();
    super.dispose();
  }
}

extension on double {
  double sin() => dart.math.sin(this);
  double cos() => dart.math.cos(this);
  double sqrt() => dart.math.sqrt(this);
  double atan2(double y) => dart.math.atan2(this, y);
}

import 'dart:math' as dart.math;