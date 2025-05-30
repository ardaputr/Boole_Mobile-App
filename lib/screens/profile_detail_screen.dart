import 'dart:convert';
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'package:http/http.dart' as http;

class ProfileDetailScreen extends StatefulWidget {
  final String email;

  const ProfileDetailScreen({super.key, required this.email});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserDetail();
  }

  Future<void> _fetchUserDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse('http://192.168.100.199/api/get_user_detail.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _userData = data['user'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Gagal memuat data user';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Koneksi gagal: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_userData == null)
      return const Center(child: Text('Tidak ada data user'));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _userData!['photo_url'] ??
                    'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_userData!['full_name'])}&background=0D8ABC&color=fff',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _userData!['full_name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),

          _buildDetailRow('Date of Birth', _userData!['birth_date'] ?? ''),
          _buildDetailRow('Gender', _genderLabel(_userData!['gender'] ?? '')),
          _buildDetailRow('Nationality', _userData!['country'] ?? ''),
          _buildDetailRow('Email', _userData!['email'] ?? ''),
          _buildDetailRow('Phone Number', _userData!['phone_number'] ?? ''),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
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
