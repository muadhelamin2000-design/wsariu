import 'dart:async';
import 'package:flutter/foundation.dart';

class StudyTimerService {
  static final StudyTimerService _instance = StudyTimerService._internal();
  factory StudyTimerService() => _instance;
  StudyTimerService._internal();

  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isActive = false;
  bool _isStudyPhase = true;
  
  int _studyMinutes = 25;
  int _breakMinutes = 5;

  final _stateController = StreamController<void>.broadcast();
  Stream<void> get stateStream => _stateController.stream;

  int get secondsRemaining => _secondsRemaining;
  bool get isActive => _isActive;
  bool get isStudyPhase => _isStudyPhase;
  int get studyMinutes => _studyMinutes;
  int get breakMinutes => _breakMinutes;

  void setSettings(int study, int breakMin) {
    _studyMinutes = study;
    _breakMinutes = breakMin;
    if (!_isActive) {
      _secondsRemaining = (_isStudyPhase ? _studyMinutes : _breakMinutes) * 60;
      _stateController.add(null);
    }
  }

  void toggleTimer({required Function onComplete}) {
    if (_isActive) {
      _timer?.cancel();
      _isActive = false;
    } else {
      _isActive = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _stateController.add(null);
        } else {
          _timer?.cancel();
          _isActive = false;
          onComplete();
          _stateController.add(null);
        }
      });
    }
    _stateController.add(null);
  }

  void reset() {
    _timer?.cancel();
    _isActive = false;
    _secondsRemaining = (_isStudyPhase ? _studyMinutes : _breakMinutes) * 60;
    _stateController.add(null);
  }

  void startBreak() {
    _isStudyPhase = false;
    _secondsRemaining = _breakMinutes * 60;
    _stateController.add(null);
  }

  void startStudy() {
    _isStudyPhase = true;
    _secondsRemaining = _studyMinutes * 60;
    _stateController.add(null);
  }
  
  void dispose() {
    _timer?.cancel();
  }
}

final studyTimerService = StudyTimerService();
