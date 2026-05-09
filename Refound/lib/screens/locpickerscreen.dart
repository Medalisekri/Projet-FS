import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../theme/apptheme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _picked       = const LatLng(36.8065, 10.1815);
  String _addressLabel = '';
  bool   _geocoding    = false;   // ← shows loading while fetching address

  @override
  void initState() {
    super.initState();
    _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();

      // ✅ mounted check after every await
      if (!mounted) return;

      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = loc);
      _mapController.move(loc, 14);
      _reverseGeocode(loc);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng point) async {
    // ✅ Show loading indicator
    if (!mounted) return;
    setState(() {
      _geocoding    = true;
      _addressLabel = '';
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&accept-language=en',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'ReFoundApp/1.0',
      });

      // ✅ Always check mounted after every await
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};

        final parts = <String>[];
        if (address['road']    != null) parts.add(address['road']);
        if (address['suburb']  != null) parts.add(address['suburb']);
        if (address['city']    != null) {
          parts.add(address['city']);
        } else if (address['town']    != null) {
          parts.add(address['town']);
        } else if (address['village'] != null) {
          parts.add(address['village']);
        }

        if (!mounted) return;
        setState(() {
          _addressLabel = parts.isNotEmpty
              ? parts.join(', ')
              : (data['display_name'] as String?) ?? '';
          _geocoding = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _addressLabel = _coordFallback(point);
          _geocoding    = false;
        });
      }
    } catch (_) {
      // ✅ mounted check in catch too
      if (!mounted) return;
      setState(() {
        _addressLabel = _coordFallback(point);
        _geocoding    = false;
      });
    }
  }

  String _coordFallback(LatLng point) =>
      '${point.latitude.toStringAsFixed(4)}, '
      '${point.longitude.toStringAsFixed(4)}';

  void _confirm() {
    // ✅ Cancel any pending geocode — just pop with current state
    Navigator.pop<Map<String, dynamic>>(context, {
      'lat':     _picked.latitude,
      'lng':     _picked.longitude,
      'address': _addressLabel.isNotEmpty
          ? _addressLabel
          : _coordFallback(_picked),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Pick Location',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm',
                style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 13,
              onTap: (_, point) {
                // ✅ mounted check before setState in callback
                if (!mounted) return;
                setState(() => _picked = point);
                _reverseGeocode(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.refound.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 48, height: 48,
                    child: const Icon(Icons.location_pin,
                        color: Color(0xFFE24B4A), size: 42),
                  ),
                ],
              ),
            ],
          ),

          // ── Instruction banner ────────────────────────
          Positioned(
            top: 12, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.touch_app_outlined,
                    color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Tap anywhere on the map to place pin',
                    style: TextStyle(
                        color: Colors.white, fontSize: 12)),
              ]),
            ),
          ),

          // ── Address label ─────────────────────────────
          Positioned(
            bottom: 80, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                // ✅ Show spinner while geocoding
                _geocoding
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.teal))
                    : const Icon(Icons.location_on_outlined,
                        color: AppColors.teal, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _geocoding
                        ? 'Getting address...'
                        : _addressLabel.isNotEmpty
                            ? _addressLabel
                            : 'Tap the map to select a location',
                    style: TextStyle(
                        fontSize: 13,
                        color: _geocoding || _addressLabel.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                  ),
                ),
              ]),
            ),
          ),

          // ── My location FAB ───────────────────────────
          Positioned(
            bottom: 20, right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}