import 'dart:convert';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'package:http/http.dart' as http;

class ProfileDetailScreen extends StatefulWidget {
  final int userId;

  const ProfileDetailScreen({super.key, required this.userId});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  String? _updatedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserDetail(); // Ambil data user saat aplikasi dijalankan
  }

  // Fungsi async untuk fetch data user dari API
  Future<void> _fetchUserDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
        'http://192.168.100.199:5000/user/${widget.userId}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userData = data['user'];
            _isLoading = false;
            // Set updated photo url dengan timestamp supaya reload gambar
            if (_userData?['photo_url'] != null) {
              _updatedPhotoUrl =
                  'http://192.168.100.199:5000${_userData!['photo_url']}?t=${DateTime.now().millisecondsSinceEpoch}';
            } else {
              _updatedPhotoUrl = null;
            }
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load user data';
            _isLoading = false;
            _updatedPhotoUrl = null;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
          _updatedPhotoUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed: $e';
        _isLoading = false;
        _updatedPhotoUrl = null;
      });
    }
  }

  // Widget utama konten halaman: loading, error, atau data user
  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_userData == null)
      return const Center(child: Text('No user data found'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Avatar user, pakai foto jika ada, jika tidak pakai avatar otomatis dari layanan UI Avatars
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  _updatedPhotoUrl != null
                      ? NetworkImage(_updatedPhotoUrl!)
                      : (_userData?['photo_url'] != null
                          ? NetworkImage(
                            'http://192.168.100.199:5000${_userData!['photo_url']}',
                          )
                          : NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userData!['full_name'])}&background=0D8ABC&color=fff',
                          )),
            ),
          ),
          const SizedBox(height: 16),
          // Nama lengkap user
          Center(
            child: Text(
              _userData!['full_name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          // Baris detail user: Tanggal lahir, Jenis kelamin, Kebangsaan, Email, Nomor telepon
          _buildDetailRow('Date of Birth', _userData!['birth_date'] ?? ''),
          _buildDetailRow('Gender', _genderLabel(_userData!['gender'] ?? '')),
          _buildDetailRow('Nationality', _userData!['country'] ?? ''),
          _buildDetailRow('Email', _userData!['email'] ?? ''),
          _buildDetailRow('Phone Number', _userData!['phone_number'] ?? ''),

          const SizedBox(height: 30),
          // Tombol edit profile, navigasi ke halaman EditProfileScreen
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Tunggu hasil update dari halaman edit, jika true refresh data
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(userData: _userData!),
                  ),
                );
                if (updated == true) {
                  _fetchUserDetail();
                }
              },
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget baris detail label dan value (contoh: "Date of Birth" : "01 Jan 2000")
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label\n',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Mengubah kode gender 'M','F','O' menjadi label lengkap
  String _genderLabel(String code) {
    switch (code) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Detail')),
      body: _buildContent(),
    );
  }
}
