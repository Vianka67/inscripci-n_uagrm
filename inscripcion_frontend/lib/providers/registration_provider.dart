import 'package:flutter/material.dart';
import 'package:inscripcion_frontend/models/career.dart';

class RegistrationProvider extends ChangeNotifier {
  Career? _selectedCareer;
  String? _selectedSemester;
  String? _studentRegister;

  Career? get selectedCareer => _selectedCareer;
  String? get selectedSemester => _selectedSemester;
  String? get studentRegister => _studentRegister;

  void selectCareer(Career career, {String? registro}) {
    _selectedCareer = career;
    if (registro != null) {
      _studentRegister = registro;
    }
    notifyListeners();
  }

  void selectSemester(String semester) {
    _selectedSemester = semester;
    notifyListeners();
  }

  void setStudentRegister(String register) {
    _studentRegister = register;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCareer = null;
    _selectedSemester = null;
    _studentRegister = null;
    notifyListeners();
  }
}
