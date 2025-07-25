import 'package:flutter_test/flutter_test.dart';
import 'package:userdetection/models/motion_state.dart';

void main() {
  group('MotionState Tests', () {
    test('should create MotionState from classification with Italian mapping', () {
      // Test each activity class
      final testCases = [
        {'classIndex': 0, 'expectedActivity': 'Fermo'},
        {'classIndex': 1, 'expectedActivity': 'Camminando'},
        {'classIndex': 2, 'expectedActivity': 'Correndo'},
        {'classIndex': 3, 'expectedActivity': 'In Veicolo'},
        {'classIndex': 4, 'expectedActivity': 'In Bicicletta'},
      ];

      for (final testCase in testCases) {
        final classIndex = testCase['classIndex'] as int;
        final expectedActivity = testCase['expectedActivity'] as String;
        final confidence = 0.85;

        final motionState = MotionState.fromClassification(classIndex, confidence);

        expect(motionState.activity, equals(expectedActivity));
        expect(motionState.confidence, equals(confidence));
        expect(motionState.timestamp, isA<DateTime>());
      }
    });

    test('should handle unknown class index', () {
      const unknownClassIndex = 999;
      const confidence = 0.5;

      final motionState = MotionState.fromClassification(unknownClassIndex, confidence);

      expect(motionState.activity, equals('Sconosciuto'));
      expect(motionState.confidence, equals(confidence));
    });

    test('should have correct activity mapping', () {
      expect(MotionState.activityMapping[0], equals('Fermo'));
      expect(MotionState.activityMapping[1], equals('Camminando'));
      expect(MotionState.activityMapping[2], equals('Correndo'));
      expect(MotionState.activityMapping[3], equals('In Veicolo'));
      expect(MotionState.activityMapping[4], equals('In Bicicletta'));
    });

    test('should have correct English activity mapping', () {
      expect(MotionState.englishActivityMapping[0], equals('Still'));
      expect(MotionState.englishActivityMapping[1], equals('Walking'));
      expect(MotionState.englishActivityMapping[2], equals('Running'));
      expect(MotionState.englishActivityMapping[3], equals('In Vehicle'));
      expect(MotionState.englishActivityMapping[4], equals('On Bicycle'));
    });

    test('toString should format correctly', () {
      final motionState = MotionState.fromClassification(1, 0.856);
      final string = motionState.toString();

      expect(string, contains('Camminando'));
      expect(string, contains('85.6%'));
      expect(string, contains('MotionState'));
    });
  });
}