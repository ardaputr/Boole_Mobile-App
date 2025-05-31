import 'package:json_annotation/json_annotation.dart';

part 'locations.g.dart';

@JsonSerializable()
class LatLngModel {
  LatLngModel({required this.lat, required this.lng});

  final double lat;
  final double lng;

  factory LatLngModel.fromJson(Map<String, dynamic> json) =>
      _$LatLngFromJson(json);
  Map<String, dynamic> toJson() => _$LatLngToJson(this);
}

@JsonSerializable()
class Region {
  Region({
    required this.coords,
    required this.id,
    required this.name,
    required this.zoom,
  });

  final LatLngModel coords;
  final String id;
  final String name;
  final double zoom;

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
  Map<String, dynamic> toJson() => _$RegionToJson(this);
}

@JsonSerializable()
class Office {
  Office({
    required this.address,
    required this.id,
    required this.image,
    required this.lat,
    required this.lng,
    required this.name,
    required this.phone,
    required this.region,
  });

  final String address;
  final String id;
  final String image;
  final double lat;
  final double lng;
  final String name;
  final String phone;
  final String region;

  factory Office.fromJson(Map<String, dynamic> json) => _$OfficeFromJson(json);
  Map<String, dynamic> toJson() => _$OfficeToJson(this);
}

@JsonSerializable()
class Locations {
  Locations({required this.offices, required this.regions});

  final List<Office> offices;
  final List<Region> regions;

  factory Locations.fromJson(Map<String, dynamic> json) =>
      _$LocationsFromJson(json);
  Map<String, dynamic> toJson() => _$LocationsToJson(this);
}
