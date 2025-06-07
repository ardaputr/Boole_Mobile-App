import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk menyimpan data user
import 'package:http/http.dart' as http;
import 'profile_detail_screen.dart';
import 'impressions_and_suggestions_screen.dart';
import 'student_screen.dart';
import 'login_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String email;

  const ProfileScreen({super.key, required this.userName, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? userId; // Menyimpan ID user yang diambil dari SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Memuat ID user saat aplikasi dijalankan
  }

  // Fungsi mengambil userId dari SharedPreferences
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    setState(() {
      userId = id;
    });
  }

  // Fungsi logout: hapus data login dari SharedPreferences dan kembali ke halaman login
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('full_name');

    // Navigasi ke halaman login dan hapus history halaman sebelumnya
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Fungsi hapus akun user dengan konfirmasi
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? userId = prefs.getInt('user_id');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found, please login again'),
          ),
        );
        return;
      }
      // url
      // final url = Uri.parse(
      //   'https://boole-boolebe-525057870643.us-central1.run.app/user/$userId',
      // );

      final url = Uri.parse('http://192.168.1.14:5000/user/$userId');

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['message'] != null) {
          await prefs.clear(); // Bersihkan semua data SharedPreferences

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(data['message'])));

          // Kembali ke halaman login dan hapus history
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete account')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    }
  }

  // Fungsi membuka halaman detail profil jika userId tersedia
  void _openProfileDetail() {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileDetailScreen(userId: userId!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found, please login again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info user (nama dan email)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(),
                  Text(
                    widget.email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // List menu profile dengan scrollable jika melebihi batas tinggi layar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Menu Details (Detail Akun)
                      _buildMenuItem(
                        context,
                        icon: Icons.details_outlined,
                        iconBgColor: Colors.cyan.shade100,
                        title: 'Details',
                        subtitle: 'Complete details of your account',
                        onTap: _openProfileDetail,
                      ),
                      // Menu Wishlist
                      _buildMenuItem(
                        context,
                        icon: Icons.favorite_border,
                        iconBgColor: Colors.pink.shade100,
                        title: 'Wishlist',
                        subtitle: 'Places you want to visit',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WishlistScreen(),
                            ),
                          );
                        },
                      ),
                      // Menu Student
                      _buildMenuItem(
                        context,
                        icon: Icons.school_outlined,
                        iconBgColor: Colors.blue.shade100,
                        iconColor: Colors.blue.shade700,
                        title: 'Student',
                        subtitle: 'Profile about the student',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => StudentScreen(
                                    name: 'Waramatja Yuda Putra',
                                    nim: '123220163',
                                    birthDate: '6 September 2003',
                                    gender: 'M',
                                    email: '123220163@student.upnyk.ac.id',
                                  ),
                            ),
                          );
                        },
                      ),
                      // Menu Impressions and Suggestions
                      _buildMenuItem(
                        context,
                        icon: Icons.feedback_outlined,
                        iconBgColor: Colors.orange.shade100,
                        iconColor: Colors.orange.shade700,
                        title: 'Impressions and Suggestions',
                        subtitle:
                            'Impressions and suggestions for the Mobile Programming Technology course',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      const ImpressionsAndSuggestionsScreen(),
                            ),
                          );
                        },
                      ),
                      // Menu Delete Account
                      _buildMenuItem(
                        context,
                        icon: Icons.delete_outline,
                        iconBgColor: Colors.red.shade100,
                        iconColor: Colors.red.shade700,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        onTap: () {
                          _deleteAccount(context);
                        },
                      ),
                      // Menu Log out
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        iconBgColor: Colors.grey.shade300,
                        title: 'Log out',
                        subtitle: 'Log out of your account',
                        onTap: () {
                          _logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk membuat item menu profil yang konsisten
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: iconBgColor,
          child: Icon(icon, color: iconColor ?? Colors.cyan),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
