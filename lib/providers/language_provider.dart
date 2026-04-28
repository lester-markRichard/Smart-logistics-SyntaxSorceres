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
    'plan_trip_title': {
      'en': 'Plan a Trip',
      'hi': 'यात्रा की योजना बनाएं',
    },
    'plan_trip_sub': {
      'en': 'AI-assisted route strategy and scheduling.',
      'hi': 'AI-सहायता प्राप्त मार्ग रणनीति और शेड्यूलिंग।',
    },
    'start_now_title': {
      'en': 'Start Now',
      'hi': 'अभी शुरू करें',
    },
    'start_now_sub': {
      'en': 'Jump into your active trip navigation.',
      'hi': 'अपनी सक्रिय यात्रा नेविगेशन में जाएं।',
    },
    'book_slot_title': {
      'en': 'Book Slot',
      'hi': 'स्लॉट बुक करें',
    },
    'book_slot_sub': {
      'en': 'Reserve warehouse unloading or parking slots.',
      'hi': 'गोदाम अनलोडिंग या पार्किंग स्लॉट आरक्षित करें।',
    },
    'trip_details': {
      'en': 'TRIP DETAILS',
      'hi': 'यात्रा विवरण',
    },
    'date_label': {
      'en': 'Date (e.g., 2026-05-12)',
      'hi': 'दिनांक (उदा., 2026-05-12)',
    },
    'arrival_time_label': {
      'en': 'Desired Arrival Time (e.g., 14:00)',
      'hi': 'वांछित आगमन समय (उदा., 14:00)',
    },
    'start_location': {
      'en': 'Start Location',
      'hi': 'प्रारंभ स्थान',
    },
    'end_location': {
      'en': 'End Location',
      'hi': 'अंतिम स्थान',
    },
    'generate_strategy': {
      'en': 'Generate Strategy',
      'hi': 'रणनीति उत्पन्न करें',
    },
    'smart_warehouse': {
      'en': 'Smart Warehouse',
      'hi': 'स्मार्ट वेयरहाउस',
    },
    'total_slots': {
      'en': 'Total Slots',
      'hi': 'कुल स्लॉट',
    },
    'available_slots': {
      'en': 'Available Slots',
      'hi': 'उपलब्ध स्लॉट',
    },
    'booked_slots': {
      'en': 'Booked Slots',
      'hi': 'बुक किए गए स्लॉट',
    },
    'active_queue': {
      'en': 'Active Queue',
      'hi': 'सक्रिय कतार',
    },
    'truck_id': {
      'en': 'Truck ID',
      'hi': 'ट्रक आईडी',
    },
    'slot_number': {
      'en': 'Slot Number',
      'hi': 'स्लॉट नंबर',
    },
    'eta': {
      'en': 'ETA',
      'hi': 'आगमन का अनुमानित समय',
    },
    'loading': {
      'en': 'Loading',
      'hi': 'लोड हो रहा है',
    },
    'unloading': {
      'en': 'Unloading',
      'hi': 'अनलोड हो रहा है',
    },
  };

  String translate(String key) {
    final langKey = isHindi ? 'hi' : 'en';
    return _dictionary[key]?[langKey] ?? key;
  }
}
