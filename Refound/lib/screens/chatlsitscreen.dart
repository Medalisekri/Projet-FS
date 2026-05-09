import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/apptheme.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db    = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Messages',
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
      body: StreamBuilder<QuerySnapshot>(
        // ✅ No orderBy — avoids index requirement
        stream: db
            .collection('chats')
            .where('participants', arrayContains: myUid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.teal));
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 52,
                      color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 14),
                  const Text('No conversations yet',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Start by messaging someone on a listing',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.7))),
                ],
              ),
            );
          }

          // ✅ Sort in Dart — no Firestore index needed
          final chats = snap.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['lastMessageAt'] as String?) ?? '';
              final bTime = (bData['lastMessageAt'] as String?) ?? '';
              return bTime.compareTo(aTime);
            });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: AppColors.border,
                indent: 76,
                endIndent: 16),
            itemBuilder: (_, i) {
              final data = chats[i].data() as Map<String, dynamic>;
              final chatId = chats[i].id;

              // ✅ Safe null handling for every field
              final parts = List<String>.from(
                  (data['participants'] as List?)?.map((e) => e.toString()) ?? []);
              final otherId   = parts.firstWhere(
                  (id) => id != myUid, orElse: () => '');
              final lastMsg   = (data['lastMessage']   as String?) ?? '';
              final itemTitle = (data['itemTitle']     as String?) ?? '';
              final lastAt    = (data['lastMessageAt'] as String?) ?? '';

              return _ChatTile(
                chatId:    chatId,
                otherId:   otherId,
                lastMsg:   lastMsg,
                itemTitle: itemTitle,
                lastMsgAt: lastAt,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final String otherId;
  final String lastMsg;
  final String itemTitle;
  final String lastMsgAt;

  const _ChatTile({
    required this.chatId,
    required this.otherId,
    required this.lastMsg,
    required this.itemTitle,
    required this.lastMsgAt,
  });

  String _formatTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt  = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:'
               '${dt.minute.toString().padLeft(2, '0')}';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Guard — if otherId is empty don't even try to fetch
    if (otherId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(otherId)
          .get(),
      builder: (context, snap) {

        // ✅ Loading skeleton
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 13,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        )),
                    const SizedBox(height: 8),
                    Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: AppColors.border.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        )),
                  ],
                ),
              ),
            ]),
          );
        }

        // ✅ Safe data extraction with full null handling
        String name = 'User';
        if (snap.hasData &&
            snap.data != null &&
            snap.data!.exists &&
            snap.data!.data() != null) {
          final userData = snap.data!.data() as Map<String, dynamic>;
          name = (userData['name'] as String?) ?? 'User';
        }

        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
            'chatId':      chatId,
            'otherUserId': otherId,
            'otherName':   name,
            'itemTitle':   itemTitle,
          }),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(children: [
              // Avatar
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),

              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatTime(lastMsgAt),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (itemTitle.isNotEmpty)
                      Text('Re: $itemTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.teal,
                              fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      lastMsg.isEmpty ? 'No messages yet' : lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: lastMsg.isEmpty
                              ? AppColors.textSecondary.withOpacity(0.5)
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.border, size: 20),
            ]),
          ),
        );
      },
    );
  }
}