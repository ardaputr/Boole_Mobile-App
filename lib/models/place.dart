class Place {
  final int id;
  final String name;
  final String description;
  final String photoUrl;
  final String category;
  final String urlMaps;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.category,
    required this.urlMaps,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      photoUrl: json['photo_url'],
      category: json['category'],
      urlMaps: json['url_maps'],
    );
  }
}
