import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/language_provider.dart';
import '../models/logistics_models.dart';
import '../services/gemini_service.dart';

const List<LatLng> _kRoute = [
  LatLng(19.076, 72.877), LatLng(19.065, 72.881), LatLng(19.050, 72.873),
  LatLng(19.030, 72.876), LatLng(19.010, 72.902), LatLng(18.998, 72.962),
  LatLng(18.990, 73.022), LatLng(18.975, 73.062), LatLng(18.960, 73.102),
  LatLng(18.920, 73.152), LatLng(18.870, 73.202), LatLng(18.820, 73.272),
  LatLng(18.787, 73.343), LatLng(18.770, 73.362), LatLng(18.755, 73.400),
  LatLng(18.748, 73.430), LatLng(18.738, 73.482), LatLng(18.728, 73.532),
  LatLng(18.715, 73.582), LatLng(18.700, 73.630), LatLng(18.680, 73.682),
  LatLng(18.652, 73.720), LatLng(18.627, 73.792), LatLng(18.600, 73.812),
  LatLng(18.578, 73.826), LatLng(18.558, 73.841), LatLng(18.540, 73.851),
  LatLng(18.528, 73.854), LatLng(18.520, 73.856),
];

const List<LatLng> _kReroute = [
  LatLng(18.738, 73.482), LatLng(18.718, 73.512), LatLng(18.700, 73.558),
  LatLng(18.682, 73.605), LatLng(18.658, 73.652), LatLng(18.633, 73.712),
  LatLng(18.608, 73.758), LatLng(18.578, 73.810), LatLng(18.548, 73.838),
  LatLng(18.520, 73.856),
];

const List<Map<String, dynamic>> _kHud = [
  {'from': 0.00, 'text': 'Merge onto Mumbai-Pune Expressway (NH48)',       'icon': Icons.merge_type},
  {'from': 0.15, 'text': 'In 300m — take flyover towards Khopoli',         'icon': Icons.turn_slight_left},
  {'from': 0.28, 'text': '⚠️ Slowing — severe weather detected ahead',     'icon': Icons.warning_amber_rounded},
  {'from': 0.42, 'text': 'Continue straight for 45 km on Expressway',      'icon': Icons.straight},
  {'from': 0.51, 'text': '🔄 Alternate route via Urse bypass — 8 km saved','icon': Icons.alt_route},
  {'from': 0.72, 'text': 'In 2 km — exit towards Pimpri-Chinchwad',        'icon': Icons.turn_right},
  {'from': 0.88, 'text': 'Arriving at destination — Pune',                 'icon': Icons.flag},
];

class LiveTripScreen extends StatefulWidget {
  const LiveTripScreen({super.key});
  @override
  State<LiveTripScreen> createState() => _LiveTripScreenState();
}

class _LiveTripScreenState extends State<LiveTripScreen> {
  // ── Quick-start ───────────────────────────────────────────────────────────
  bool _needsDestination = false;
  final _destCtrl = TextEditingController();
  bool _qlLoading = false;
  final _delayReasonCtrl = TextEditingController();

  // ── Phase 30: Queue Timer ──────────────────────────────────────────────────
  Timer? _queueTimer;
  int _waitTimeMins = 45;
  bool _isSlotAvailable = false;

  // ── Map & simulation ──────────────────────────────────────────────────────
  GoogleMapController? _mapCtrl;
  Timer? _timer;
  int _step = 0;
  final _rng = Random();

  // ── Reactive state (rebuilt every tick inside setState) ───────────────────
  Set<Marker>   _markers   = {};
  Set<Polyline> _polylines = {};
  double   _velocity   = 62.0;
  String   _hudText    = _kHud[0]['text'] as String;
  IconData _hudIcon    = _kHud[0]['icon'] as IconData;
  bool _riskShown     = false;
  bool _rerouteShown  = false;
  bool _rerouteActive = false;
  
  // ── Phase 44: Two-Panel AI UI & Pre-Cognitive Reroute ───────────────────
  String currentPrediction = "Monitoring route conditions...";
  String currentStrategy = "Awaiting initial telemetry...";
  bool _weatherCleared = false;
  bool _preRerouteTriggered = false;

  // Micro-steps (lerped points) + ETA state
  late List<LatLng> _micro;
  String _eta = '2h 35m';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _micro = _generateMicroSteps();
    _rebuildMapObjects(0);
    _startQueueTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTrip());
  }

  void _startQueueTimer() {
    _queueTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_waitTimeMins > 0) {
        setState(() {
          _waitTimeMins--;
        });
      } else {
        setState(() {
          _isSlotAvailable = true;
        });
        timer.cancel();
      }
    });
  }

  // ── Generate 200 lerped micro-steps from the 29 sparse waypoints ────────
  List<LatLng> _generateMicroSteps() {
    const stepsPerSegment = 8; // 28 segments × 8 = 224 micro-steps
    final out = <LatLng>[];
    for (int i = 0; i < _kRoute.length - 1; i++) {
      final a = _kRoute[i];
      final b = _kRoute[i + 1];
      for (int j = 0; j < stepsPerSegment; j++) {
        final t = j / stepsPerSegment;
        out.add(LatLng(a.latitude + (b.latitude - a.latitude) * t,
                       a.longitude + (b.longitude - a.longitude) * t));
      }
    }
    out.add(_kRoute.last);
    return out; // ~225 points
  }



  @override
  void dispose() {
    _timer?.cancel();
    _queueTimer?.cancel();
    _destCtrl.dispose();
    _delayReasonCtrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ── Trip init ─────────────────────────────────────────────────────────────

  void _initTrip() {
    final prov = Provider.of<AppStateProvider>(context, listen: false);
    final user = prov.currentUser;
    if (user == null) return;

    final vehicle = prov.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user.truckNumber, orElse: () => null);
    if (vehicle == null) return;

    Trip? active;
    try { active = prov.trips.lastWhere((t) => t.vehicleId == vehicle.id && t.status == 'active'); } catch (_) {}
    if (active != null) return; // timer starts in onMapCreated

    Trip? planned;
    try { planned = prov.trips.lastWhere((t) => t.vehicleId == vehicle.id && t.status == 'planned'); } catch (_) {}
    if (planned != null) { prov.startTrip(planned.id); return; }

    setState(() => _needsDestination = true);
  }

  // ── Map created — START TIMER HERE (controller guaranteed non-null) ────────

  void _onMapCreated(GoogleMapController c) {
    _mapCtrl = c;
    // Small delay so the map tiles load before we start driving
    Future.delayed(const Duration(milliseconds: 600), _startTimer);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 350), _tick);
  }

  // ── The tick — every 350ms across ~225 micro-steps (~79s total) ──────────

  void _tick(Timer timer) {
    if (!mounted) { timer.cancel(); return; }

    final total = _micro.length - 1;
    if (_step >= total) { timer.cancel(); return; }

    final nextStep = _step + 1;
    final progress = nextStep / total;

    // 1. Velocity — slow in risk zone (30-50%)
    final double vel = (progress >= 0.28 && progress <= 0.50)
        ? 30 + _rng.nextDouble() * 10
        : 55 + _rng.nextDouble() * 15;

    // 2. HUD
    final hud = _kHud.lastWhere((e) => progress >= (e['from'] as double));

    // 3. Reroute flag at exactly 50% (micro-step 112)
    if (progress >= 0.50 && !_rerouteShown) _rerouteActive = true;

    // 4. Rebuild map objects (new Set instances → Flutter detects change)
    _rebuildMapObjects(nextStep);

    // 5. ETA: remaining % of 155-min total trip, decreasing realistically
    final remainingMins = ((1.0 - progress) * 155).round().clamp(0, 999);
    final String eta;
    if (remainingMins <= 2) {
      eta = 'Arriving soon';
    } else if (remainingMins < 60) {
      eta = '${remainingMins}m';
    } else {
      final h = remainingMins ~/ 60;
      final m = remainingMins % 60;
      eta = '${h}h ${m.toString().padLeft(2, '0')}m';
    }

    // 6. setState — FORCE RENDER
    setState(() {
      _step      = nextStep;
      _velocity  = vel;
      _hudText   = hud['text'] as String;
      _hudIcon   = hud['icon'] as IconData;
      _eta       = eta;
    });

    // 6. Camera pan AFTER setState
    _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _micro[nextStep], zoom: 12.5, tilt: 45,
          bearing: _microBearing(nextStep)),
    ));

    // 7. Scripted snackbars and Mocked Strategy
    if (progress >= 0.30 && !_riskShown) {
      _riskShown = true;
      setState(() {
        currentPrediction = "Telemetry indicates a severe localized storm front 15km ahead on NH48. High probability of surface flooding and reduced visibility. Current trajectory intersects the high-risk zone in approximately 12 minutes.";
        currentStrategy = "Initiating immediate velocity reduction protocol. Decrease speed by 23 km/h to maintain optimal tire traction and increase following distance. Continue monitoring for potential reroute triggers.";
      });
      _showSnack('⚠️ RISK DETECTED: Severe Weather Ahead. Reducing speed.',
          Colors.orangeAccent, Colors.black);
    }
    // Pre-Cognitive Reroute: triggers at 0.47 (slightly BEFORE map reroute at 0.50)
    if (progress >= 0.47 && !_preRerouteTriggered) {
      _preRerouteTriggered = true;
      setState(() {
        currentPrediction = "Critical incident detected: Major multi-vehicle collision reported near Lonavala ghat section. Traffic velocity has dropped to 0 km/h. Estimated clearance time exceeds 3 hours, causing a complete gridlock on the primary route.";
        currentStrategy = "Calculated optimal alternative: Diverting to the Old Mumbai-Pune Highway. This will add approximately 45 minutes to the ETA but guarantees continuous movement. Standby for updated navigation coordinates.";
      });
    }
    if (progress >= 0.50 && !_rerouteShown) {
      _rerouteShown = true;
      _showSnack('🔄 REROUTING: Faster alternate highway found — saving 8 km.',
          Colors.deepOrange, Colors.white);
    }
    if (progress >= 0.65 && !_weatherCleared) {
      _weatherCleared = true;
      setState(() {
        currentPrediction = "Vehicle has successfully bypassed the congested zone. Current route parameters are nominal. Weather conditions have stabilized with optimal visibility and dry road surfaces for the remainder of the journey.";
        currentStrategy = "Restore standard operating velocity. Resume standard power consumption profile. Recalculating final arrival time for Distribution Centre 3. Proceed with standard logistics protocols.";
      });
    }
  }

  // ── Rebuild markers + polylines as new Set objects each tick ──────────────

  void _rebuildMapObjects(int step) {
    final s = step.clamp(0, _micro.length - 1);
    final truckPos = _micro[s];
    final bearing  = _microBearing(s);
    // Always use hueAzure — reliable on Flutter Web without asset files
    const truckIcon = BitmapDescriptor.defaultMarker;

    _markers = {
      // Static pin 1 — Origin (green), never moves
      Marker(
        markerId: const MarkerId('origin'),
        position: _kRoute.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Origin — Mumbai'),
      ),
      // Static pin 2 — Destination (red), never moves
      Marker(
        markerId: const MarkerId('dest'),
        position: _kRoute.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination — Pune'),
      ),
      // Moving pin 3 — Live truck with emoji icon + rotation
      Marker(
        markerId: const MarkerId('live_truck'),
        position: truckPos,
        rotation: bearing,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: '🚛 Live Truck'),
      ),
    };

    final travelled = _micro.sublist(0, s + 1);
    final remaining = _micro.sublist(s);

    _polylines = {
      Polyline(polylineId: const PolylineId('done'),
          color: Colors.white38, width: 4, points: travelled),
      if (!_rerouteActive)
        Polyline(polylineId: const PolylineId('ahead'),
            color: const Color(0xFF38BDF8), width: 6, points: remaining),
      if (_rerouteActive)
        Polyline(
          polylineId: const PolylineId('reroute'),
          color: Colors.deepOrange, // vivid orange — clearly distinct
          width: 7,
          points: _kReroute,
          patterns: [PatternItem.dash(24), PatternItem.gap(10)],
        ),
    };
  }

  // Bearing computed against the micro-step list
  double _microBearing(int step) {
    if (step <= 0 || step >= _micro.length - 1) return 0;
    final a = _micro[step - 1];
    final b = _micro[step];
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final y = sin(dLng) * cos(b.latitude * pi / 180);
    final x = cos(a.latitude * pi / 180) * sin(b.latitude * pi / 180) -
              sin(a.latitude * pi / 180) * cos(b.latitude * pi / 180) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  double _bearing(int step) {
    if (step >= _kRoute.length - 1) return 0;
    final a = _kRoute[step - 1 < 0 ? 0 : step - 1];
    final b = _kRoute[step];
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final y = sin(dLng) * cos(b.latitude * pi / 180);
    final x = cos(a.latitude * pi / 180) * sin(b.latitude * pi / 180) -
              sin(a.latitude * pi / 180) * cos(b.latitude * pi / 180) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  void _showSnack(String msg, Color bg, Color fg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: TextStyle(color: fg, fontWeight: FontWeight.bold)),
        backgroundColor: bg,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
      ));
    });
  }

  // ── Quick start ───────────────────────────────────────────────────────────

  Future<void> _quickStart() async {
    if (_destCtrl.text.trim().isEmpty) return;
    setState(() => _qlLoading = true);
    final prov = Provider.of<AppStateProvider>(context, listen: false);
    final user = prov.currentUser;
    final vehicle = prov.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user?.truckNumber, orElse: () => null);
    final result = await GeminiService.generatePredictionAndStrategy(
      source: 'Current Location', destination: _destCtrl.text.trim(),
      truck: vehicle ?? Vehicle(id: 'mock', number: 'UNKNOWN', type: VehicleType.truck,
          fuelType: 'Diesel', age: 3, capacity: 20, status: VehicleStatus.active,
          currentPrediction: '', currentStrategy: ''),
    );
    final trip = Trip(
      id: 't_qs_${DateTime.now().millisecondsSinceEpoch}',
      vehicleId: vehicle?.id ?? '', startLocation: 'Current Location',
      endLocation: _destCtrl.text.trim(), startTime: DateTime.now(), status: 'planned',
      prediction: result['prediction'] ?? '', strategy: result['strategy'] ?? '',
    );
    prov.addTrip(trip);
    if (vehicle != null) prov.updateVehiclePrediction(vehicle.id, result['prediction'] ?? '', result['strategy'] ?? '');
    prov.startTrip(trip.id);
    setState(() { _needsDestination = false; _qlLoading = false; });
  }

  void _finishTrip() {
    _timer?.cancel();
    final prov = Provider.of<AppStateProvider>(context, listen: false);
    final user = prov.currentUser;
    if (user == null) return;
    final vehicle = prov.vehicles.cast<Vehicle?>().firstWhere(
        (v) => v?.number == user.truckNumber, orElse: () => null);
    if (vehicle == null) return;
    for (final t in prov.trips.where((t) => t.vehicleId == vehicle.id && t.status == 'active').toList()) {
      prov.updateTripStatus(t.id, 'completed');
    }
    Navigator.pushReplacementNamed(context, '/trip_completed');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_needsDestination) return _buildQuickStart();
    return Consumer<AppStateProvider>(builder: (ctx, prov, _) {
      final langProvider = Provider.of<LanguageProvider>(ctx);
      final user = prov.currentUser;
      Trip? trip;
      Vehicle? vehicle;
      if (user?.truckNumber != null) {
        vehicle = prov.vehicles.cast<Vehicle?>().firstWhere(
            (v) => v?.number == user!.truckNumber, orElse: () => null);
        if (vehicle != null) {
          try { trip = prov.trips.lastWhere((t) => t.vehicleId == vehicle!.id && t.status == 'active'); } catch (_) {}
        }
      }
      final origin = trip?.startLocation ?? 'Mumbai';
      final destination = trip?.endLocation ?? 'Pune';
      final etaDisplay = _eta;
      final aiAlert = trip?.strategy.isNotEmpty == true ? trip!.strategy : 'Monitoring route conditions...';
      final progress = (_step / (_micro.length - 1)).clamp(0.0, 1.0);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surface, elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
              tooltip: 'Report Delay',
              onPressed: () => _showDelaySheet(context),
            ),
            IconButton(icon: const Icon(Icons.close),
                onPressed: () => Navigator.pushReplacementNamed(context, '/driver_dashboard'))
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(children: [
                // 📍 PHASE 30: Live Queue Status Card (Glassmorphism)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _isSlotAvailable 
                        ? Colors.greenAccent.withOpacity(0.1) 
                        : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: _isSlotAvailable 
                          ? Colors.greenAccent.withOpacity(0.5) 
                          : Colors.white10
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _isSlotAvailable 
                              ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24)
                              : const _PulsingDot(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isSlotAvailable 
                                      ? '✅ ${langProvider.translate('status')}: ${prov.assignedSlot} Available' 
                                      : '📍 Live Status: 3rd in line at Distribution Centre 3, ${prov.assignedSlot}',
                                  style: TextStyle(
                                    color: _isSlotAvailable ? Colors.greenAccent : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (_waitTimeMins > 0)
                                  Text(
                                    '${langProvider.translate('est_wait')}: $_waitTimeMins mins',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 13,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Route banner
                _banner(context, origin, destination),
                const SizedBox(height: 10),
                // Telemetry
                _telemetry(context, etaDisplay, progress),
                const SizedBox(height: 10),
                // Map + HUD
                Expanded(flex: 3, child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(target: LatLng(19.0, 73.2), zoom: 9),
                      onMapCreated: _onMapCreated,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      
                    ),
                  ),
                  Positioned(top: 14, left: 14, right: 14, child: _hud(context, progress)),
                  Positioned(bottom: 0, left: 0, right: 0, child: _progressBar(progress)),
                ])),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Two-Panel AI Copilot
                        _aiPanels(currentPrediction, currentStrategy),
                        const SizedBox(height: 10),
                        // 🚨 PHASE 33: Massive Delay Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showRescheduleSheet(context),
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: Text('🚨 ${langProvider.translate('report_delay')}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Finish
                        SizedBox(width: double.infinity, child: ElevatedButton.icon(
                          onPressed: _finishTrip,
                          icon: const Icon(Icons.flag), label: Text(langProvider.translate('complete_trip')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _banner(BuildContext ctx, String origin, String dest) {
    final c = Theme.of(ctx).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.directions, color: c),
        const SizedBox(width: 12),
        Expanded(child: Text('$origin  ➔  $dest',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent)),
          child: const Text('ON ROUTE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _telemetry(BuildContext ctx, String eta, double progress) {
    final velColor = _velocity < 40 ? Colors.orangeAccent : Colors.white;
    return Row(children: [
      Expanded(child: _tel(ctx, 'Live Velocity', '${_velocity.toStringAsFixed(0)} km/h', Icons.speed, color: velColor)),
      const SizedBox(width: 10),
      Expanded(child: _tel(ctx, 'ETA', eta, Icons.access_time)),
      const SizedBox(width: 10),
      Expanded(child: _tel(ctx, 'Progress', '${(progress * 100).toStringAsFixed(0)}%',
          Icons.route, color: Theme.of(ctx).colorScheme.secondary)),
    ]);
  }

  Widget _tel(BuildContext ctx, String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(color: Theme.of(ctx).cardColor, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Icon(icon, size: 24, color: color ?? Theme.of(ctx).colorScheme.secondary),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          Text(value, style: TextStyle(fontSize: 17, color: color ?? Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _hud(BuildContext ctx, double progress) {
    final isRisk    = _hudText.contains('⚠️');
    final isReroute = _hudText.contains('🔄');
    final bg = isRisk ? Colors.orange.withOpacity(0.93)
        : isReroute  ? const Color(0xFF10B981).withOpacity(0.93)
        : const Color(0xFF0F172A).withOpacity(0.90);
    final border = isRisk ? Colors.orangeAccent : isReroute ? Colors.greenAccent : Colors.white24;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Row(children: [
        Icon(_hudIcon, color: Colors.white, size: 26),
        const SizedBox(width: 12),
        Expanded(child: Text(_hudText,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        Text('${(progress * 207).toStringAsFixed(0)} km',
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _progressBar(double progress) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      child: LinearProgressIndicator(
        value: progress, minHeight: 6, backgroundColor: Colors.black45,
        valueColor: AlwaysStoppedAnimation<Color>(_rerouteActive ? const Color(0xFF10B981) : const Color(0xFF38BDF8)),
      ),
    );
  }

  Widget _aiPanels(String prediction, String strategy) {
    return Column(
      children: [
        // Panel 1: Prediction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orangeAccent),
                  SizedBox(width: 8),
                  Text('⚠️ AI PREDICTION / ANALYSIS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: 1.1)),
                ],
              ),
              const SizedBox(height: 6),
              Text(prediction, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Panel 2: Strategy
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text('💡 STRATEGY RECOMMENDED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.greenAccent, letterSpacing: 1.1)),
                ],
              ),
              const SizedBox(height: 6),
              Text(strategy, style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStart() {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surface, elevation: 0, automaticallyImplyLeading: false),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Card(color: Theme.of(context).cardColor, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(padding: const EdgeInsets.all(48), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.navigation, size: 60, color: Colors.blueAccent),
            const SizedBox(height: 22),
            const Text('WHERE ARE YOU HEADED?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            const Text('No planned trip found. Enter destination for Gemini AI strategy.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 36),
            TextField(controller: _destCtrl, style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'Destination', labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.location_on, color: Colors.white54), filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _qlLoading ? null : _quickStart,
              icon: _qlLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.bolt),
              label: Text(_qlLoading ? 'Generating Strategy...' : 'Start Now'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )),
          ])),
        ),
      )),
    );
  }

  // ── PHASE 28: Delay Bottom Sheet ──────────────────────────────────────────
  void _showDelaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                '⚠️ Delay Reporting Interface',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select duration or provide a custom reason.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: ['15 Min', '30 Min', '1 Hour'].map((label) {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSnack(
                        'Delay logged. Admin notified and slot dynamically rescheduled.',
                        const Color(0xFF10B981),
                        Colors.white,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Custom Delay Reason',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _delayReasonCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'E.g., Flat tire, heavy traffic...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_delayReasonCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      _showSnack(
                        'Delay logged. Admin notified and slot dynamically rescheduled.',
                        const Color(0xFF10B981),
                        Colors.white,
                      );
                      _delayReasonCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── PHASE 33: Reschedule Bottom Sheet ───────────────────────────────────────
  void _showRescheduleSheet(BuildContext context) {
    String selectedTime = "15 Min";
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_busy, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Report Transit Delay',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _delayReasonCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Custom Reason (e.g., Flat Tire, Traffic)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ["15 Min", "30 Min", "1 Hour", "Unknown"].map((time) {
                    final isSelected = selectedTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      onSelected: (val) => setSheetState(() => selectedTime = time),
                      selectedColor: Colors.redAccent,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                      backgroundColor: Colors.white.withOpacity(0.05),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final reason = _delayReasonCtrl.text.isEmpty ? "Unspecified Issue" : _delayReasonCtrl.text;
                      Provider.of<AppStateProvider>(context, listen: false).reportDelay(selectedTime, reason);
                      Navigator.pop(ctx);
                      _showSnack("Warehouse Notified. Slot Reassigned.", Colors.greenAccent, Colors.black);
                      _delayReasonCtrl.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Submit to Smart Warehouse', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── PHASE 28: Pulsing Dot Widget ─────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(_animation.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5),
                blurRadius: 10 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
