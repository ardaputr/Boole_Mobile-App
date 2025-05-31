import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  final String kodeWilayah;

  const WeatherScreen({super.key, required this.kodeWilayah});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? lokasi;
  List<dynamic>? prakiraanCuaca;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    final apiUrl =
        "https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=${widget.kodeWilayah}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['lokasi'] != null && data['data'] != null) {
          setState(() {
            lokasi = data['lokasi'];
            prakiraanCuaca = data['data'][0]['cuaca'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Data prakiraan cuaca tidak ditemukan.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Gagal mengambil data. Status: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Terjadi kesalahan: $e";
        isLoading = false;
      });
    }
  }

  Widget buildLokasi() {
    if (lokasi == null) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Lokasi: ${lokasi!['desa'] ?? '-'}, Kecamatan: ${lokasi!['kecamatan'] ?? '-'}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          "Kota/Kabupaten: ${lokasi!['kotkab'] ?? '-'}, Provinsi: ${lokasi!['provinsi'] ?? '-'}",
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          "Koordinat: Lat ${lokasi!['lat'] ?? '-'}, Lon ${lokasi!['lon'] ?? '-'}",
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget buildPrakiraanCuaca() {
    if (prakiraanCuaca == null || prakiraanCuaca!.isEmpty) {
      return const Text("Data prakiraan cuaca tidak tersedia.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prakiraanCuaca!.length,
      itemBuilder: (context, index) {
        final item = prakiraanCuaca![index];
        final waktuLokal = item['local_datetime'] ?? '-';
        final cuaca = item['weather_desc'] ?? '-';
        final suhu = item['t']?.toString() ?? '-';
        final kelembapan = item['hu']?.toString() ?? '-';
        final kecepatanAngin = item['ws']?.toString() ?? '-';
        final arahAngin = item['wd'] ?? '-';
        final jarakPandang = item['vs_text'] ?? '-';
        final imageUrl = item['image'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading:
                imageUrl.isNotEmpty
                    ? Image.network(
                      imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    )
                    : const Icon(Icons.wb_sunny),
            title: Text("$waktuLokal - $cuaca"),
            subtitle: Text(
              "Suhu: $suhu°C, Kelembapan: $kelembapan%, Kecepatan Angin: $kecepatanAngin km/jam, Arah Angin: $arahAngin, Jarak Pandang: $jarakPandang",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prakiraan Cuaca BMKG"),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLokasi(),
                      const Divider(),
                      buildPrakiraanCuaca(),
                    ],
                  ),
                ),
      ),
    );
  }
}
