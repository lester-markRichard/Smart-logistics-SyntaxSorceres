import 'dart:math';
import 'package:flutter/material.dart';
import '../models/logistics_models.dart';

class AppStateProvider with ChangeNotifier {
  AppUser? _currentUser;
  int _totalWarehouseSlots = 0;
  String _warehouseName = '';
  
  // ── Phase 33: Rescheduling Logic ──────────────────────────────────────────
  String? delayDuration;
  String? delayReason;
  String assignedSlot = "Slot 4";
  String currentTruckId = "TRK405";

  void reportDelay(String duration, String reason) {
    delayDuration = duration;
    delayReason = reason;
    assignedSlot = "Slot 12 (Late Arrival)";
    notifyListeners();
  }

  void clearDelay() {
    delayDuration = null;
    delayReason = null;
    assignedSlot = "Slot 4";
    notifyListeners();
  }
  
  // Mock Data
  final List<Vehicle> _vehicles = [];

  final List<Trip> _trips = [];

  final List<WarehouseSlot> _warehouseSlots = [];

  // Getters
  int get totalWarehouseSlots => _totalWarehouseSlots;
  String get warehouseName => _warehouseName;
  AppUser? get currentUser => _currentUser;
  List<Vehicle> get vehicles => _vehicles;
  List<Trip> get trips => _trips;
  List<WarehouseSlot> get warehouseSlots => _warehouseSlots;

  // Actions
  void login(String name, UserRole role, {String? truckNumber}) {
    _currentUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: role,
      truckNumber: truckNumber,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void addTrip(Trip trip) {
    _trips.add(trip);
    notifyListeners();
  }

  void updateTripStatus(String tripId, String newStatus) {
    int index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _trips[index] = _trips[index].copyWith(
        status: newStatus,
        endTime: newStatus == 'completed' ? DateTime.now() : null,
        efficiencyScore: newStatus == 'completed' ? (80 + Random().nextInt(20)) : null,
      );
      notifyListeners();
    }
  }

  /// Activates a trip: sets it active and injects mock live telemetry.
  void startTrip(String tripId) {
    int index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      final rng = Random();
      final velocity = 60.0 + rng.nextInt(40);
      final etaMins = 45 + rng.nextInt(120);
      final restHrs = 1 + rng.nextInt(3);
      final restMins = rng.nextInt(60);
      _trips[index] = _trips[index].copyWith(
        status: 'active',
        startTime: DateTime.now(),
        liveVelocity: velocity,
        eta: '$etaMins min',
        nextRestStop: '${restHrs}h ${restMins}m',
      );
      notifyListeners();
    }
  }

  /// Persists Gemini-generated AI insights onto a planned/active trip.
  void updateTripInsights(String tripId, String prediction, String strategy) {
    int index = _trips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _trips[index] = _trips[index].copyWith(
        prediction: prediction,
        strategy: strategy,
      );
      notifyListeners();
    }
  }

  /// Also updates the Vehicle-level prediction/strategy for Admin dashboard fallback.
  void updateVehiclePrediction(String vehicleId, String prediction, String strategy) {
    int index = _vehicles.indexWhere((v) => v.id == vehicleId);
    if (index != -1) {
      final v = _vehicles[index];
      _vehicles[index] = Vehicle(
        id: v.id,
        number: v.number,
        type: v.type,
        fuelType: v.fuelType,
        age: v.age,
        capacity: v.capacity,
        status: v.status,
        currentPrediction: prediction,
        currentStrategy: strategy,
      );
      notifyListeners();
    }
  }

  void addWarehouseSlot(WarehouseSlot slot) {
    _warehouseSlots.add(slot);
    notifyListeners();
  }

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    notifyListeners();
  }
  void setWarehouseCapacity(int capacity, String name) {
    _totalWarehouseSlots = capacity;
    _warehouseName = name;
    notifyListeners();
  }
}
