class Place {
  final int id;
  final String name;
  final String description;
  final String photoUrl;
  final String category;
  final String urlMaps;
  final double rating;
  final String? openingHours;
  final double? ticketPrice;
  final String? address;
  bool isFavorite;
  final double? latitude;
  final double? longitude;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.urlMaps,
    required this.rating,
    this.openingHours,
    this.ticketPrice,
    this.address,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    double? parseToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Place(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      category: json['category'] ?? '',
      openingHours: json['opening_hours'] as String?,
      ticketPrice: parseToDouble(json['ticket_price']),
      urlMaps: json['url_maps'] ?? '',
      address: json['address'] ?? '',
      rating: parseToDouble(json['rating']) ?? 0.0,
      latitude:
          json['location'] != null
              ? parseToDouble(json['location']['latitude'])
              : null,
      longitude:
          json['location'] != null
              ? parseToDouble(json['location']['longitude'])
              : null,
    );
  }
}
