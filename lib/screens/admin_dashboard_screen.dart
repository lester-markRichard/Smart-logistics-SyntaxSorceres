import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/logistics_models.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Vehicle? _selectedVehicle;

  // Shared demo coordinates mirroring the driver's map (Mumbai → Pune)
  static const LatLng _originLatLng = LatLng(19.076, 72.877);
  static const LatLng _destLatLng = LatLng(18.520, 73.856);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicles = Provider.of<AppStateProvider>(context, listen: false).vehicles;
      if (vehicles.isNotEmpty) {
        setState(() {
          _selectedVehicle = vehicles.first;
        });
      }
    });
  }

  void _handleLogout(BuildContext context) {
    Provider.of<AppStateProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final vehicles = provider.vehicles;

          return Column(
            children: [
              if (provider.delayDuration != null) const AdminTruckMonitorCard(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side: Master Detail Panel (70%)
                    Expanded(
                      flex: 7,
                      child: _selectedVehicle == null
                          ? const Center(child: Text('No asset selected.', style: TextStyle(color: Colors.white54)))
                          : _buildDetailPanel(context, _selectedVehicle!),
                    ),

                    VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),

                    // Right Side: Active Asset Cards (30%)
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ACTIVE ASSETS (${vehicles.length})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: Theme.of(context).colorScheme.primary,
                                    tooltip: 'Add New Asset',
                                    onPressed: () => Navigator.pushNamed(context, '/add_vehicle'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                itemCount: vehicles.length,
                                itemBuilder: (context, index) {
                                  final vehicle = vehicles[index];
                                  final isSelected = vehicle.id == _selectedVehicle?.id;
                                  return _buildAssetCard(context, vehicle, isSelected);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
          ),
          title: Row(
            children: [
              Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Vehicle Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: const Text('Asset Number', style: TextStyle(color: Colors.white54, fontSize: 12)), subtitle: Text(vehicle.number, style: const TextStyle(color: Colors.white, fontSize: 18))),
              ListTile(title: const Text('Type', style: TextStyle(color: Colors.white54, fontSize: 12)), subtitle: Text(vehicle.type.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 18))),
              ListTile(title: const Text('Age', style: TextStyle(color: Colors.white54, fontSize: 12)), subtitle: Text('${vehicle.age} Years', style: const TextStyle(color: Colors.white, fontSize: 18))),
              ListTile(title: const Text('Capacity', style: TextStyle(color: Colors.white54, fontSize: 12)), subtitle: Text('${vehicle.capacity} Tonnes', style: const TextStyle(color: Colors.white, fontSize: 18))),
              ListTile(title: const Text('Fuel Type', style: TextStyle(color: Colors.white54, fontSize: 12)), subtitle: Text(vehicle.fuelType, style: const TextStyle(color: Colors.white, fontSize: 18))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetCard(BuildContext context, Vehicle vehicle, bool isSelected) {
    return Card(
      elevation: isSelected ? 4 : 0,
      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedVehicle = vehicle),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  vehicle.type == VehicleType.truck ? Icons.local_shipping : Icons.directions_boat,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '${vehicle.capacity.toStringAsFixed(0)}T • ${vehicle.fuelType}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                onSelected: (value) {
                  if (value == 'history') {
                    Navigator.pushNamed(context, '/view_history', arguments: vehicle.id);
                  } else if (value == 'details') {
                    _showVehicleDetails(context, vehicle);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'details', child: Text('View Details')),
                  const PopupMenuItem(value: 'history', child: Text('View History')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, Vehicle vehicle) {
    return Consumer<AppStateProvider>(
      builder: (context, provider, child) {
        // Find active or most recent planned trip for this vehicle
        Trip? trip;
        try {
          trip = provider.trips.lastWhere(
            (t) => t.vehicleId == vehicle.id && (t.status == 'active' || t.status == 'planned'),
          );
        } catch (_) {}

        // Prefer AI insights from trip, fallback to vehicle-level defaults
        final prediction = (trip?.prediction.isNotEmpty == true) ? trip!.prediction : vehicle.currentPrediction;
        final strategy = (trip?.strategy.isNotEmpty == true) ? trip!.strategy : vehicle.currentStrategy;
        final bool isActive = trip?.status == 'active';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.number,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatusBadge(vehicle.status),
                          const SizedBox(width: 16),
                          Text(
                            '${vehicle.type.name.toUpperCase()} • ${vehicle.age} YRS OLD • CAP: ${vehicle.capacity}T • FUEL: ${vehicle.fuelType.toUpperCase()}',
                            style: const TextStyle(color: Colors.white54, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Live velocity badge when a trip is active
                  if (isActive && trip != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${trip.liveVelocity.toStringAsFixed(0)} km/h  •  ETA: ${trip.eta}',
                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 48),

              // AI Prediction & Strategy
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      title: 'PREDICTION',
                      icon: Icons.warning_amber_rounded,
                      content: prediction,
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildInsightCard(
                      context,
                      title: 'STRATEGY RECOMMENDED',
                      icon: Icons.auto_awesome,
                      content: strategy,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Map section label
              Text(
                isActive ? 'LIVE TRIP MAP (MIRRORING DRIVER)' : 'ACTIVE TRIP ROUTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isActive ? Colors.greenAccent : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Google Map — live mirror when active, placeholder when idle
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 340,
                  child: isActive
                      ? GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(19.0, 73.2),
                            zoom: 8.5,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('truck'),
                              position: _originLatLng,
                              infoWindow: InfoWindow(title: vehicle.number),
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
                              color: Color(0xFF10B981), // Emerald green — distinct from driver view
                              width: 5,
                              points: [_originLatLng, _destLatLng],
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context).colorScheme.surface.withOpacity(0.5),
                                Theme.of(context).colorScheme.surface,
                              ],
                              radius: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map_outlined, size: 56,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Live map mirrors the driver when a trip is active.',
                                  style: TextStyle(color: Colors.white38, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(BuildContext context, {required String title, required IconData icon, required String content, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            content.isEmpty ? 'No data yet. Start a trip to generate AI insights.' : content,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(VehicleStatus status) {
    Color badgeColor;
    String label = status.name.toUpperCase();

    switch (status) {
      case VehicleStatus.active:
        badgeColor = const Color(0xFF10B981);
        break;
      case VehicleStatus.delayed:
        badgeColor = const Color(0xFFEF4444);
        break;
      case VehicleStatus.docked:
      case VehicleStatus.maintenance:
        badgeColor = const Color(0xFFF59E0B);
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class AdminTruckMonitorCard extends StatelessWidget {
  const AdminTruckMonitorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, prov, _) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.redAccent, size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 TRUCK ${prov.currentTruckId} DELAYED: ${prov.delayDuration} - ${prov.delayReason}',
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System auto-reassigned to ${prov.assignedSlot}.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => prov.clearDelay(),
                child: const Text('RESOLVE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}
