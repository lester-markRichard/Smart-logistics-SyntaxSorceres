import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'package:intl/intl.dart';

class WarehouseDashboardScreen extends StatelessWidget {
  const WarehouseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppStateProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final totalSlots = provider.totalWarehouseSlots;
          final activeBookings = provider.warehouseSlots.where((s) => s.status == 'booked').toList();
          final bookedSlots = activeBookings.length;
          final availableSlots = totalSlots - bookedSlots;

          return Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Row
                Row(
                  children: [
                    Expanded(child: _buildMetricCard(context, 'Total Slots', totalSlots.toString(), Icons.warehouse, Colors.blueAccent)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildMetricCard(context, 'Available Slots', availableSlots.toString(), Icons.check_circle_outline, Colors.greenAccent)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildMetricCard(context, 'Booked Slots', bookedSlots.toString(), Icons.local_shipping, Colors.purpleAccent)),
                  ],
                ),
                const SizedBox(height: 48),
                const Text(
                  'ACTIVE BOOKINGS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white54),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: activeBookings.isEmpty
                      ? Center(
                          child: Text('No active bookings at this time.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        )
                      : ListView.builder(
                          itemCount: activeBookings.length,
                          itemBuilder: (context, index) {
                            final slot = activeBookings[index];
                            return Card(
                              color: Theme.of(context).cardColor,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3))),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(24),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.local_shipping, color: Colors.purpleAccent),
                                ),
                                title: Text(slot.truckNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('Type: ${slot.type.toUpperCase()} • Slot: ${slot.dockId}', style: const TextStyle(color: Colors.white54)),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('SLOT TIME', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.0)),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(slot.slotTime),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
