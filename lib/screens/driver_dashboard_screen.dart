import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  void _handleLogout(BuildContext context) {
    Provider.of<AppStateProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppStateProvider>(context).currentUser;
    final driverName = user?.name ?? 'Driver';
    final truckNumber = user?.truckNumber ?? 'Unknown Truck';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $driverName',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Driving: $truckNumber',
                    style: const TextStyle(fontSize: 18, color: Colors.white54, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 64),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Plan a Trip',
                          subtitle: 'AI-assisted route strategy and scheduling.',
                          icon: Icons.calendar_today_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: () => Navigator.pushNamed(context, '/plan_trip'),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Start Now',
                          subtitle: 'Jump into your active trip navigation.',
                          icon: Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => _startNow(context),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          title: 'Book Slot',
                          subtitle: 'Reserve warehouse unloading or parking slots.',
                          icon: Icons.warehouse_outlined,
                          color: Colors.purpleAccent,
                          onTap: () => Navigator.pushNamed(context, '/slot_booking'),
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
    );
  }

  /// Guards the "Start Now" flow. If no planned/active trip exists, shows a
  /// destination dialog before navigating so live_trip_screen always has data.
  Future<void> _startNow(BuildContext context) async {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final user = provider.currentUser;

    Vehicle? vehicle;
    if (user?.truckNumber != null) {
      vehicle = provider.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user!.truckNumber, orElse: () => null,
      );
    }

    // Check for any existing active or planned trip for this vehicle
    bool hasTripReady = false;
    if (vehicle != null) {
      hasTripReady = provider.trips.any(
        (t) => t.vehicleId == vehicle!.id &&
            (t.status == 'active' || t.status == 'planned'),
      );
    }

    if (hasTripReady) {
      // Trip exists — navigate directly; live_trip_screen handles activation
      Navigator.pushNamed(context, '/live_trip');
      return;
    }

    // No trip found — show destination dialog before navigating
    final destController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(ctx).colorScheme.primary.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Icon(Icons.navigation, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Where are you headed?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No planned trip found. Enter a destination and Gemini AI will '  
              'generate a live strategy when you start navigating.',
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: destController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Destination',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.white54),
                filled: true,
                fillColor: Theme.of(ctx).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.bolt),
            label: const Text('Start Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              foregroundColor: Theme.of(ctx).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (destController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Store the quick-start destination in a temporary planned trip so
    // live_trip_screen can pick it up and call GeminiService itself.
    if (vehicle != null) {
      final quickTrip = Trip(
        id: 't_dash_${DateTime.now().millisecondsSinceEpoch}',
        vehicleId: vehicle.id,
        startLocation: 'Current Location',
        endLocation: destController.text.trim(),
        startTime: DateTime.now(),
        status: 'planned',
      );
      provider.addTrip(quickTrip);
    }

    if (context.mounted) {
      Navigator.pushNamed(context, '/live_trip');
    }
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        hoverColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 64, color: color),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
