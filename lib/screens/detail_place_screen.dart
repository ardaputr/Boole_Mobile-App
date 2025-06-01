import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DetailPlaceScreen extends StatefulWidget {
  final Place place;
  const DetailPlaceScreen({super.key, required this.place});

  @override
  State<DetailPlaceScreen> createState() => _DetailPlaceScreenState();
}

class _DetailPlaceScreenState extends State<DetailPlaceScreen> {
  late Place place;

  String selectedTimezone = 'WIB';
  final List<String> timezoneOptions = [
    'WIB',
    'WITA',
    'WIT',
    'London',
    'Japan',
    'Korea',
    'USA',
    'AUS',
    'Dubai',
    'Mesir',
  ];

  String selectedCurrency = 'Rp';
  final List<String> currencyOptions = [
    'Rp',
    'MYR',
    'AUD',
    'USD',
    'GBP',
    'EUR',
  ];

  final Map<String, double> currencyRates = {
    'Rp': 1,
    'MYR': 0.31,
    'AUD': 0.000094,
    'USD': 0.000067,
    'GBP': 0.000058,
    'EUR': 0.000063,
  };

  final Map<String, int> timezoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
    'Japan': 9,
    'Korea': 9,
    'USA': -5,
    'AUS': 10,
    'Dubai': 4,
    'Mesir': 2,
  };

  bool isTranslating = false;
  bool isTranslated = false;
  String? translatedDescription;
  late String displayedDescription;

  int? userId;

  @override
  @override
  void initState() {
    super.initState();
    place = widget.place;
    displayedDescription = place.description;
    _loadUserIdAndFavoriteStatus();
  }

  Future<void> _loadUserIdAndFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      setState(() {
        place.isFavorite = false;
      });
      return;
    }

    final favList = prefs.getStringList('wishlist_user_$userId') ?? [];
    setState(() {
      place.isFavorite = favList.contains(place.id.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please login again.')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'wishlist_user_$userId';
    final favList = prefs.getStringList(key) ?? [];

    setState(() {
      if (place.isFavorite) {
        favList.remove(place.id.toString());
        place.isFavorite = false;
      } else {
        favList.add(place.id.toString());
        place.isFavorite = true;
      }
    });

    await prefs.setStringList(key, favList);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          place.isFavorite ? 'Added to Wishlist' : 'Removed from Wishlist',
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  String convertOpenTime(String openTime, String targetTimezone) {
    try {
      final timeParts = openTime.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      int offsetTarget = timezoneOffsets[targetTimezone] ?? 7;
      int offsetWIB = 7;

      int convertedHour = hour + (offsetTarget - offsetWIB);
      if (convertedHour < 0) convertedHour += 24;
      if (convertedHour >= 24) convertedHour -= 24;

      final hh = convertedHour.toString().padLeft(2, '0');
      final mm = minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return openTime;
    }
  }

  String convertTimeRange(String openingHours, String timezone) {
    if (openingHours == '-' || openingHours.isEmpty) return '-';

    if (openingHours.contains('-')) {
      final parts = openingHours.split('-');
      if (parts.length != 2) return openingHours;

      final startConverted = convertOpenTime(parts[0].trim(), timezone);
      final endConverted = convertOpenTime(parts[1].trim(), timezone);

      return '$startConverted - $endConverted';
    } else {
      return convertOpenTime(openingHours.trim(), timezone);
    }
  }

  String convertCurrency(dynamic price, String currency) {
    if (price == null) return '-';
    double priceDouble;
    try {
      priceDouble =
          price is int ? price.toDouble() : double.parse(price.toString());
    } catch (_) {
      return '-';
    }

    final rate = currencyRates[currency] ?? 1;
    final converted = priceDouble * rate;

    if (currency == 'Rp') {
      return 'Rp ${converted.toStringAsFixed(0)}';
    } else {
      return '$currency ${converted.toStringAsFixed(2)}';
    }
  }

  Future<void> translateDescription() async {
    if (isTranslating) return;
    if (place.description.isEmpty) return;

    setState(() {
      isTranslating = true;
    });

    final String text = place.description;

    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=id|en',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final translatedText =
            json['responseData']?['translatedText'] ?? 'Translation failed';

        setState(() {
          translatedDescription = translatedText;
          displayedDescription = translatedDescription!;
          isTranslated = true;
          isTranslating = false;
        });
      } else {
        setState(() {
          translatedDescription = 'Translation failed';
          displayedDescription = translatedDescription!;
          isTranslated = true;
          isTranslating = false;
        });
      }
    } catch (e) {
      setState(() {
        translatedDescription = 'Translation error: $e';
        displayedDescription = translatedDescription!;
        isTranslated = true;
        isTranslating = false;
      });
    }
  }

  void toggleTranslate() {
    if (isTranslated) {
      // Jika sudah translate, kembali ke bahasa asli
      setState(() {
        displayedDescription = place.description;
        isTranslated = false;
      });
    } else {
      // Jika belum translate, lakukan translate
      translateDescription();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedTime = convertTimeRange(
      place.openingHours ?? '-',
      selectedTimezone,
    );
    final displayedPrice = convertCurrency(place.ticketPrice, selectedCurrency);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(50),
                  ),
                  child: Image.network(
                    place.photoUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 240),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 230,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    place.category[0].toUpperCase() +
                                        place.category.substring(1),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyan),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Opening Hours',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayedTime,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: selectedTimezone,
                            isExpanded: true,
                            underline: Container(height: 1, color: Colors.cyan),
                            items:
                                timezoneOptions
                                    .map(
                                      (zone) => DropdownMenuItem<String>(
                                        value: zone,
                                        child: Text(zone),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedTimezone = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyan),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Price',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            convertCurrency(
                              place.ticketPrice,
                              selectedCurrency,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: selectedCurrency,
                            isExpanded: true,
                            underline: Container(height: 1, color: Colors.cyan),
                            items:
                                currencyOptions
                                    .map(
                                      (cur) => DropdownMenuItem<String>(
                                        value: cur,
                                        child: Text(cur),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedCurrency = val;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description header + translate button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.translate),
                    tooltip:
                        isTranslated
                            ? 'Show Original Description'
                            : 'Translate to English',
                    onPressed: toggleTranslate,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child:
                  isTranslating
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                        displayedDescription,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        textAlign: TextAlign.justify,
                      ),
            ),

            const SizedBox(height: 16),

            if (place.address != null && place.address!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  place.address!,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (place.urlMaps.isNotEmpty) {
                    _launchURL(place.urlMaps);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL Google Maps tidak tersedia'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.cyan),
                color: Colors.white,
              ),
              child: IconButton(
                icon: Icon(
                  place.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: Colors.cyan,
                ),
                onPressed: _toggleFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
