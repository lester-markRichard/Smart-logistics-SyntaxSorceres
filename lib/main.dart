import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/app_state_provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/plan_trip_screen.dart';
import 'screens/live_trip_screen.dart';
import 'screens/trip_completed_screen.dart';
import 'screens/warehouse_dashboard_screen.dart';
import 'screens/view_history_screen.dart';
import 'screens/slot_booking_screen.dart';
import 'screens/add_vehicle_screen.dart';
import 'screens/warehouse_setup_screen.dart';

Future<void> main() async {
  // 1. THIS IS REQUIRED if you have 'await' before runApp!
  WidgetsFlutterBinding.ensureInitialized(); 

  await dotenv.load(fileName: 'config.env');
  
  // 2. The AI Test
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // Use 1.5-flash, gemini-pro is legacy and might throw errors!
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey); 
  final content = [Content.text('Write a short sentence about a magic truck.')];
  
  try {
    final response = await model.generateContent(content);
    print('🤖 AI TEST SUCCESS: ${response.text}');
  } catch (e) {
    print('❌ AI TEST FAILED: $e');
  }

  // 3. Start the actual app UI
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const LogisticsApp(),
    ),
  );
}


class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Logistics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/driver_dashboard': (context) => const DriverDashboardScreen(),
        '/plan_trip': (context) => const PlanTripScreen(),
        '/live_trip': (context) => const LiveTripScreen(),
        '/trip_completed': (context) => const TripCompletedScreen(),
        '/warehouse_dashboard': (context) => const WarehouseDashboardScreen(),
        '/view_history': (context) => const ViewHistoryScreen(),
        '/slot_booking': (context) => const SlotBookingScreen(),
        '/add_vehicle': (context) => const AddVehicleScreen(),
        '/warehouse_setup': (context) => const WarehouseSetupScreen(),
      },
    );
  }
}
