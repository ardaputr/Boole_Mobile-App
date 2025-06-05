import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart'; // Plugin compass (sensor arah)
import 'package:location/location.dart';
import 'sos_page.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _heading; // Nilai arah kompas (0-360 derajat)
  StreamSubscription? _compassSubscription; // Subsription arah kompas

  final Location _location = Location(); // Instance plugin lokasi

  double? _latitude; // Latitude pengguna
  double? _longitude; // Longitude pengguna
  double? _elevation; // Elevasi (ketinggian) pengguna

  @override
  void initState() {
    super.initState();

    // Mendapatkan arah kompas
    _compassSubscription = FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading;
      });
    });

    // Request izin lokasi pengguna
    _requestLocationPermissionAndListen();
  }

  // Fungsi untuk meminta izin lokasi
  void _requestLocationPermissionAndListen() async {
    bool serviceEnabled =
        await _location
            .serviceEnabled(); // Memeriksa apakah service lokasi aktif
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService(); // Meminta izin
      if (!serviceEnabled)
        return; // Jika user tidak aktifkan service lokasi, hentikan
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted)
        return; // Jika user tolak, hentikan
    }

    // Listen perubahan lokasi dan update state latitude, longitude, elevasi
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
    // Hentikan arah kompas
    _compassSubscription?.cancel();
    super.dispose();
  }

  // Fungsi untuk mendapatkan label arah dan rentang sesuai arah mata angin
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

  // Format koordinat desimal jadi derajat-menit-detik dan arah (N/S/E/W)
  String _formatCoordinate(double? coord, bool isLatitude) {
    if (coord == null) return "...";
    final degrees = coord.abs().floor(); // Konversi ke derajat
    final minutes = ((coord.abs() - degrees) * 60).floor(); // Konversi ke menit
    final seconds =
        (((coord.abs() - degrees) * 60 - minutes) * 60)
            .floor(); // Konversi ke detik
    final direction =
        isLatitude
            ? (coord >= 0 ? "N" : "S")
            : (coord >= 0 ? "E" : "W"); // Arah
    return "$degrees°$minutes'${seconds}\" $direction";
  }

  @override
  Widget build(BuildContext context) {
    final heading = _heading ?? 0; // Default 0 jika belum ada nilai
    final directionLabel = _directionLabel(heading);

    final latitudeStr = _formatCoordinate(_latitude, true);
    final longitudeStr = _formatCoordinate(_longitude, false);
    final elevationStr =
        _elevation != null
            ? "${_elevation!.toStringAsFixed(0)} m Elevation"
            : "Elevation not available";

    return Scaffold(
      backgroundColor: Colors.cyan.shade50,
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade50,
        actions: [
          IconButton(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 32,
            ),
            tooltip: "SOS",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SOSPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Kompas custom yang digambar menggunakan CustomPainter
              CustomPaint(
                size: const Size(300, 300),
                painter: _PaleCyanCompassPainter(heading),
              ),
              const SizedBox(height: 32),
              // Teks arah derajat dan label arah
              Text(
                "${heading.toStringAsFixed(0)}° $directionLabel",
                style: TextStyle(
                  color: Colors.cyan.shade900,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              // Teks koordinat latitude dan longitude
              Text(
                "$latitudeStr  $longitudeStr",
                style: TextStyle(color: Colors.cyan.shade700, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Teks elevasi
              Text(
                elevationStr,
                style: TextStyle(
                  color: Colors.cyan.shade700.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CustomPainter untuk gambar kompas
class _PaleCyanCompassPainter extends CustomPainter {
  final double heading;

  _PaleCyanCompassPainter(this.heading);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);

    // Background gradient pale cyan
    final gradient = RadialGradient(
      colors: [Colors.cyan.shade100, Colors.white.withOpacity(0.9)],
      stops: [0.4, 1],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paintBackground =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paintBackground);

    // Outer ring tipis
    final ringPaint =
        Paint()
          ..color = Colors.cyan.shade300.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    canvas.drawCircle(center, radius - 3, ringPaint);

    // Ticks kecil & utama
    final tickPaintSmall =
        Paint()
          ..color = Colors.cyan.shade400.withOpacity(0.7)
          ..strokeWidth = 1.2;
    final tickPaintMain =
        Paint()
          ..color = Colors.cyan.shade700.withOpacity(0.9)
          ..strokeWidth = 2.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Putar canvas berlawanan arah jarum jam sesuai heading
    canvas.rotate(-heading * math.pi / 180);

    for (int i = 0; i < 360; i += 5) {
      final isMainTick = (i % 30 == 0);
      final tickLength = isMainTick ? 15.0 : 8.0;
      final paint = isMainTick ? tickPaintMain : tickPaintSmall;

      final angle = (i - 90) * math.pi / 180;
      final start = Offset(
        (radius - tickLength - 10) * math.cos(angle),
        (radius - tickLength - 10) * math.sin(angle),
      );
      final end = Offset(
        (radius - 10) * math.cos(angle),
        (radius - 10) * math.sin(angle),
      );

      canvas.drawLine(start, end, paint);
    }

    // Label arah utama N, E, S, W
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final directions = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];

    final directionTextStyle = TextStyle(
      color: Colors.cyan.shade900,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(
          blurRadius: 2,
          color: Colors.cyan.shade200.withOpacity(0.7),
          offset: const Offset(1, 1),
        ),
      ],
    );

    for (int i = 0; i < directions.length; i++) {
      final angle = (angles[i] - 90) * math.pi / 180;
      final labelRadius = radius - 50;

      textPainter.text = TextSpan(
        text: directions[i],
        style: directionTextStyle,
      );
      textPainter.layout();

      final pos = Offset(
        labelRadius * math.cos(angle) - textPainter.width / 2,
        labelRadius * math.sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, pos);
    }

    canvas.restore();

    // Jarum panah segitiga ramping (merah dan putih)
    final needleLength = radius * 0.75;
    final needleWidth = 10.0;

    void drawArrowNeedle(Color color, double offsetY) {
      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2);

      final path = Path();
      path.moveTo(center.dx, center.dy + offsetY);
      path.lineTo(
        center.dx - needleWidth / 2,
        center.dy + offsetY + needleLength / 2.8,
      );
      path.lineTo(
        center.dx + needleWidth / 2,
        center.dy + offsetY + needleLength / 2.8,
      );
      path.close();

      final tipPath = Path();
      tipPath.moveTo(center.dx, center.dy + offsetY - needleLength * 0.7);
      tipPath.lineTo(center.dx - needleWidth / 2, center.dy + offsetY);
      tipPath.lineTo(center.dx + needleWidth / 2, center.dy + offsetY);
      tipPath.close();

      canvas.drawPath(path, paint);
      canvas.drawPath(tipPath, paint);
    }

    // Gambar jarum merah (arah utara) dan putih (arah selatan)
    drawArrowNeedle(Colors.redAccent.shade200, 0);
    drawArrowNeedle(Colors.white.withOpacity(0.85), needleLength * 0.7);

    // Titik tengah dengan glow cyan
    final centerCirclePaint =
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.cyan.shade300.withOpacity(0.9), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: 12));

    canvas.drawCircle(center, 12, centerCirclePaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.cyan.shade900);
  }

  @override
  bool shouldRepaint(covariant _PaleCyanCompassPainter oldDelegate) {
    return oldDelegate.heading != heading;
  }
}
