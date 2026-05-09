import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refound/theme/apptheme.dart';
import '../../../models/usermodel.dart';
import '../../../models/itemmodel.dart';
import '../widgets/actionscard.dart';
import '../widgets/listingcard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  final GlobalKey _notifKey   = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();

  UserModel? _user;
  bool       _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ✅ Only load user profile once — listings use stream
  Future<void> _loadUser() async {
    try {
      final uid    = _auth.currentUser!.uid;
      final doc    = await _db.collection('users').doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _user    = UserModel.fromMap(doc.data()!);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('HomeScreen user load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  RelativeRect _menuPosition(GlobalKey key, double leftOffset) {
    final box    = key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    return RelativeRect.fromLTRB(
      offset.dx - leftOffset,
      offset.dy + box.size.height + 8,
      offset.dx + box.size.width,
      0,
    );
  }

  void _showNotifMenu() {
    showMenu<dynamic>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: _menuPosition(_notifKey, 200),
      items: <PopupMenuEntry<dynamic>>[
        const PopupMenuItem<dynamic>(
          enabled: false,
          height: 44,
          child: Text('Notifications',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<dynamic>(
          enabled: false,
          height: 60,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 28, color: AppColors.textSecondary),
                SizedBox(height: 6),
                Text('No notifications yet',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProfileMenu() {
    showMenu<dynamic>(
      context: context,
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: _menuPosition(_profileKey, 160),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem<dynamic>(
          enabled: false,
          height: 54,
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.teal.withOpacity(0.15),
              child: Text(
                (_user?.name.isNotEmpty == true)
                    ? _user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_user?.name ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(_user?.email ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<dynamic>(
          height: 44,
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: const Row(children: [
            Icon(Icons.manage_accounts_outlined,
                size: 18, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('Manage Profile',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<dynamic>(
          height: 44,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/welcome');
            }
          },
          child: const Row(children: [
            Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Logout',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : RefreshIndicator(
              color: AppColors.teal,
              onRefresh: _loadUser,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildTopBar()),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildMyListings(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome Back!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    _user?.name ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
              Row(children: [
                GestureDetector(
                  key: _notifKey,
                  onTap: _showNotifMenu,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  key: _profileKey,
                  onTap: _showProfileMenu,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(
              label: 'Post Lost/Found Item',
              icon: Icons.upload_outlined,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFF854F0B),
              onTap: () => Navigator.pushNamed(context, '/postitem',
                  arguments: 'lost'),
            ),
            QuickActionCard(
              label: 'Browse Listings',
              icon: Icons.search_rounded,
              iconBg: const Color(0xFFE1F5EE),
              iconColor: const Color(0xFF0F6E56),
              onTap: () => Navigator.pushNamed(context, '/browse'),
            ),
            QuickActionCard(
              label: 'Map View',
              icon: Icons.map_outlined,
              iconBg: const Color(0xFFE6F1FB),
              iconColor: const Color(0xFF185FA5),
              onTap: () => Navigator.pushNamed(context, '/map'),
            ),
            QuickActionCard(
              label: 'Messages',
              icon: Icons.chat_bubble_outline_rounded,
              iconBg: const Color(0xFFEEEDFE),
              iconColor: const Color(0xFF534AB7),
              onTap: () => Navigator.pushNamed(context, '/messages'),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ Real-time stream — updates instantly on add/delete/edit
  Widget _buildMyListings() {
    final uid = _auth.currentUser!.uid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Listings',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/my-listings'),
              child: const Text('View all',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ✅ StreamBuilder listens to Firestore in real time
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('items')
              .where('userId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal));
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _emptyListings();
            }

            // Sort and take latest 3 in Dart
            final items = snap.data!.docs
                .map((d) => ItemModel.fromMap(
                    d.data() as Map<String, dynamic>, d.id))
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            final latest = items.take(3).toList();

            return Column(
              children: latest
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListingCard(item: item),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyListings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(Icons.inbox_outlined,
            size: 36, color: AppColors.textSecondary.withOpacity(0.4)),
        const SizedBox(height: 10),
        Text('No listings yet',
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withOpacity(0.6))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/postitem', arguments: 'lost'),
          child: const Text('Post your first item',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.teal,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}