import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../theme/apptheme.dart';
import '../../../models/itemmodel.dart';
import '../../../models/usermodel.dart';
import '../../../services/imgbbservices.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late ItemModel _item;
  bool _itemLoaded = false;
  UserModel? _poster;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _item       = ModalRoute.of(context)!.settings.arguments as ItemModel;
        _itemLoaded = true;
      });
      _loadPoster();
    });
  }

  Future<void> _loadPoster() async {
    try {
      final doc = await _db.collection('users').doc(_item.userId).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _poster  = UserModel.fromMap(doc.data()!);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _myUid => _auth.currentUser!.uid;

  Future<void> _openChat() async {
    if (_myUid == _item.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your own listing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final chatId  = ([_myUid, _item.userId]..sort()).join('_');
    final chatRef = _db.collection('chats').doc(chatId);

    if (!(await chatRef.get()).exists) {
      await chatRef.set({
        'participants':  [_myUid, _item.userId],
        'itemId':        _item.id,
        'itemTitle':     _item.title,
        'createdAt':     DateTime.now().toIso8601String(),
        'lastMessage':   '',
        'lastMessageAt': DateTime.now().toIso8601String(),
        'blockedBy':     [],
      });
    }

    if (mounted) {
      Navigator.pushNamed(context, '/chat', arguments: {
        'chatId':      chatId,
        'otherUserId': _item.userId,
        'otherName':   _poster?.name ?? 'User',
        'itemTitle':   _item.title,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_itemLoaded) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    final isOwner = _myUid == _item.userId;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── AppBar with image ─────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  size: 18, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: const Text('Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: _item.imageUrl.isNotEmpty
                  ? Image.network(_item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imagePlaceholder(_item))
                  : _imagePlaceholder(_item),
            ),
          ),

          // ── Body ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Title + badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(_item.title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _item.isLost
                                  ? const Color(0xFFFCEBEB)
                                  : const Color(0xFFE1F5EE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _item.isLost ? 'Lost' : 'Found',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _item.isLost
                                      ? const Color(0xFFA32D2D)
                                      : const Color(0xFF0F6E56)),
                            ),
                          ),
                          // Resolved badge
                          if (_item.status == 'resolved') ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEDFE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Resolved',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF534AB7))),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(_item.category,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 14),

                  if (_item.description.isNotEmpty) ...[
                    Text(_item.description,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6)),
                    const SizedBox(height: 20),
                  ],

                  // ── Information ───────────────────────
                  _sectionTitle('Information'),
                  const SizedBox(height: 12),
                  _infoRow(
                    Icons.location_on_outlined,
                    _item.isLost ? 'Location Lost' : 'Location Found',
                    _item.location,
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  _infoRow(Icons.calendar_today_outlined, 'Date', _item.date),
                  const SizedBox(height: 24),

                  // ── Contact ───────────────────────────
                  // Only show contact for non-owners
                  if (!isOwner) ...[
                    _sectionTitle('Contact'),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.teal))
                    else if (_poster != null) ...[
                      _infoRow(Icons.person_outline_rounded,
                          'Name', _poster!.name),
                      const Divider(color: AppColors.border, height: 24),
                      _infoRow(Icons.phone_outlined,
                          'Phone', _poster!.phone),
                    ],
                    const SizedBox(height: 28),

                    // ── Send Message ──────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openChat,
                        icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18),
                        label: const Text('Send Message',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder(ItemModel item) {
    return Container(
      color: item.isLost
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFE1F5EE),
      child: Center(
        child: Icon(
          item.isLost
              ? Icons.search_off_rounded
              : Icons.check_circle_outline_rounded,
          size: 64,
          color: item.isLost
              ? const Color(0xFF854F0B)
              : const Color(0xFF0F6E56),
        ),
      ),
    );
  }
}