import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/apptheme.dart';
import '../../../models/itemmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final _db = FirebaseFirestore.instance;

  LatLng _center         = const LatLng(36.8065, 10.1815); // Tunis default
  LatLng? _userLocation;
  List<ItemModel> _items = [];
  ItemModel? _selected;
  bool _loading          = true;
  String _filter         = 'all'; // 'all' | 'lost' | 'found'

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadItems();
  }

  // ── Get user GPS location ─────────────────────────────
  Future<void> _getUserLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final loc = LatLng(pos.latitude, pos.longitude);

      setState(() => _userLocation = loc);
      _mapController.move(loc, 13);
    } catch (_) {
      // Keep default Tunis center if location fails
    }
  }

  // ── Load all items from Firestore ─────────────────────
  Future<void> _loadItems() async {
    try {
      final snap = await _db.collection('items').get();
      final items = snap.docs
          .map((d) => ItemModel.fromMap(d.data(), d.id))
          .where((item) => item.lat != null && item.lng != null)
          .toList();

      setState(() {
        _items   = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<ItemModel> get _filteredItems {
    if (_filter == 'all') return _items;
    return _items.where((i) => i.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Map View',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selected = null),
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.refound.app',
              ),

              // Item markers
              MarkerLayer(
                markers: [
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40, height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.my_location_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),

                  // Item markers
                  ..._filteredItems.map((item) => Marker(
                    point: LatLng(item.lat!, item.lng!),
                    width: 40, height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: item.isLost
                              ? const Color(0xFFE24B4A)
                              : AppColors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          item.isLost
                              ? Icons.search_off_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // ── Filter chips (top) ─────────────────────────
          Positioned(
            top: 12, left: 16, right: 16,
            child: Row(children: [
              _filterChip('all',   'All'),
              const SizedBox(width: 8),
              _filterChip('lost',  'Lost'),
              const SizedBox(width: 8),
              _filterChip('found', 'Found'),
            ]),
          ),

          // ── Loading ────────────────────────────────────
          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: AppColors.teal)),

          // ── Selected item card (bottom) ────────────────
          if (_selected != null)
            Positioned(
              bottom: 20, left: 16, right: 16,
              child: _buildItemCard(_selected!),
            ),

          // ── My location FAB ────────────────────────────
          Positioned(
            bottom: _selected != null ? 140 : 20,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14);
                }
              },
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter chip ───────────────────────────────────────
  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            )),
      ),
    );
  }

  // ── Selected item card ────────────────────────────────
  Widget _buildItemCard(ItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        // Image or icon
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: item.isLost
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: item.imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.imageUrl, fit: BoxFit.cover),
                )
              : Icon(
                  item.isLost
                      ? Icons.search_off_rounded
                      : Icons.check_circle_outline_rounded,
                  color: item.isLost
                      ? const Color(0xFF854F0B)
                      : const Color(0xFF0F6E56),
                  size: 26,
                ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(item.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isLost
                        ? const Color(0xFFFCEBEB)
                        : const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isLost ? 'Lost' : 'Found',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.isLost
                            ? const Color(0xFFA32D2D)
                            : const Color(0xFF0F6E56)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(item.location,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                      context, '/item-detail',
                      arguments: item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}