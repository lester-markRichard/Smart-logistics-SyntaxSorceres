import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';
import '../services/sarvam_service.dart';
import '../providers/language_provider.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _startLocationController = TextEditingController();
  final _endLocationController = TextEditingController();
  final _timeController = TextEditingController();

  bool _strategyGenerated = false;
  bool _isLoading = false;

  // Stored AI results
  String _aiPrediction = '';
  String _aiStrategy = '';

  // Fixed demo coordinates (Mumbai → Pune)
  static const LatLng _originLatLng = LatLng(19.076, 72.877);
  static const LatLng _destLatLng = LatLng(18.520, 73.856);

  @override
  void dispose() {
    _dateController.dispose();
    _startLocationController.dispose();
    _endLocationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _generateStrategy() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final user = provider.currentUser;

    Vehicle? vehicle;
    if (user?.truckNumber != null) {
      vehicle = provider.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user!.truckNumber,
        orElse: () => null,
      );
    }
    vehicle ??= Vehicle(
      id: 'mock',
      number: user?.truckNumber ?? 'UNKNOWN',
      type: VehicleType.truck,
      fuelType: 'Diesel',
      age: 3,
      capacity: 20,
      status: VehicleStatus.active,
      currentPrediction: '',
      currentStrategy: '',
    );

    final result = await SarvamService.generatePredictionAndStrategy(
      source: _startLocationController.text.trim(),
      destination: _endLocationController.text.trim(),
      truck: vehicle,
    );

    setState(() {
      _isLoading = false;
      _strategyGenerated = true;
      _aiPrediction = result['prediction'] ?? '';
      _aiStrategy = result['strategy'] ?? '';
    });
  }

  void _confirmAndSaveTrip() {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final user = provider.currentUser;

    String vehicleId = '';
    if (user?.truckNumber != null) {
      final match = provider.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user!.truckNumber,
        orElse: () => null,
      );
      if (match != null) vehicleId = match.id;
    }

    final newTrip = Trip(
      id: 't_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: vehicleId,
      startLocation: _startLocationController.text.trim(),
      endLocation: _endLocationController.text.trim(),
      startTime: DateTime.now(),
      status: 'planned',
      prediction: _aiPrediction,
      strategy: _aiStrategy,
    );

    provider.addTrip(newTrip);

    if (vehicleId.isNotEmpty) {
      provider.updateVehiclePrediction(vehicleId, _aiPrediction, _aiStrategy);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip saved & AI insights synced!')),
    );

    Navigator.pushReplacementNamed(context, '/live_trip');
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(langProvider.translate('plan_trip_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input Form Card
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            langProvider.translate('trip_details'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_dateController, langProvider.translate('date_label'), Icons.date_range)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField(_timeController, langProvider.translate('arrival_time_label'), Icons.access_time)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTextField(_startLocationController, langProvider.translate('start_location'), Icons.my_location)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildTextField(_endLocationController, langProvider.translate('end_location'), Icons.location_on)),
                            ],
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading || _strategyGenerated ? null : _generateStrategy,
                              icon: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome),
                              label: Text(_isLoading
                                  ? 'Sarvam AI Analyzing Route...'
                                  : (_strategyGenerated ? '✓ Strategy Generated' : langProvider.translate('generate_strategy'))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Animated reveal of AI results + map
                if (_strategyGenerated) ...[
                  const SizedBox(height: 48),
                  // Google Map — constrained with explicit width+height
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(19.0, 73.2),
                        zoom: 8.5,
                      ),
                      markers: {
                        const Marker(
                          markerId: MarkerId('origin'),
                          position: _originLatLng,
                          infoWindow: InfoWindow(title: 'Origin'),
                        ),
                        const Marker(
                          markerId: MarkerId('destination'),
                          position: _destLatLng,
                          infoWindow: InfoWindow(title: 'Destination'),
                        ),
                      },
                      polylines: {
                        const Polyline(
                          polylineId: PolylineId('route'),
                          color: Color(0xFF38BDF8),
                          width: 5,
                          points: [_originLatLng, _destLatLng],
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // AI Prediction & Strategy Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildInsightCard(
                          title: 'PREDICTION',
                          icon: Icons.warning_amber_rounded,
                          content: _aiPrediction,
                          color: Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildInsightCard(
                          title: 'STRATEGY RECOMMENDED',
                          icon: Icons.lightbulb_outline,
                          content: _aiStrategy,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _confirmAndSaveTrip,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm & Save Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildInsightCard({required String title, required IconData icon, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            content.isEmpty ? 'Generating...' : content,
            style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
