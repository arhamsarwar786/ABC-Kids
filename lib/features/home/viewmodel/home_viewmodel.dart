import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  bool _isNavigating = false;

  bool get isNavigating => _isNavigating;

  Future<void> handleNavigation(VoidCallback navigateAction) async {
    if (_isNavigating) return;
    
    _isNavigating = true;
    notifyListeners();
    
    navigateAction();

    await Future.delayed(const Duration(milliseconds: 500));
    _isNavigating = false;
    notifyListeners();
  }
}
