import 'package:flutter/material.dart';

class StudentScreen extends StatelessWidget {
  final String name;
  final String nim;
  final String birthDate;
  final String gender;
  final String email;

  const StudentScreen({
    super.key,
    required this.name,
    required this.nim,
    required this.birthDate,
    required this.gender,
    required this.email,
  });

  String _genderLabel(String genderCode) {
    switch (genderCode.toUpperCase()) {
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
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
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
        title: const Text('Student Profile'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: const AssetImage(
                  'assets/images/student_photo.jpg',
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('NIM', nim),
            _buildDetailRow('Birth Date', birthDate),
            _buildDetailRow('Gender', _genderLabel(gender)),
            _buildDetailRow('Email', email),
          ],
        ),
      ),
    );
  }
}
