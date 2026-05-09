import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/apptheme.dart';
import '../../../models/msgmodel.dart';
import '../../../services/imgbbservices.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db          = FirebaseFirestore.instance;
  final _auth        = FirebaseAuth.instance;
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();

  late String _chatId;
  late String _otherUserId;
  late String _otherName;
  late String _itemTitle;

  MessageModel? _editingMsg;
  bool _isBlocked    = false;
  bool _sending      = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      setState(() {
        _chatId      = args['chatId'];
        _otherUserId = args['otherUserId'];
        _otherName   = args['otherName'];
        _itemTitle   = args['itemTitle'];
      });
      _checkBlocked();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _myUid => _auth.currentUser!.uid;

  Future<void> _checkBlocked() async {
    final doc = await _db.collection('chats').doc(_chatId).get();
    if (doc.exists) {
      final blocked = List<String>.from(doc.data()?['blockedBy'] ?? []);
      setState(() => _isBlocked = blocked.contains(_myUid));
    }
  }

  // ── Send text message ─────────────────────────────────
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      // Editing existing message
      if (_editingMsg != null) {
        await _db
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .doc(_editingMsg!.id)
            .update({'text': text, 'isEdited': true});
        setState(() => _editingMsg = null);
      } else {
        // New message
        await _addMessage(text: text);
      }
    } finally {
      setState(() => _sending = false);
    }
  }

  // ── Send image ────────────────────────────────────────
Future<void> _sendImage() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
      source: ImageSource.gallery, imageQuality: 75);
  if (picked == null) return;

  setState(() => _sending = true);
  try {
    final bytes = await picked.readAsBytes();
    final url   = await ImgbbService.uploadImageBytes(bytes);
    if (url != null) await _addMessage(imageUrl: url);
  } finally {
    setState(() => _sending = false);
  }
}

  Future<void> _addMessage({String text = '', String? imageUrl}) async {
    final msg = MessageModel(
      id:        '',
      senderId:  _myUid,
      text:      text,
      imageUrl:  imageUrl,
      createdAt: DateTime.now(),
    );

    await _db
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add(msg.toMap());

    // Update chat last message
    await _db.collection('chats').doc(_chatId).update({
      'lastMessage':   imageUrl != null ? '📷 Image' : text,
      'lastMessageAt': DateTime.now().toIso8601String(),
    });

    _scrollToBottom();
  }

  // ── Delete message ────────────────────────────────────
  Future<void> _deleteMessage(MessageModel msg) async {
    await _db
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .doc(msg.id)
        .update({'isDeleted': true, 'text': '', 'imageUrl': ''});
  }

  // ── Block / Unblock ───────────────────────────────────
  Future<void> _toggleBlock() async {
    final chatRef = _db.collection('chats').doc(_chatId);
    if (_isBlocked) {
      await chatRef.update({
        'blockedBy': FieldValue.arrayRemove([_myUid])
      });
    } else {
      await chatRef.update({
        'blockedBy': FieldValue.arrayUnion([_myUid])
      });
    }
    setState(() => _isBlocked = !_isBlocked);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_otherName,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(_itemTitle,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              PopupMenuItem<dynamic>(
                onTap: _toggleBlock,
                child: Row(children: [
                  Icon(
                    _isBlocked
                        ? Icons.lock_open_outlined
                        : Icons.block_outlined,
                    size: 18,
                    color: _isBlocked
                        ? AppColors.teal
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isBlocked ? 'Unblock User' : 'Block User',
                    style: TextStyle(
                        fontSize: 13,
                        color: _isBlocked
                            ? AppColors.teal
                            : Colors.redAccent),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Messages list ─────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.teal));
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48,
                            color: AppColors.textSecondary
                                .withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(
                                color: AppColors.textSecondary
                                    .withOpacity(0.6),
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Say hello!',
                            style: TextStyle(
                                color: AppColors.teal,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }

                final messages = snap.data!.docs
                    .map((d) => MessageModel.fromMap(
                        d.data() as Map<String, dynamic>, d.id))
                    .toList();

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _buildMessageBubble(messages[i]),
                );
              },
            ),
          ),

          // ── Blocked banner ────────────────────────────
          if (_isBlocked)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.redAccent.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block_outlined,
                      size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  const Text('You blocked this user.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.redAccent)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBlock,
                    child: const Text('Unblock',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.teal,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          // ── Edit banner ───────────────────────────────
          if (_editingMsg != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: AppColors.teal.withOpacity(0.08),
              child: Row(children: [
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Editing: ${_editingMsg!.text}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.teal),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _editingMsg = null);
                    _msgCtrl.clear();
                  },
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.teal),
                ),
              ]),
            ),

          // ── Input bar ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(children: [
                // Image button
                GestureDetector(
                  onTap: _isBlocked ? null : _sendImage,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _isBlocked
                          ? AppColors.border
                          : AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.image_outlined,
                        color: _isBlocked
                            ? AppColors.textSecondary
                            : AppColors.teal,
                        size: 20),
                  ),
                ),
                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    enabled: !_isBlocked,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: _isBlocked
                          ? 'You blocked this user'
                          : 'Type a message...',
                      hintStyle: TextStyle(
                          color: AppColors.textSecondary.withOpacity(0.5),
                          fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _isBlocked ? null : _send,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _isBlocked
                          ? AppColors.border
                          : AppColors.teal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────
  Widget _buildMessageBubble(MessageModel msg) {
    final isMe = msg.senderId == _myUid;

    if (msg.isDeleted) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Message deleted',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic)),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: isMe ? () => _showMessageOptions(msg) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: msg.hasImage
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.teal : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border),
                ),
                child: msg.hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        child: Image.network(msg.imageUrl!,
                            width: 200,
                            fit: BoxFit.cover),
                      )
                    : Text(msg.text,
                        style: TextStyle(
                            fontSize: 14,
                            color: isMe
                                ? Colors.white
                                : AppColors.textPrimary)),
              ),

              // Time + edited
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.isEdited)
                    const Text('edited · ',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),
                  Text(
                    _formatTime(msg.createdAt),
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Message options (long press) ──────────────────────
  void _showMessageOptions(MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Edit (only for text messages)
            if (!msg.hasImage)
              ListTile(
                leading: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary),
                title: const Text('Edit Message',
                    style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMsg = msg;
                    _msgCtrl.text = msg.text;
                  });
                },
              ),

            // Delete
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              title: const Text('Delete Message',
                  style: TextStyle(
                      fontSize: 14, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(msg);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}