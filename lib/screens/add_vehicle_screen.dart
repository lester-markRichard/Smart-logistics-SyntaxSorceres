import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _ageController = TextEditingController();
  final _capacityController = TextEditingController();

  VehicleType? _selectedType;
  String? _selectedFuel;
  
  final List<String> _fuelTypes = ['Diesel', 'Electric', 'Hybrid', 'Heavy Fuel Oil'];

  void _saveVehicle(bool finish) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null || _selectedFuel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select all required dropdowns.')));
      return;
    }

    final newVehicle = Vehicle(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      number: _numberController.text.trim(),
      type: _selectedType!,
      fuelType: _selectedFuel!,
      age: double.tryParse(_ageController.text) ?? 0.0,
      capacity: double.tryParse(_capacityController.text) ?? 0.0,
      status: VehicleStatus.active,
      currentPrediction: 'No recent data. Awaiting first trip telemetry.',
      currentStrategy: 'Standard operating parameters active.',
    );

    Provider.of<AppStateProvider>(context, listen: false).addVehicle(newVehicle);
    
    if (finish) {
      Navigator.pushReplacementNamed(context, '/admin_dashboard');
    } else {
      _numberController.clear();
      _ageController.clear();
      _capacityController.clear();
      setState(() {
        _selectedType = null;
        _selectedFuel = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle saved. Add another.')));
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _ageController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fleet Asset', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false, // Force them to finish setup
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48.0),
            child: Card(
              color: Theme.of(context).cardColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 64, color: Colors.blueAccent),
                      const SizedBox(height: 24),
                      const Text(
                        'INITIALIZE FLEET DATABASE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your logistics network is currently empty. Please add your first physical asset to begin operations and activate the dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 64),
                      
                      // Row 1: Identification
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _numberController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(context, 'Asset Number / Callsign', Icons.tag),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: DropdownButtonFormField<VehicleType>(
                              isExpanded: true,
                              value: _selectedType,
                              hint: const Text('Asset Type', style: TextStyle(color: Colors.white54)),
                              items: const [
                                DropdownMenuItem(value: VehicleType.truck, child: Text('Truck')),
                                DropdownMenuItem(value: VehicleType.ship, child: Text('Cargo Ship')),
                              ],
                              onChanged: (v) => setState(() => _selectedType = v),
                              validator: (v) => v == null ? 'Required' : null,
                              decoration: _inputDecoration(context, null, Icons.directions_boat),
                              dropdownColor: Theme.of(context).cardColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Row 2: Specifications
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _selectedFuel,
                              hint: const Text('Fuel Class', style: TextStyle(color: Colors.white54)),
                              items: _fuelTypes.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                              onChanged: (v) => setState(() => _selectedFuel = v),
                              validator: (v) => v == null ? 'Required' : null,
                              decoration: _inputDecoration(context, null, Icons.local_gas_station),
                              dropdownColor: Theme.of(context).cardColor,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration(context, 'Age (Years)', Icons.access_time),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _capacityController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: _inputDecoration(context, 'Capacity (Tonnes)', Icons.fitness_center),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 64),

                      // Submit Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _saveVehicle(false),
                              icon: const Icon(Icons.add),
                              label: const Text('Save & Add Another'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueAccent,
                                side: const BorderSide(color: Colors.blueAccent),
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveVehicle(true),
                              icon: const Icon(Icons.check),
                              label: const Text('Save & Finish'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String? label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}
