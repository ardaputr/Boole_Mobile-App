import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import 'detail_place_screen.dart';

// StatefulWidget untuk halaman eksplorasi tempat dengan peta dan daftar
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late Future<List<Place>> _placesFuture;
  final Completer<GoogleMapController> _controller =
      Completer(); // Controller GoogleMap async
  LatLng? _currentPosition; // Posisi pengguna saat ini (latitude, longitude)
  Set<Marker> _markers = {}; // Set marker yang akan ditampilkan di peta

  List<Place> _allPlaces = []; // Semua data tempat dari API
  List<Place> _filteredPlaces =
      []; // Tempat yang sudah difilter berdasarkan pencarian
  String _searchQuery = ''; // Query pencarian text

  @override
  void initState() {
    super.initState();
    // Mulai fetch data tempat dari API
    _placesFuture = fetchPlaces();

    // Setelah data diterima, simpan ke state dan set marker di peta
    _placesFuture.then((places) {
      setState(() {
        _allPlaces = places;
        _filteredPlaces = places;
        _setMarkers(_filteredPlaces);
      });
    });
    // Dapatkan lokasi pengguna saat ini
    _getCurrentLocation();
  }

  // Mendapatkan lokasi pengguna menggunakan Geolocator
  Future<void> _getCurrentLocation() async {
    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Jika izin belum diberikan, minta izin
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // jika masih di tolak
        }
      }

      // Ambil posisi terkini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // akurasi tinggi
      );

      // Update posisi saat ini ke state (LatLng untuk Google Maps)
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Setelah controller peta siap, arahkan kamera ke posisi pengguna
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition!, zoom: 15), // camera lokasi
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Mengambil daftar tempat dari API backend
  Future<List<Place>> fetchPlaces() async {
    // final response = await http.get(
    //   Uri.parse(
    //     'https://boole-boolebe-525057870643.us-central1.run.app/places',
    //   ),
    // );
    final response = await http.get(
      Uri.parse('http://192.168.100.199:5000/places'),
    );

    if (response.statusCode == 200) {
      // Jika berhasil, decode JSON dan map ke objek Place
      final data = jsonDecode(response.body);
      List placesJson = data['places'];
      return placesJson.map((json) => Place.fromJson(json)).toList();
    } else {
      // Jika gagal, error exception
      throw Exception('Failed to load places');
    }
  }

  // Menghitung jarak (meter) antara dua titik latitude-longitude
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        // Convert meter ke kilometer dengan pembagi 300
        300;
  }

  // Membuat marker Google Maps untuk tiap tempat yang ada koordinatnya
  void _setMarkers(List<Place> places) {
    final newMarkers =
        places.where((p) => p.latitude != null && p.longitude != null).map((p) {
          BitmapDescriptor icon;
          // Pilih ikon marker berdasarkan kategori tempat
          switch (p.category.toLowerCase()) {
            case 'beach':
              icon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ); // biru muda
              break;
            case 'culinary':
              icon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ); // oranye
              break;
            case 'nature':
              icon = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ); // hijau
              break;
            default:
              icon = BitmapDescriptor.defaultMarker; // merah default
          }

          // Buat marker dengan info window dan onTap untuk navigasi ke detail
          return Marker(
            markerId: MarkerId(p.id.toString()),
            position: LatLng(p.latitude!, p.longitude!),
            icon: icon,
            infoWindow: InfoWindow(
              title: p.name,
              snippet: p.category,
              onTap: () {
                // Navigasi ke halaman detail tempat saat info window dipilih
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailPlaceScreen(place: p),
                  ),
                );
              },
            ),
          );
        }).toSet();

    // Update state marker
    setState(() {
      _markers = newMarkers;
    });
  }

  // Fungsi filter tempat berdasarkan query pencarian
  void _filterPlaces(String query) {
    List<Place> filtered =
        _allPlaces.where((place) {
          final nameLower = place.name.toLowerCase();
          final categoryLower = place.category.toLowerCase();
          final searchLower = query.toLowerCase();
          // Cari yang nama atau kategori mengandung kata pencarian
          return nameLower.contains(searchLower) ||
              categoryLower.contains(searchLower);
        }).toList();

    // Update state dengan query dan list hasil filter, serta marker baru
    setState(() {
      _searchQuery = query;
      _filteredPlaces = filtered;
      _setMarkers(_filteredPlaces);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Place>>(
      future: _placesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Saat masih loading tampilkan loading indicator
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          // Jika error, tampilkan pesan error
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (_allPlaces.isEmpty) {
          // Jika tidak ada data tempat tampilkan pesan kosong
          return const Center(child: Text('No places found'));
        }

        // List tempat rekomendasi, filter jarak kurang dari 10km dari posisi pengguna
        List<Place> recommendedPlaces;
        if (_searchQuery.isEmpty && _currentPosition != null) {
          recommendedPlaces =
              _filteredPlaces.where((place) {
                if (place.latitude == null || place.longitude == null)
                  return false;
                final placeLocation = LatLng(place.latitude!, place.longitude!);
                final distance = calculateDistance(
                  _currentPosition!,
                  placeLocation,
                );
                return distance <= 10; // atur jarak max 10 km
              }).toList();
        } else {
          recommendedPlaces = _filteredPlaces;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Widget Google Maps
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(0, 0),
                  zoom: _currentPosition != null ? 15 : 2,
                ),
                mapType: MapType.normal, // type maps
                myLocationEnabled: true, // lokasi aktif
                myLocationButtonEnabled: true, // tombol lokasi pengguna aktif
                markers: _markers, // marker di peta

                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  // Jika posisi pengguna tersedia, pindahkan kamera ke posisi itu
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: _currentPosition!,
                          zoom: 15, // jarak kamera
                        ),
                      ),
                    );
                  }
                },
              ),

              // Search bar di posisi atas peta
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 55,
                right: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search places...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      _filterPlaces(value); // panggil filter saat user mengetik
                    },
                  ),
                ),
              ),

              // Sheet yang dapat didrag ke atas/bawah berisi list rekomendasi
              DraggableScrollableSheet(
                initialChildSize: 0.6, // awal
                minChildSize: 0.3, // min
                maxChildSize: 0.60, // max
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
                              // garis kecil di atas
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
                              // Judul daftar rekomendasi
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
                              // ListView horizontal berisi kartu tempat rekomendasi
                              SizedBox(
                                height: 210,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: recommendedPlaces.length,
                                  itemBuilder: (context, index) {
                                    final place = recommendedPlaces[index];
                                    return Container(
                                      width: 180, // lebar kartu
                                      margin: EdgeInsets.only(
                                        // jarak antar kartu
                                        right:
                                            index ==
                                                    recommendedPlaces.length - 1
                                                ? 0 // jika kartu terakhir, tidak ada jarak kanan
                                                : 16, // jika bukan kartu terakhir, jarak kanan
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        // border kartu
                                        borderRadius: BorderRadius.circular(24),
                                        // ketika kartu di klik, buka detail tempat
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        DetailPlaceScreen(
                                                          place: place,
                                                        ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            // isi kartu
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

                                                  // rating
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
                                                      // nama tempat
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
                                                      // kategori
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
