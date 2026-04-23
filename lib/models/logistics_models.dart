enum UserRole { admin, driver, warehouse }
enum VehicleType { truck, ship, both }
enum VehicleStatus { active, delayed, docked, maintenance }

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String? truckNumber; // For drivers

  AppUser({required this.id, required this.name, required this.role, this.truckNumber});
}

class Vehicle {
  final String id;
  final String number;
  final VehicleType type;
  final String fuelType;
  final double age; // in years
  final double capacity; // in tonnes
  final VehicleStatus status;
  
  // Prediction & strategy info for prototype
  final String currentPrediction;
  final String currentStrategy;

  Vehicle({
    required this.id,
    required this.number,
    required this.type,
    required this.fuelType,
    required this.age,
    required this.capacity,
    required this.status,
    required this.currentPrediction,
    required this.currentStrategy,
  });
}

class Trip {
  final String id;
  final String vehicleId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String startLocation;
  final String endLocation;
  final String status; // 'planned', 'active', 'completed'
  final int efficiencyScore;

  // AI-generated fields
  final String prediction;
  final String strategy;

  // Live telemetry fields
  final double liveVelocity;
  final String eta;
  final String nextRestStop;

  Trip({
    required this.id,
    required this.vehicleId,
    this.startTime,
    this.endTime,
    required this.startLocation,
    required this.endLocation,
    required this.status,
    this.efficiencyScore = 0,
    this.prediction = '',
    this.strategy = '',
    this.liveVelocity = 0.0,
    this.eta = '--',
    this.nextRestStop = '--',
  });

  /// Returns a copy with updated fields.
  Trip copyWith({
    String? id,
    String? vehicleId,
    DateTime? startTime,
    DateTime? endTime,
    String? startLocation,
    String? endLocation,
    String? status,
    int? efficiencyScore,
    String? prediction,
    String? strategy,
    double? liveVelocity,
    String? eta,
    String? nextRestStop,
  }) {
    return Trip(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      status: status ?? this.status,
      efficiencyScore: efficiencyScore ?? this.efficiencyScore,
      prediction: prediction ?? this.prediction,
      strategy: strategy ?? this.strategy,
      liveVelocity: liveVelocity ?? this.liveVelocity,
      eta: eta ?? this.eta,
      nextRestStop: nextRestStop ?? this.nextRestStop,
    );
  }
}

class WarehouseSlot {
  final String id;
  final String facility;
  final DateTime slotTime;
  final String truckNumber;
  final String type; // 'unloading', 'parking'
  final String dockId; // 'Dock 1', 'Dock 2', 'Parking A'
  final String status; // 'booked', 'arrived', 'completed'

  WarehouseSlot({
    required this.id,
    required this.facility,
    required this.slotTime,
    required this.truckNumber,
    required this.type,
    required this.dockId,
    required this.status,
  });
}
