import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../theme/apptheme.dart';
import '../../../models/itemmodel.dart';
import '../../../services/imgbbservices.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<ItemModel> _allItems      = [];
  List<ItemModel> _filteredItems = [];
  bool   _loading      = true;
  String _statusFilter = 'all';
  String _typeFilter   = 'all';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final uid  = _auth.currentUser!.uid;
      final snap = await _db
          .collection('items')
          .where('userId', isEqualTo: uid)
          .get();

      if (!mounted) return;

      final items = snap.docs
          .map((d) => ItemModel.fromMap(d.data(), d.id))
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _allItems      = items;
        _filteredItems = List.from(items);
        _loading       = false;
      });
    } catch (e) {
      debugPrint('MyListings error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchStatus = _statusFilter == 'all' || item.status == _statusFilter;
        final matchType   = _typeFilter   == 'all' || item.type   == _typeFilter;
        return matchStatus && matchType;
      }).toList();
    });
  }

  // ── Delete ────────────────────────────────────────────
  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete this listing.',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _db.collection('items').doc(item.id).delete();
      if (!mounted) return;
      // ✅ Remove from both lists immediately
      setState(() {
        _allItems.removeWhere((i) => i.id == item.id);
        _filteredItems.removeWhere((i) => i.id == item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing deleted.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Toggle resolved ───────────────────────────────────
  Future<void> _toggleResolved(ItemModel item) async {
    final newStatus = item.status == 'resolved' ? 'active' : 'resolved';
    try {
      await _db.collection('items').doc(item.id)
          .update({'status': newStatus});
      if (!mounted) return;
      setState(() {
        final idx = _allItems.indexWhere((i) => i.id == item.id);
        if (idx != -1) {
          _allItems[idx] = ItemModel(
            id: item.id, userId: item.userId, title: item.title,
            description: item.description, category: item.category,
            type: item.type, status: newStatus, location: item.location,
            imageUrl: item.imageUrl, date: item.date,
            createdAt: item.createdAt, lat: item.lat, lng: item.lng,
          );
        }
        _applyFilters();
      });
    } catch (e) {
      debugPrint('Toggle error: $e');
    }
  }

  // ── Edit ──────────────────────────────────────────────
  void _editItem(ItemModel item) {
    final nameCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    final locCtrl  = TextEditingController(text: item.location);
    final dateCtrl = TextEditingController(text: item.date);
    final formKey  = GlobalKey<FormState>();

    String     category        = item.category;
    DateTime?  selectedDate;
    Uint8List? pickedBytes;
    String     currentImageUrl = item.imageUrl;
    double?    lat             = item.lat;
    double?    lng             = item.lng;
    bool       saving          = false;

    final categories = [
      'Keys', 'Wallet', 'Phone', 'Bag', 'Documents',
      'Jewelry', 'Glasses', 'Electronics', 'Clothing', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {

          Future<void> pickImage() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 75);
            if (picked == null) return;
            final bytes = await picked.readAsBytes();
            setSheet(() => pickedBytes = bytes);
          }

          Future<void> pickDate() async {
            final now  = DateTime.now();
            final date = await showDatePicker(
              context: ctx,
              initialDate: selectedDate ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: now,
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.teal)),
                child: child!,
              ),
            );
            if (date != null) {
              setSheet(() {
                selectedDate  = date;
                dateCtrl.text = DateFormat('dd MMM yyyy').format(date);
              });
            }
          }

          Future<void> pickLocation() async {
            final raw    = await Navigator.pushNamed(context, '/pick-location');
            final result = raw is Map ? Map<String, dynamic>.from(raw) : null;
            if (result != null) {
              setSheet(() {
                lat          = (result['lat'] as num?)?.toDouble();
                lng          = (result['lng'] as num?)?.toDouble();
                final address = result['address'] as String?;
                locCtrl.text = (address != null && address.isNotEmpty)
                    ? address
                    : '${lat?.toStringAsFixed(4)}, ${lng?.toStringAsFixed(4)}';
              });
            }
          }

          Future<void> save() async {
            if (!formKey.currentState!.validate()) return;
            setSheet(() => saving = true);

            try {
              String? newImageUrl;
              if (pickedBytes != null) {
                newImageUrl = await ImgbbService.uploadImageBytes(pickedBytes!);
                if (newImageUrl == null) throw 'Image upload failed.';
              }

              await _db.collection('items').doc(item.id).update({
                'title':       nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                'category':    category,
                'location':    locCtrl.text.trim(),
                'date':        dateCtrl.text.trim(),
                'imageUrl':    newImageUrl ?? currentImageUrl,
                if (lat != null) 'lat': lat,
                if (lng != null) 'lng': lng,
              });

              // ✅ Update in local list
              if (mounted) {
                setState(() {
                  final updated = ItemModel(
                    id: item.id, userId: item.userId,
                    title: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    category: category, type: item.type,
                    status: item.status,
                    location: locCtrl.text.trim(),
                    imageUrl: newImageUrl ?? currentImageUrl,
                    date: dateCtrl.text.trim(),
                    createdAt: item.createdAt, lat: lat, lng: lng,
                  );
                  final idx = _allItems.indexWhere((i) => i.id == item.id);
                  if (idx != -1) _allItems[idx] = updated;
                  _applyFilters();
                });
              }

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Listing updated!'),
                    backgroundColor: AppColors.teal,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              setSheet(() => saving = false);
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const Text('Edit Listing',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 20),

                    // Photo
                    _label('Photo'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity, height: 130,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pickedBytes != null
                                ? AppColors.teal : AppColors.border,
                            width: pickedBytes != null ? 1.5 : 1,
                          ),
                        ),
                        child: pickedBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(pickedBytes!,
                                    fit: BoxFit.cover))
                            : currentImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(currentImageUrl,
                                            fit: BoxFit.cover),
                                        Positioned(
                                          bottom: 8, right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.navy.withOpacity(0.7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text('Change photo',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38, height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.teal.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: AppColors.teal, size: 20),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Add photo',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Item Name
                    _label('Item Name *'),
                    const SizedBox(height: 6),
                    _field(controller: nameCtrl, hint: 'Item name',
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),

                    // Category
                    _label('Category'),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textPrimary),
                          items: categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setSheet(() => category = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    _label('Description'),
                    const SizedBox(height: 6),
                    _field(controller: descCtrl,
                        hint: 'Describe the item...', maxLines: 3),
                    const SizedBox(height: 12),

                    // Location
                    _label('Location *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: pickLocation,
                      child: AbsorbPointer(
                        child: _field(
                          controller: locCtrl,
                          hint: 'Tap to pick on map',
                          prefixIcon: Icon(Icons.location_on_outlined,
                              size: 18,
                              color: lat != null
                                  ? AppColors.teal
                                  : AppColors.textSecondary),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date
                    _label('Date *'),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: pickDate,
                      child: AbsorbPointer(
                        child: _field(
                          controller: dateCtrl,
                          hint: 'Select date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textSecondary),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: saving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: saving
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
        title: const Text('My Listings',
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
      body: Column(
        children: [
          // ── Filters ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                Row(children: [
                  _typeTab('all', 'All'),
                  const SizedBox(width: 8),
                  _typeTab('lost', 'Lost'),
                  const SizedBox(width: 8),
                  _typeTab('found', 'Found'),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _statusTab('all',      'All',      AppColors.navy),
                  const SizedBox(width: 8),
                  _statusTab('active',   'Active',   const Color(0xFF0F6E56)),
                  const SizedBox(width: 8),
                  _statusTab('resolved', 'Resolved', const Color(0xFF534AB7)),
                ]),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          if (!_loading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: AppColors.surface,
              child: Text(
                '${_filteredItems.length} listing${_filteredItems.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _buildCard(_filteredItems[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/postitem');
          _loadItems();
        },
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Item',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCard(ItemModel item) {
    final isResolved = item.status == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isResolved
              ? const Color(0xFFAFA9EC)
              : AppColors.border,
        ),
      ),
      child: Opacity(
        opacity: isResolved ? 0.8 : 1.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, '/item-detail',
                    arguments: item);
                _loadItems();
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: SizedBox(
                  width: 90, height: 110,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(item))
                      : _placeholder(item),
                ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(item.title,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isResolved
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _typeBadge(item),
                            if (isResolved) ...[
                              const SizedBox(height: 4),
                              _resolvedBadge(),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(item.category,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.teal),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.teal),
                      const SizedBox(width: 3),
                      Text(item.date,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 10),

                    // ── Action buttons ────────────────
                    Row(children: [
                      // Edit
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editItem(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F1FB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 12,
                                    color: Color(0xFF185FA5)),
                                SizedBox(width: 4),
                                Text('Edit',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF185FA5))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Resolve / Reopen
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleResolved(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFFEEEDFE)
                                  : const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isResolved
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 12,
                                  color: isResolved
                                      ? const Color(0xFF534AB7)
                                      : const Color(0xFF0F6E56),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isResolved ? 'Reopen' : 'Resolve',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isResolved
                                          ? const Color(0xFF534AB7)
                                          : const Color(0xFF0F6E56)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Delete
                      GestureDetector(
                        onTap: () => _deleteItem(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBEB),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 12, color: Color(0xFFA32D2D)),
                            SizedBox(width: 4),
                            Text('Delete',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA32D2D))),
                          ]),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter tabs ───────────────────────────────────────
  Widget _typeTab(String value, String label) {
    final selected = _typeFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _typeFilter = value); _applyFilters(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? AppColors.navy : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _statusTab(String value, String label, Color activeColor) {
    final selected = _statusFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _statusFilter = value); _applyFilters(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          decoration: BoxDecoration(
            color: selected ? activeColor.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: selected ? activeColor : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? activeColor : AppColors.textSecondary)),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4)),
  );

  Widget _field({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
      ),
    );
  }

  Widget _typeBadge(ItemModel item) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: item.isLost
          ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(item.isLost ? 'Lost' : 'Found',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: item.isLost
                ? const Color(0xFFA32D2D) : const Color(0xFF0F6E56))),
  );

  Widget _resolvedBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEDFE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text('Resolved',
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: Color(0xFF534AB7))),
  );

  Widget _placeholder(ItemModel item) => Container(
    color: item.isLost
        ? const Color(0xFFFEF3C7) : const Color(0xFFE1F5EE),
    child: Center(
      child: Icon(
        item.isLost
            ? Icons.search_off_rounded
            : Icons.check_circle_outline_rounded,
        size: 28,
        color: item.isLost
            ? const Color(0xFF854F0B) : const Color(0xFF0F6E56),
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined,
            size: 52,
            color: AppColors.textSecondary.withOpacity(0.3)),
        const SizedBox(height: 14),
        const Text('No listings yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(
          _statusFilter != 'all' || _typeFilter != 'all'
              ? 'No listings match your filters'
              : 'Post your first lost or found item',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.7)),
        ),
      ],
    ),
  );
}