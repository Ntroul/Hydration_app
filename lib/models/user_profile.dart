import 'package:flutter/material.dart';

class UserProfile extends ChangeNotifier {
  String _name        = '';
  int    _age         = 0;
  double _weightKg    = 0;
  bool   _onboarded   = false;

  String get name      => _name;
  int    get age       => _age;
  double get weightKg  => _weightKg;
  bool   get onboarded => _onboarded;

  double get dailyGoalMl {
    if (_weightKg == 0) return 2500;
    return ((_weightKg * 33 + 350 + 200) / 100).round() * 100;
  }

  void completeOnboarding({
    required String name,
    required int    age,
    required double weightKg,
  }) {
    _name      = name;
    _age       = age;
    _weightKg  = weightKg;
    _onboarded = true;
    notifyListeners();
  }

  void skipOnboarding() {
    _onboarded = true;
    notifyListeners();
  }

  void updateName(String v)     { _name     = v; notifyListeners(); }
  void updateAge(int v)         { _age      = v; notifyListeners(); }
  void updateWeight(double v)   { _weightKg = v; notifyListeners(); }
}