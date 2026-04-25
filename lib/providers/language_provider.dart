import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  bool isHindi = false;

  void toggleLanguage() {
    isHindi = !isHindi;
    notifyListeners();
  }

  final Map<String, Map<String, String>> _dictionary = {
    'welcome_back': {
      'en': 'Welcome Back',
      'hi': 'वापसी पर स्वागत है',
    },
    'sign_in': {
      'en': 'SIGN IN',
      'hi': 'साइन इन करें',
    },
    'driver_dashboard': {
      'en': 'Driver Dashboard',
      'hi': 'ड्राइवर डैशबोर्ड',
    },
    'active_trips': {
      'en': 'Active Trips',
      'hi': 'सक्रिय यात्राएं',
    },
    'report_delay': {
      'en': 'Report Delay / Issue',
      'hi': 'देरी / समस्या की रिपोर्ट करें',
    },
    'complete_trip': {
      'en': 'Complete / Finish Trip',
      'hi': 'यात्रा पूरी करें',
    },
    'status': {
      'en': 'Status',
      'hi': 'स्थिति',
    },
    'est_wait': {
      'en': 'Est. Wait',
      'hi': 'अनुमानित प्रतीक्षा',
    },
  };

  String translate(String key) {
    final langKey = isHindi ? 'hi' : 'en';
    return _dictionary[key]?[langKey] ?? key;
  }
}
