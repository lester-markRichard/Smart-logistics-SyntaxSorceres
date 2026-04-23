import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class ViewHistoryScreen extends StatelessWidget {
  const ViewHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the passed vehicleId from arguments
    final vehicleId = ModalRoute.of(context)?.settings.arguments as String?;
    final provider = Provider.of<AppStateProvider>(context);
    
    final vehicle = provider.vehicles.cast<Vehicle?>().firstWhere(
      (v) => v?.id == vehicleId, 
      orElse: () => null
    );

    final completedTrips = provider.trips.where((t) => t.vehicleId == vehicleId && t.status == 'completed').toList();
    
    int totalTrips = completedTrips.length;
    double avgEfficiency = 0.0;
    if (totalTrips > 0) {
      avgEfficiency = completedTrips.map((t) => t.efficiencyScore).reduce((a, b) => a + b) / totalTrips;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics: ${vehicle?.number ?? "Unknown Asset"}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'TOTAL TRIPS TAKEN',
                        value: totalTrips.toString(),
                        icon: Icons.history,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        title: 'AVERAGE EFFICIENCY',
                        value: '${avgEfficiency.toStringAsFixed(1)}%',
                        icon: Icons.speed,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Middle Row: Route Intelligence
                const Text('ROUTE INTELLIGENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white54)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.whatshot, color: Colors.orangeAccent),
                                SizedBox(width: 12),
                                Text('HISTORICAL DELAY HOTSPOTS', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text('• Route A slows down significantly after 6 PM due to outbound commuter traffic.\n• Severe weather probability correlates with 14% efficiency drop on I-95.',
                              style: TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.alt_route, color: Theme.of(context).colorScheme.secondary),
                                const SizedBox(width: 12),
                                Text('BEST PATH SUCCESS RATE', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('• Primary AI strategy yields 92% on-time success rate.\n• Alternate Route B is longer but historically 40% more reliable during winter storms.',
                              style: TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Bottom List: Trip History
                const Text('TRIP HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white54)),
                const SizedBox(height: 24),
                if (completedTrips.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Center(
                      child: Text('No completed trips found for this asset.', style: TextStyle(color: Colors.white54)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: completedTrips.length,
                    itemBuilder: (context, index) {
                      final trip = completedTrips[index];
                      // Reverse list to show newest first
                      final actualIndex = completedTrips.length - 1 - index;
                      final t = completedTrips[actualIndex];
                      
                      return Card(
                        color: Theme.of(context).cardColor,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t.startLocation} ➔ ${t.endLocation}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Started: ${t.startTime != null ? t.startTime.toString().split('.')[0] : "Unknown"}',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                                ),
                                child: Text('Score: ${t.efficiencyScore}%', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
