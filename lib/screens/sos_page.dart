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
  Timer? _flashTimer;

  Future<void> _startFlashing() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (await Permission.camera.request().isGranted) {
      setState(() {
        _isFlashing = true;
      });

      _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        try {
          if (timer.tick % 2 == 0) {
            await TorchLight.enableTorch();
          } else {
            await TorchLight.disableTorch();
          }
        } catch (e) {
          setState(() {
            _error = "Failed to access flashlight!";
            _isFlashing = false;
          });
          timer.cancel();
        }
      });
    } else {
      setState(() {
        _error = "Camera permission required for SOS";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _stopFlashing() async {
    _flashTimer?.cancel();
    try {
      await TorchLight.disableTorch();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Emergency SOS',
          style: TextStyle(fontWeight: FontWeight.bold), // + color
        ),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          // background color icon
                          color: Colors.red[50],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Icon(
                          Icons.emergency,
                          size: 80,
                          // color icon
                          color:
                              _isFlashing ? Colors.red[700] : Colors.red[400],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isFlashing ? "SOS ACTIVE" : "EMERGENCY SIGNAL",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          // text color
                          color:
                              _isFlashing ? Colors.red[700] : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isFlashing
                            ? "Flashing on"
                            : "Press button to activate SOS mode",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            // button background color
                            backgroundColor:
                                _isFlashing ? Colors.red[700] : Colors.red[400],
                            // button text color
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            if (_isFlashing) {
                              await _stopFlashing();
                            } else {
                              await _startFlashing();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // icon flashlight
                              Icon(
                                _isFlashing ? Icons.flash_off : Icons.flash_on,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isFlashing ? "STOP EMERGENCY" : "ACTIVATE SOS",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "In case of emergency, use this signal to call for help",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
