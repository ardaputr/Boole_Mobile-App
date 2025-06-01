import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _birthDateController;
  late String _selectedGender;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController; // Tambah controller password

  bool _passwordVisible = false; // Untuk toggle visibility password
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = widget.userData;
    _fullNameController = TextEditingController(text: user['full_name'] ?? '');
    _birthDateController = TextEditingController(
      text: user['birth_date'] ?? '',
    );
    _selectedGender = user['gender'] ?? 'O';
    _countryController = TextEditingController(text: user['country'] ?? '');
    _phoneController = TextEditingController(text: user['phone_number'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthDateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(_birthDateController.text) ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      _birthDateController.text = pickedDate.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final int userId = widget.userData['id'];

      // final url = Uri.parse('http://localhost:5000/user/$userId');
      //url
      final url = Uri.parse('http://192.168.100.199:5000/user/$userId');

      // Bangun body, sertakan password hanya jika diisi
      Map<String, dynamic> body = {
        'full_name': _fullNameController.text.trim(),
        'birth_date': _birthDateController.text.trim(),
        'gender': _selectedGender,
        'country': _countryController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        body['password'] = _passwordController.text.trim();
      }

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] != null) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _error = 'Update failed';
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
        _error = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              label: 'Full Name',
              controller: _fullNameController,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Password (leave blank to keep current)',
              controller: _passwordController,
              obscureText: !_passwordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _passwordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Birth Date (YYYY-MM-DD)',
              controller: _birthDateController,
              readOnly: true,
              onTap: _selectBirthDate,
            ),
            const SizedBox(height: 20),
            Text(
              'Gender',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Male')),
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'O', child: Text('Other')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedGender = val;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(label: 'Country', controller: _countryController),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
