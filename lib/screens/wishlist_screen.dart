import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import 'detail_place_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Place> wishlistPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt(
      'user_id',
    ); // ambil user_id dari SharedPreferences
    if (currentUserId == null) {
      setState(() {
        wishlistPlaces = [];
      });
      return;
    }

    final favIds = prefs.getStringList('wishlist_user_$currentUserId') ?? [];

    // Fetch semua places dari API
    List<Place> allPlaces = await fetchAllPlaces();

    // Filter tempat yang ada di wishlist user
    List<Place> favPlaces =
        allPlaces
            .where((place) => favIds.contains(place.id.toString()))
            .toList();

    setState(() {
      wishlistPlaces = favPlaces;
    });
  }

  Future<List<Place>> fetchAllPlaces() async {
    final response = await http.get(
      Uri.parse(
        'https://boole-boolebe-525057870643.us-central1.run.app/places',
      ),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body:
          wishlistPlaces.isEmpty
              ? const Center(child: Text('Your wishlist is empty'))
              : ListView.builder(
                itemCount: wishlistPlaces.length,
                itemBuilder: (context, index) {
                  final place = wishlistPlaces[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        place.photoUrl,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      place.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPlaceScreen(place: place),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
