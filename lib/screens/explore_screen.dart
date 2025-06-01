import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Place>> _placesFuture;

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
      return placesJson.map((json) => Place.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load places');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _placesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final places = snapshot.data ?? [];
        if (places.isEmpty) {
          return const Center(child: Text('No places found'));
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Container(color: Colors.cyan.shade100),

              // DraggableScrollableSheet dengan rekomendasi
              DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.60,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  height: 5,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "Recommended for you",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 210,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: places.length,
                                  itemBuilder: (context, index) {
                                    final place = places[index];
                                    return Container(
                                      width: 180,
                                      margin: EdgeInsets.only(
                                        right:
                                            index == places.length - 1 ? 0 : 16,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: InkWell(
                                          onTap: () {
                                            // TODO: Navigasi ke detail page jika mau
                                          },
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Stack(
                                                children: [
                                                  Image.network(
                                                    place.photoUrl,
                                                    height: 130,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => const Icon(
                                                          Icons.broken_image,
                                                          size: 130,
                                                        ),
                                                  ),
                                                  // Rating badge
                                                  Positioned(
                                                    right: 8,
                                                    bottom: 8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white70,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons.star,
                                                            size: 14,
                                                            color: Colors.amber,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            place.rating
                                                                .toStringAsFixed(
                                                                  1,
                                                                ),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
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
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      place.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      place.category,
                                                      style: const TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
