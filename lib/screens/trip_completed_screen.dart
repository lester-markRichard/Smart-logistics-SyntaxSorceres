import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class TripCompletedScreen extends StatelessWidget {
  const TripCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final user = provider.currentUser;
    
    Trip? lastCompletedTrip;
    
    if (user != null && user.truckNumber != null) {
      final match = provider.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user.truckNumber, 
        orElse: () => null
      );
      if (match != null) {
        try {
          lastCompletedTrip = provider.trips.lastWhere(
            (t) => t.vehicleId == match.id && t.status == 'completed'
          );
        } catch (_) {}
      }
    }

    final origin = lastCompletedTrip?.startLocation ?? 'Origin';
    final destination = lastCompletedTrip?.endLocation ?? 'Destination';
    final score = lastCompletedTrip?.efficiencyScore ?? 94;

    // Calculate total time safely
    String totalTime = '3h 15m (Mock)';
    if (lastCompletedTrip?.startTime != null && lastCompletedTrip?.endTime != null) {
      final diff = lastCompletedTrip!.endTime!.difference(lastCompletedTrip.startTime!);
      if (diff.inMinutes > 0) {
        totalTime = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else {
        totalTime = '< 1m';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow back to live trip
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Celebration Header
                Icon(Icons.check_circle, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                const Text(
                  'TRIP COMPLETED SUCCESSFULLY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 64),

                // Middle: Stats Row
                Row(
                  children: [
                    // Trip Summary Card
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ROUTE SUMMARY', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 24),
                            _buildSummaryRow('Origin', origin),
                            _buildSummaryRow('Destination', destination),
                            const Divider(height: 32, color: Colors.white10),
                            _buildSummaryRow('Total Duration', totalTime),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Performance Score Card
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('EFFICIENCY SCORE', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 16),
                            Text(
                              '$score%',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Bottom: Stage-wise Breakdown
                const Text('STAGE-WISE BREAKDOWN', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineStage(Icons.my_location, 'Departed Origin', 'On-time departure verified.', isFirst: true),
                      _buildTimelineStage(Icons.thunderstorm, 'Navigated Weather Alert', 'Adjusted speed during localized heavy rain. Preserved efficiency.'),
                      _buildTimelineStage(Icons.warehouse, 'Arrived & Slotted', 'Successfully parked at destination gate.', isLast: true),
                    ],
                  ),
                ),
                const SizedBox(height: 64),

                // Return Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/driver_dashboard'),
                    icon: const Icon(Icons.home),
                    label: const Text('Return to Hub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white24)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTimelineStage(IconData icon, String title, String subtitle, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 16,
                color: isFirst ? Colors.transparent : Colors.white24,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.white70),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.white24,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
