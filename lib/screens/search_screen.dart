import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import './detail_place_screen.dart'; // Import halaman detail

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Place>> _placesFuture;
  List<Place> _allPlaces = [];
  String _selectedCategory = 'all'; // default all
  TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': 'All'},
    {'id': 'beach', 'label': 'Beach'},
    {'id': 'nature', 'label': 'Nature'},
    {'id': 'culinary', 'label': 'Culinary'},
  ];

  @override
  void initState() {
    super.initState();
    _placesFuture = fetchPlaces();
  }

  Future<List<Place>> fetchPlaces() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.199:5000/places'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List placesJson = data['places'];
      _allPlaces = placesJson.map((json) => Place.fromJson(json)).toList();
      return _allPlaces;
    } else {
      throw Exception('Failed to load places');
    }
  }

  List<Place> filterByCategory(String category) {
    if (category == 'all') {
      return _allPlaces;
    }
    return _allPlaces.where((place) => place.category == category).toList();
  }

  List<Place> filterBySearch(List<Place> places, String query) {
    if (query.isEmpty) return places;
    return places
        .where(
          (place) =>
              place.name.toLowerCase().contains(query.toLowerCase()) ||
              place.description.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Widget buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['id']!;
                        _searchController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.cyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isSelected ? Colors.cyan : Colors.grey.shade400,
                        ),
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget buildPlaceCard(Place place) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Navigasi ke halaman detail
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPlaceScreen(place: place),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    place.photoUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 130),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Tampilkan label Buka dan harga tiket di atas datanya
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Buka",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              place.openingHours ?? "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Harga tiket",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              place.ticketPrice != null
                                  ? "Rp ${place.ticketPrice!.toStringAsFixed(0)}"
                                  : "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _placesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (_allPlaces.isEmpty) {
          return const Scaffold(body: Center(child: Text('No places found')));
        }

        final filtered = filterByCategory(_selectedCategory);
        final filteredWithSearch = filterBySearch(
          filtered,
          _searchController.text,
        );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Find in Yogyakarta'),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            elevation: 0,
          ),
          backgroundColor: const Color(0xffF8F4F7),
          body: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search),
                        hintText: 'What are you looking for?',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            // TODO: Show info dialog or tooltip
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Category Filters
                buildCategoryFilters(),

                // Jika kategori all, tampilkan semua kategori satu per satu
                Expanded(
                  child:
                      _selectedCategory == 'all'
                          ? ListView(
                            children: [
                              buildCategorySection('beach', 'Beach'),
                              buildCategorySection('nature', 'Nature'),
                              buildCategorySection('culinary', 'Culinary'),
                              const SizedBox(height: 20),
                            ],
                          )
                          : // Jika bukan all, tampilkan kategori yang dipilih saja
                          ListView(
                            children: [
                              buildCategorySection(
                                _selectedCategory,
                                _categories.firstWhere(
                                  (cat) => cat['id'] == _selectedCategory,
                                )['label']!,
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildCategorySection(String categoryId, String title) {
    final filtered = filterByCategory(categoryId);
    final filteredWithSearch = filterBySearch(filtered, _searchController.text);

    if (filteredWithSearch.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredWithSearch.length,
            itemBuilder: (context, index) {
              return buildPlaceCard(filteredWithSearch[index]);
            },
          ),
        ),
      ],
    );
  }
}
