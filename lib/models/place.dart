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
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      photoUrl: json['photo_url'],
      category: json['category'],
      urlMaps: json['url_maps'],
      rating:
          (json['rating'] != null)
              ? double.tryParse(json['rating'].toString()) ?? 0.0
              : 0.0,
      openingHours: json['opening_hours'],
      ticketPrice:
          json['ticket_price'] != null
              ? double.tryParse(json['ticket_price'].toString())
              : null,
      address: json['address'],
      isFavorite: false,
    );
  }
}
