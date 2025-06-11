import 'package:flutter/material.dart';

class ImpressionsAndSuggestionsScreen extends StatelessWidget {
  const ImpressionsAndSuggestionsScreen({super.key});
  Widget impressionOrSuggestionCard({
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
    required Color cardColor,
    required Color titleColor,
    required Color contentColor,
  }) {
    return Card(
      // warna card
      // color: Colors.grey.shade200,
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: iconColor ?? Colors.cyan),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      // color: titleColor,
                      color: contentColor,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impressions & Suggestions'),
        // warna app bar
        backgroundColor: Colors.white,
      ),
      // warna background
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto dan Nama Dosen
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/images/dosen_bagus.jpeg'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Bagus Muhammad Akbar, M.Kom',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'NIP: 19890801 201903 1 013',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
              Center(
                child: Text(
                  'NIDN: 0001088905',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 20),
              // Pendidikan
              const Text(
                'Education',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              // const SizedBox(height: 8),
              const Text(
                '• M.Kom (Universitas Islam Indonesia 2016)\n'
                '• S.ST (Institut Teknologi Bandung 2011)\n'
                '• A.Md (Politeknik Seni Yogyakarta 2010)',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              // Bidang Kemintan
              const Text(
                'Field of Interest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              // const SizedBox(height: 8),
              const Text(
                'Teknologi Informasi, Sistem Informasi, Jaringan Komputer',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              // Kontak
              const Text(
                'Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'bagusmuhammadakbar@upnyk.ac.id',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Kesan dan Pesan pakai card dengan ikon
              impressionOrSuggestionCard(
                icon: Icons.thumb_up_alt_outlined,
                iconColor: Colors.green.shade700,
                title: 'Impression',
                content:
                    'Mata kuliah Teknologi Pemrograman Mobile sangat membantu dalam memahami dasar-dasar pengembangan aplikasi mobile. Materi yang disampaikan mudah dipahami dan aplikatif.',
                cardColor: Colors.grey.shade200,
                titleColor: Colors.grey.shade700,
                contentColor: Colors.black87,
              ),
              impressionOrSuggestionCard(
                icon: Icons.lightbulb_outline,
                iconColor: Colors.orange.shade700,
                title: 'Suggestion',
                content:
                    'Semoga materi selanjutnya dapat lebih banyak membahas framework Flutter dan praktik langsung membuat aplikasi. Selain itu, harap ada lebih banyak studi kasus yang relevan dengan kebutuhan industri saat ini.',
                cardColor: Colors.grey.shade200,
                titleColor: Colors.grey.shade700,
                contentColor: Colors.black87,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
