import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location/location.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _heading;
  StreamSubscription? _compassSubscription;

  final Location _location = Location();

  double? _latitude;
  double? _longitude;
  double? _elevation; // altitude

  @override
  void initState() {
    super.initState();

    // Listen kompas
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading;
      });
    });

    // Setup lokasi dan permission
    _requestLocationPermissionAndListen();
  }

  void _requestLocationPermissionAndListen() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _latitude = currentLocation.latitude;
        _longitude = currentLocation.longitude;
        _elevation = currentLocation.altitude;
      });
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  String _directionLabel(double direction) {
    if (direction >= 337.5 || direction < 22.5) return "N";
    if (direction >= 22.5 && direction < 67.5) return "NE";
    if (direction >= 67.5 && direction < 112.5) return "E";
    if (direction >= 112.5 && direction < 157.5) return "SE";
    if (direction >= 157.5 && direction < 202.5) return "S";
    if (direction >= 202.5 && direction < 247.5) return "SW";
    if (direction >= 247.5 && direction < 292.5) return "W";
    if (direction >= 292.5 && direction < 337.5) return "NW";
    return "";
  }

  String _formatCoordinate(double? coord, bool isLatitude) {
    if (coord == null) return "...";
    final degrees = coord.abs().floor();
    final minutes = ((coord.abs() - degrees) * 60).floor();
    final seconds = (((coord.abs() - degrees) * 60 - minutes) * 60).floor();
    final direction =
        isLatitude ? (coord >= 0 ? "N" : "S") : (coord >= 0 ? "E" : "W");
    return "$degrees°$minutes'${seconds}\" $direction";
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading ?? 0;
    final directionLabel = _directionLabel(heading);

    final latitudeStr = _formatCoordinate(_latitude, true);
    final longitudeStr = _formatCoordinate(_longitude, false);
    final elevationStr =
        _elevation != null
            ? "${_elevation!.toStringAsFixed(0)} m Elevation"
            : "Elevation not available";

    return Scaffold(
      backgroundColor: Colors.cyan,
      appBar: AppBar(backgroundColor: Colors.cyan),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(320, 320),
                painter: _CompassPainter(heading),
              ),
              const SizedBox(height: 40),
              Text(
                "${heading.toStringAsFixed(0)}° $directionLabel",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "$latitudeStr  $longitudeStr",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 4),

              // *** Text "Your Location" dihapus ***
              const SizedBox(height: 4),
              Text(
                elevationStr,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double heading;

  _CompassPainter(this.heading);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    final paintCircle =
        Paint()
          ..color = Colors.cyan
          ..style = PaintingStyle.fill;

    final paintBorder =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final paintNeedleRed =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    final paintNeedleWhite =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round;

    final paintTicks =
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 2;

    // Background lingkaran hitam gelap
    canvas.drawCircle(center, radius, paintCircle);
    // Border lingkaran putih
    canvas.drawCircle(center, radius, paintBorder);

    // Gambar garis-garis tick derajat tiap 3°,
    // dan garis lebih tebal tiap 30°
    for (int i = 0; i < 360; i += 3) {
      final tickLength = (i % 30 == 0) ? 15.0 : 7.0;
      final tickPaint = (i % 30 == 0) ? paintBorder : paintTicks;
      final angle = i * math.pi / 180;

      final start = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    // Hitung rotasi jarum kompas (radian, putar berlawanan arah jarum jam)
    final needleAngle = (heading) * (math.pi / 180) * -1;
    final needleLength = radius * 0.75;

    final redNeedleEnd = Offset(
      center.dx + needleLength * math.sin(needleAngle),
      center.dy + needleLength * math.cos(needleAngle),
    );
    final whiteNeedleEnd = Offset(
      center.dx - needleLength * math.sin(needleAngle),
      center.dy - needleLength * math.cos(needleAngle),
    );

    // Jarum merah menunjuk utara
    canvas.drawLine(center, redNeedleEnd, paintNeedleRed);
    // Jarum putih menunjuk selatan
    canvas.drawLine(center, whiteNeedleEnd, paintNeedleWhite);

    // Titik tengah jarum kompas
    canvas.drawCircle(center, 10, Paint()..color = Colors.grey.shade200);

    // Label arah utama N, E, S, W
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Modifikasi posisi label supaya sesuai permintaan:
    // N bawah, S atas, E kiri, W kanan
    final directions = ['N', 'E', 'S', 'W'];
    final List<Offset> positions = [
      // N (bawah)
      Offset(center.dx, center.dy + radius - 20),
      // E (kiri)
      Offset(center.dx - radius + 20, center.dy),
      // S (atas)
      Offset(center.dx, center.dy - radius + 20),
      // W (kanan)
      Offset(center.dx + radius - 20, center.dy),
    ];

    for (int i = 0; i < 4; i++) {
      textPainter.text = TextSpan(
        text: directions[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final pos = positions[i];
      textPainter.paint(
        canvas,
        pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}
