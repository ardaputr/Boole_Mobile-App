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
  List<Place> wishlistPlaces = []; // List tempat yang ada di wishlist

  @override
  void initState() {
    super.initState();
    _loadWishlist(); // Load data wishlist saat widget dibuat
  }

  // Fungsi untuk load daftar wishlist dari SharedPreferences dan API
  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt(
      'user_id',
    ); // ambil user_id dari SharedPreferences
    if (currentUserId == null) {
      // Jika user belum login, kosongkan wishlist
      setState(() {
        wishlistPlaces = [];
      });
      return;
    }

    // Ambil daftar id tempat favorit user dari SharedPreferences
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

  // Fungsi mengambil semua tempat dari API backend
  Future<List<Place>> fetchAllPlaces() async {
    final response = await http.get(
      Uri.parse(
        'https://boole-boolebe-525057870643.us-central1.run.app/places',
      ),
    );

    // final response = await http.get(
    //   Uri.parse('http://192.168.100.199:5000/places'),
    // );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List placesJson = data['places'];
      // Mapping JSON ke objek Place
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
                        // Navigasi ke halaman detail tempat saat item diklik
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
