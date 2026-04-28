import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';

class RegistrationProvider extends ChangeNotifier {
  Career? _selectedCareer;
  String? _selectedSemester;
  String? _studentRegister;
  String? _studentName;
  bool _isBlocked = false;

  RegistrationProvider() {
    _loadFromPrefs();
  }

  Career? get selectedCareer => _selectedCareer;
  String? get selectedSemester => _selectedSemester;
  String? get studentRegister => _studentRegister;
  String? get studentName => _studentName;
  bool get isBlocked => _isBlocked;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Solo cargamos si no se ha configurado ya en esta sesión (evitar sobrescritura)
    if (_studentRegister == null) {
      _studentRegister = prefs.getString('student_register');
    }
    if (_studentName == null) {
      _studentName = prefs.getString('student_name');
    }
    
    final careerJson = prefs.getString('selected_career');
    if (careerJson != null && _selectedCareer == null) {
      try {
        _selectedCareer = Career.fromJson(jsonDecode(careerJson));
      } catch (_) {}
    }
    _isBlocked = prefs.getBool('is_blocked') ?? false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_studentRegister != null) {
      await prefs.setString('student_register', _studentRegister!);
    } else {
      await prefs.remove('student_register');
    }

    if (_studentName != null) {
      await prefs.setString('student_name', _studentName!);
    } else {
      await prefs.remove('student_name');
    }

    if (_selectedCareer != null) {
      final careerMap = {
        'codigo': _selectedCareer!.code,
        'nombre': _selectedCareer!.name,
        'facultad': _selectedCareer!.faculty,
        'duracionSemestres': _selectedCareer!.durationSemesters,
        'planCode': _selectedCareer!.planCode,
      };
      await prefs.setString('selected_career', jsonEncode(careerMap));
    } else {
      await prefs.remove('selected_career');
    }
    await prefs.setBool('is_blocked', _isBlocked);
  }

  void selectCareer(Career career, {String? registro}) {
    _selectedCareer = career;
    if (registro != null) {
      _studentRegister = registro;
    }
    _saveToPrefs();
    notifyListeners();
  }

  void selectSemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
  }

  void setStudentRegister(String register, {String? name, bool? isBlocked}) {
    _studentRegister = register;
    if (name != null) {
      _studentName = name;
    }
    if (isBlocked != null) {
      _isBlocked = isBlocked;
    }
    _saveToPrefs();
    notifyListeners();
  }

  void setBlocked(bool value) {
    _isBlocked = value;
    _saveToPrefs();
    notifyListeners();
  }

  void clearSelection() {
    _selectedCareer = null;
    _selectedSemester = null;
    _studentRegister = null;
    _studentName = null;
    _saveToPrefs();
    notifyListeners();
  }
}
