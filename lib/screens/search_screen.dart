import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import 'detail_place_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Place>> _placesFuture; // Future untuk data tempat dari API
  List<Place> _allPlaces = []; // List lengkap tempat dari API
  String _selectedCategory = 'all'; // Kategori yang dipilih, default "all"
  TextEditingController _searchController =
      TextEditingController(); // Controller input search text

  // List kategori yang dapat dipilih user untuk filter
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

  // Fungsi fetch data tempat dari API backend
  Future<List<Place>> fetchPlaces() async {
    final response = await http.get(
      Uri.parse(
        'https://boole-boolebe-525057870643.us-central1.run.app/places',
      ),
    );
    if (response.statusCode == 200) {
      // Jika berhasil, decode JSON dan map ke list Place
      final data = jsonDecode(response.body);
      List placesJson = data['places'];
      _allPlaces = placesJson.map((json) => Place.fromJson(json)).toList();
      return _allPlaces;
    } else {
      throw Exception('Failed to load places');
    }
  }

  // Filter list tempat berdasarkan kategori yang dipilih
  List<Place> filterByCategory(String category) {
    if (category == 'all') {
      return _allPlaces;
    }
    // Filter tempat berdasarkan kategori
    return _allPlaces.where((place) => place.category == category).toList();
  }

  // Filter list tempat berdasarkan kata pencarian
  List<Place> filterBySearch(List<Place> places, String query) {
    if (query.isEmpty) return places;
    return places
        .where(
          (place) =>
              place.name.toLowerCase().contains(query.toLowerCase()) ||
              place.category.toLowerCase().contains(query.toLowerCase()) ||
              place.rating.toString().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Widget filter kategori discroll horizontal
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
                    // Saat kategori dipilih, update state dan bersihkan search text
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['id']!;
                        _searchController.clear();
                      });
                    },
                    // Tampilan kategori
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        // Warna latar kategori
                        color:
                            isSelected
                                ? Colors.cyan
                                : Colors.transparent, // warna latar kategori
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Colors.cyan
                                  : Colors
                                      .grey
                                      .shade400, // warna border kategori
                        ),
                      ),
                      child: Text(
                        // teks kategori
                        cat['label']!,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors
                                      .white // warna teks kategori terpilih
                                  : Colors.grey.shade700, // warna teks kategori
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

  // Fungsi konversi waktu HH:mm:ss ke HH:mm (untuk opening hours)
  String formatTimeToHHmm(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      } else {
        return time;
      }
    } catch (_) {
      return time;
    }
  }

  // Widget kartu tempat untuk ditampilkan di list
  Widget buildPlaceCard(Place place) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300, // warna border kartu
          width: 1.5, // ketebalan border
        ),
        color: Colors.white, // warna card
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            // Navigasi ke halaman detail tempat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPlaceScreen(place: place),
              ),
            );
          },
          // Tampilan kartu
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
                  // Tampilan rating
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white70, // warna latar rating
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
              // Tampilan nama tempat
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
                        fontSize: 16, // + color (text)
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tampilan di bawah images
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tampilan waktu buka
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Opening Hours",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              place.openingHours != null
                                  ? formatTimeToHHmm(place.openingHours!)
                                  : "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        // Tampilan harga
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Price",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            // Tampilan harga
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
            // Tampilkan loading indicator
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
        // Filter tempat berdasarkan kategori yang dipilih
        final filtered = filterByCategory(_selectedCategory);
        //
        final filteredWithSearch = filterBySearch(
          filtered,
          _searchController.text,
        );

        return Scaffold(
          appBar: AppBar(
            // warna app bar
            backgroundColor: Colors.white,
            title: const Text('Find Your Destination'),
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            elevation: 0,
          ),
          // Tampilan body
          backgroundColor: const Color(0xFFF8F4F7), // warna body latar belakang
          body: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 42,
                    // Tampilan pencarian
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300, // warna search bar
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search), // + color
                        hintText: 'What are you looking for?', // + hinstyle
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                buildCategoryFilters(),
                // Bagian daftar tempat berdasarkan kategori & pencarian
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
                          : ListView(
                            children: [
                              // Jika kategori spesifik, tampilkan hanya section itu
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

  // Membuat section kategori dengan list kartu tempat secara horizontal
  Widget buildCategorySection(String categoryId, String title) {
    final filtered = filterByCategory(
      categoryId,
    ); // Filter berdasarkan kategori
    final filteredWithSearch = filterBySearch(
      filtered,
      _searchController.text,
    ); // Filter berdasarkan pencarian

    if (filteredWithSearch.isEmpty) {
      return const SizedBox.shrink(); // Jika kosong, jangan tampilkan apapun
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul section kategori
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ), // + color (text)
          ),
        ),

        // ListView horizontal berisi kartu tempat kategori tersebut
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
