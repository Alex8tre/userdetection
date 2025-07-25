import 'package:flutter/material.dart';
import 'dart:async';
import 'services/motion_detection_service.dart';
import 'models/motion_state.dart';

void main() {
  runApp(const UserDetectionApp());
}

class UserDetectionApp extends StatelessWidget {
  const UserDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Activity Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MotionDetectionScreen(),
    );
  }
}

class MotionDetectionScreen extends StatefulWidget {
  const MotionDetectionScreen({super.key});

  @override
  State<MotionDetectionScreen> createState() => _MotionDetectionScreenState();
}

class _MotionDetectionScreenState extends State<MotionDetectionScreen> {
  final MotionDetectionService _motionService = MotionDetectionService();
  
  MotionState? _currentMotionState;
  bool _isDetecting = false;
  bool _hasPermissions = false;
  StreamSubscription<MotionState>? _motionSubscription;
  
  final Map<String, IconData> _activityIcons = {
    'Fermo': Icons.person,
    'Camminando': Icons.directions_walk,
    'Correndo': Icons.directions_run,
    'In Veicolo': Icons.directions_car,
    'In Bicicletta': Icons.directions_bike,
  };
  
  final Map<String, Color> _activityColors = {
    'Fermo': Colors.grey,
    'Camminando': Colors.green,
    'Correndo': Colors.orange,
    'In Veicolo': Colors.blue,
    'In Bicicletta': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _stopDetection();
    _motionService.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final hasPermissions = await _motionService.hasPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _motionService.requestPermissions();
    setState(() {
      _hasPermissions = granted;
    });
    
    if (!granted) {
      _showSnackBar('Permessi per i sensori necessari per il rilevamento dell\'attività');
    }
  }

  Future<void> _startDetection() async {
    if (!_hasPermissions) {
      await _requestPermissions();
      if (!_hasPermissions) return;
    }

    final started = await _motionService.startDetection();
    if (started) {
      setState(() {
        _isDetecting = true;
      });
      
      _motionSubscription = _motionService.motionStateStream.listen(
        (motionState) {
          setState(() {
            _currentMotionState = motionState;
          });
        },
        onError: (error) {
          _showSnackBar('Errore nel rilevamento: $error');
          _stopDetection();
        },
      );
      
      _showSnackBar('Rilevamento attività avviato');
    } else {
      _showSnackBar('Impossibile avviare il rilevamento');
    }
  }

  Future<void> _stopDetection() async {
    await _motionService.stopDetection();
    await _motionSubscription?.cancel();
    _motionSubscription = null;
    
    setState(() {
      _isDetecting = false;
      _currentMotionState = null;
    });
    
    _showSnackBar('Rilevamento attività fermato');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rilevamento Attività Utente'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _isDetecting ? Icons.sensors : Icons.sensors_off,
                      size: 48,
                      color: _isDetecting ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isDetecting ? 'Rilevamento Attivo' : 'Rilevamento Inattivo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasPermissions 
                          ? 'Permessi concessi' 
                          : 'Permessi richiesti per i sensori',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _hasPermissions ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Current activity card
            if (_currentMotionState != null) ...[
              Card(
                elevation: 4,
                color: _activityColors[_currentMotionState!.activity]?.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        _activityIcons[_currentMotionState!.activity] ?? Icons.help,
                        size: 64,
                        color: _activityColors[_currentMotionState!.activity],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentMotionState!.activity,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _activityColors[_currentMotionState!.activity],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confidenza: ${(_currentMotionState!.confidence * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ultimo aggiornamento: ${_formatTime(_currentMotionState!.timestamp)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_isDetecting) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Raccolta dati in corso...',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attendere almeno 2 secondi per la prima classificazione',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Activity legend
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attività Rilevabili:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...MotionState.activityMapping.values.map((activity) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              _activityIcons[activity],
                              color: _activityColors[activity],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(activity),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Control button
            ElevatedButton.icon(
              onPressed: _isDetecting ? _stopDetection : _startDetection,
              icon: Icon(_isDetecting ? Icons.stop : Icons.play_arrow),
              label: Text(_isDetecting ? 'Ferma Rilevamento' : 'Avvia Rilevamento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isDetecting ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }
}