import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class SlotBookingScreen extends StatefulWidget {
  const SlotBookingScreen({super.key});

  @override
  State<SlotBookingScreen> createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends State<SlotBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFacility;
  String? _selectedSlotType;
  String? _selectedTimeSlot;

  final List<String> _facilities = ['Distribution Center B', 'Warehouse A', 'Port of Seattle'];
  final List<String> _slotTypes = ['Unloading', 'Parking'];
  final List<String> _timeSlots = [
    '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '13:00 PM', '14:00 PM', '15:00 PM', '16:00 PM'
  ];

  void _confirmBooking() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a time slot.')));
      return;
    }

    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final user = provider.currentUser;
    final truckNum = user?.truckNumber ?? 'Unknown Truck';

    // Mock slot id generation logic
    final generatedSlotId = _selectedSlotType == 'Unloading' ? 'Slot ${DateTime.now().second % 5 + 1}' : 'Parking A';

    // Parse mock datetime
    final parts = _selectedTimeSlot!.split(' ');
    int hour = int.parse(parts[0].split(':')[0]);
    if (parts[1] == 'PM' && hour != 12) hour += 12;
    
    final slotTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);

    final totalBookedForTime = provider.warehouseSlots.where((s) => 
      s.status == 'booked' && s.slotTime == slotTime).length;
      
    if (totalBookedForTime >= provider.totalWarehouseSlots) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Slot capacity reached for this time.')));
      return;
    }

    final newSlot = WarehouseSlot(
      id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
      facility: _selectedFacility!,
      slotTime: slotTime,
      truckNumber: truckNum,
      type: _selectedSlotType!.toLowerCase(),
      dockId: generatedSlotId,
      status: 'booked',
    );

    provider.addWarehouseSlot(newSlot);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot Booking Confirmed!')),
    );

    Navigator.pushReplacementNamed(context, '/driver_dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final List<String> currentFacilities = [];
    if (provider.warehouseName.isNotEmpty) {
      currentFacilities.add(provider.warehouseName);
    }
    currentFacilities.addAll(_facilities);
    final List<String> uniqueFacilities = currentFacilities.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Slot', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
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
                      const Text(
                        'FACILITY & SLOT DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedFacility,
                              hint: const Text('Select Facility', style: TextStyle(color: Colors.white54)),
                              items: uniqueFacilities.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                              onChanged: (v) => setState(() => _selectedFacility = v),
                              validator: (v) => v == null ? 'Required' : null,
                              decoration: _inputDecoration(Theme.of(context), Icons.business),
                              dropdownColor: Theme.of(context).cardColor,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSlotType,
                              hint: const Text('Slot Type', style: TextStyle(color: Colors.white54)),
                              items: _slotTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (v) => setState(() => _selectedSlotType = v),
                              validator: (v) => v == null ? 'Required' : null,
                              decoration: _inputDecoration(Theme.of(context), Icons.merge_type),
                              dropdownColor: Theme.of(context).cardColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      const Text(
                        'AVAILABLE TIME SLOTS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Consumer<AppStateProvider>(
                        builder: (context, provider, child) {
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _timeSlots.map((time) {
                              final parts = time.split(' ');
                              int hour = int.parse(parts[0].split(':')[0]);
                              if (parts[1] == 'PM' && hour != 12) hour += 12;
                              final slotTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, 0);
                              
                              final totalBookedForTime = provider.warehouseSlots.where((s) => 
                                s.status == 'booked' && s.slotTime == slotTime).length;
                              
                              final isFull = totalBookedForTime >= provider.totalWarehouseSlots;
                              final isSelected = _selectedTimeSlot == time;
                              
                              return ChoiceChip(
                                label: Text(isFull ? '$time (Full)' : time, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, decoration: isFull ? TextDecoration.lineThrough : null)),
                                selected: isSelected,
                                onSelected: isFull ? null : (selected) {
                                  if (selected) setState(() => _selectedTimeSlot = time);
                                },
                                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                                selectedColor: Colors.purpleAccent.withOpacity(0.2),
                                disabledColor: Colors.white10,
                                labelStyle: TextStyle(color: isFull ? Colors.white38 : (isSelected ? Colors.purpleAccent : Colors.white70)),
                                side: BorderSide(color: isFull ? Colors.transparent : (isSelected ? Colors.purpleAccent : Colors.white10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 64),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmBooking,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirm Booking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
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

  InputDecoration _inputDecoration(ThemeData theme, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }
}
