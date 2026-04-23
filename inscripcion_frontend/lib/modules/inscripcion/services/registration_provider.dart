import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inscripcion_frontend/modules/inscripcion/models/career.dart';

class RegistrationProvider extends ChangeNotifier {
  Career? _selectedCareer;
  String? _selectedSemester;
  String? _studentRegister;
  String? _studentName;

  RegistrationProvider() {
    _loadFromPrefs();
  }

  Career? get selectedCareer => _selectedCareer;
  String? get selectedSemester => _selectedSemester;
  String? get studentRegister => _studentRegister;
  String? get studentName => _studentName;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Solo cargamos si no se ha configurado en esta sesión para evitar sobrescritura.
    if (_studentRegister == null) {
      _studentRegister = prefs.getString('student_register');
    }
    _studentName = prefs.getString('student_name');
    
    final careerJson = prefs.getString('selected_career');
    if (careerJson != null && _selectedCareer == null) {
      try {
        _selectedCareer = Career.fromJson(jsonDecode(careerJson));
      } catch (_) {}
    }
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
      };
      await prefs.setString('selected_career', jsonEncode(careerMap));
    } else {
      await prefs.remove('selected_career');
    }
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

  void setStudentRegister(String register) {
    _studentRegister = register;
    _saveToPrefs();
    notifyListeners();
  }

  void setStudentData(String register, String name) {
    _studentRegister = register;
    _studentName = name;
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
