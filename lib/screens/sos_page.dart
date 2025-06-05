import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:torch_light/torch_light.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({Key? key}) : super(key: key);

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  bool _isFlashing = false;
  bool _isLoading = false;
  String? _error;
  Timer? _flashTimer; // Timer untuk kedap-kedip

  @override
  void initState() {
    super.initState();
  }

  Future<void> _startFlashing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Permission cek
    if (await Permission.camera.request().isGranted) {
      setState(() {
        _isFlashing = true;
      });

      // Timer berkedip setiap 500 ms (kedap-kedip dengan interval)
      _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        try {
          if (timer.tick % 2 == 0) {
            await TorchLight.enableTorch(); // Nyalakan flashlight
          } else {
            await TorchLight.disableTorch(); // Matikan flashlight
          }
        } catch (e) {
          setState(() {
            _error = "Gagal mengakses flashlight!";
            _isFlashing = false;
          });
          timer.cancel(); // Stop timer jika terjadi error
        }
      });
    } else {
      setState(() {
        _error = "Izin kamera dibutuhkan untuk SOS";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _stopFlashing() async {
    _flashTimer?.cancel();
    try {
      await TorchLight.disableTorch(); // Pastikan flashlight dimatikan
    } catch (_) {}
    setState(() {
      _isFlashing = false;
    });
  }

  @override
  void dispose() {
    _stopFlashing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('SOS'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child:
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 90,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _isFlashing ? "Flashlight ON" : "Flashlight OFF",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 34),
                    ElevatedButton.icon(
                      icon: Icon(
                        _isFlashing ? Icons.flash_off : Icons.flash_on,
                      ),
                      label: Text(_isFlashing ? "Turn Off SOS" : "Turn On SOS"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (_isFlashing) {
                          await _stopFlashing();
                        } else {
                          await _startFlashing();
                        }
                      },
                    ),
                  ],
                ),
      ),
    );
  }
}
