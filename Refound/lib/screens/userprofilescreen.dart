import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/apptheme.dart';
import '../../../models/usermodel.dart';
import '../../../services/imgbbservices.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  UserModel? _user;
  bool       _loading  = true;
  bool       _saving   = false;
  bool       _editing  = false;

  Uint8List? _pickedBytes;
  String     _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        setState(() {
          _user       = user;
          _nameCtrl.text  = user.name;
          _phoneCtrl.text = user.phone;
        
          _loading    = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _pickedBytes = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final uid = _auth.currentUser!.uid;
      String? newAvatarUrl;

      // Upload new avatar if picked
      if (_pickedBytes != null) {
        newAvatarUrl = await ImgbbService.uploadImageBytes(_pickedBytes!);
        if (newAvatarUrl == null) throw 'Image upload failed.';
      }

      final updates = {
        'name':  _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (newAvatarUrl != null) 'avatarUrl': newAvatarUrl,
      };

      await _db.collection('users').doc(uid).update(updates);

      // Update Firebase Auth display name
      await _auth.currentUser!.updateDisplayName(_nameCtrl.text.trim());

      if (!mounted) return;
      setState(() {
        _user = UserModel(
          uid:       _user!.uid,
          name:      _nameCtrl.text.trim(),
          phone:     _phoneCtrl.text.trim(),
          email:     _user!.email,
          createdAt: _user!.createdAt,
          isVerified: _user!.isVerified,
          role:      _user!.role,
     
        );
        _avatarUrl   = newAvatarUrl ?? _avatarUrl;
        _pickedBytes = null;
        _editing     = false;
        _saving      = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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

  Future<void> _changePassword() async {
    final emailCtrl = TextEditingController(
        text: _auth.currentUser?.email ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_outlined,
                size: 40, color: AppColors.teal),
            const SizedBox(height: 12),
            Text(
              'A password reset link will be sent to:\n${_auth.currentUser?.email ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _auth.sendPasswordResetEmail(
                    email: _auth.currentUser!.email!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset link sent to your email!'),
                      backgroundColor: AppColors.teal,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete your account and all your listings. This cannot be undone.',
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
      final uid = _auth.currentUser!.uid;

      // Delete user's items
      final items = await _db
          .collection('items')
          .where('userId', isEqualTo: uid)
          .get();
      for (final doc in items.docs) {
        await doc.reference.delete();
      }

      // Delete user doc
      await _db.collection('users').doc(uid).delete();

      // Delete auth account
      await _auth.currentUser!.delete();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Delete failed. Please re-login and try again.\n${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        title: const Text('Manage Profile',
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
          if (!_loading)
            TextButton(
              onPressed: () {
                if (_editing) {
                  // Cancel — restore original values
                  setState(() {
                    _nameCtrl.text  = _user?.name  ?? '';
                    _phoneCtrl.text = _user?.phone ?? '';
                    _pickedBytes    = null;
                    _editing        = false;
                  });
                } else {
                  setState(() => _editing = true);
                }
              },
              child: Text(
                _editing ? 'Cancel' : 'Edit',
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Avatar ────────────────────────────
                    Center(
                      child: Stack(
                        children: [
                          // Avatar circle
                          Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal.withOpacity(0.15),
                              border: Border.all(
                                  color: AppColors.teal.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: ClipOval(
                              child: _pickedBytes != null
                                  ? Image.memory(_pickedBytes!,
                                      fit: BoxFit.cover)
                                  : _avatarUrl.isNotEmpty
                                      ? Image.network(_avatarUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _avatarFallback())
                                      : _avatarFallback(),
                            ),
                          ),

                          // Edit camera button
                          if (_editing)
                            Positioned(
                              bottom: 0, right: 0,
                              child: GestureDetector(
                                onTap: _pickAvatar,
                                child: Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.teal,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white,
                                      size: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email (read-only always)
                    Center(
                      child: Text(
                        _user?.email ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary),
                      ),
                    ),

                    // Role badge
                    if (_user?.isAdmin == true)
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF854F0B))),
                        ),
                      ),

                    const SizedBox(height: 28),

                    // ── Info section ──────────────────────
                    _sectionTitle('Personal Info'),
                    const SizedBox(height: 14),

                    // Name
                    _fieldLabel('Full Name'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: _editing,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: _inputDec(
                          hint: '',
                          icon: Icons.person_outline_rounded),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.trim().length < 3) return 'Min 3 characters';
                        if (v.contains(RegExp(r'[0-9]')))
                          return 'Name must contain only letters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    _fieldLabel('Phone'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneCtrl,
                      enabled: _editing,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                      decoration: _inputDec(
                          hint: '',
                          icon: Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.contains(RegExp(r'[a-zA-Z]')))
                          return 'Phone must contain only numbers';
                        if (v.length != 8) return 'Must be exactly 8 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email (always disabled)
                    _fieldLabel('Email'),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _user?.email ?? '',
                      enabled: false,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                      decoration: _inputDec(
                          hint: 'Email address',
                          icon: Icons.email_outlined),
                    ),

                    // ── Save button ───────────────────────
                    if (_editing) ...[
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20, width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('Save Changes',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── Danger zone ───────────────────────
                    _sectionTitle('Danger Zone'),
                    const SizedBox(height: 14),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: _actionTile(
                        icon: Icons.delete_forever_outlined,
                        iconColor: Colors.redAccent,
                        label: 'Delete Account',
                        labelColor: Colors.redAccent,
                        onTap: _deleteAccount,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _avatarFallback() {
    return Center(
      child: Text(
        (_user?.name.isNotEmpty == true)
            ? _user!.name[0].toUpperCase()
            : 'U',
        style: const TextStyle(
            color: AppColors.teal,
            fontWeight: FontWeight.w700,
            fontSize: 36),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));

  Widget _fieldLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4));

  InputDecoration _inputDec({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
      filled: true,
      fillColor: _editing ? Colors.white : AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: AppColors.border.withOpacity(0.5))),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: labelColor ?? AppColors.textPrimary)),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: AppColors.border, size: 20)
              : null),
    );
  }
}