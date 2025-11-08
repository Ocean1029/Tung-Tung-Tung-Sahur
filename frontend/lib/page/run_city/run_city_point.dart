import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents one NFC location in the Run City experience.
class RunCityPoint {
  const RunCityPoint({
    required this.id,
    required this.name,
    required this.district,
    required this.location,
    this.collected = false,
  });

  final String id;
  final String name;
  final String district;
  final LatLng location;
  final bool collected;

  RunCityPoint copyWith({
    String? id,
    String? name,
    String? district,
    LatLng? location,
    bool? collected,
  }) {
    return RunCityPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      district: district ?? this.district,
      location: location ?? this.location,
      collected: collected ?? this.collected,
    );
  }
}

