class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isEdited;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.isEdited  = false,
    this.isDeleted = false,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'senderId':  senderId,
    'text':      text,
    'imageUrl':  imageUrl ?? '',
    'createdAt': createdAt.toIso8601String(),
    'isEdited':  isEdited,
    'isDeleted': isDeleted,
  };

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) =>
      MessageModel(
        id:        id,
        senderId:  map['senderId']  ?? '',
        text:      map['text']      ?? '',
        imageUrl:  map['imageUrl'],
        createdAt: map['createdAt'] is String
            ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
            : (map['createdAt'] as dynamic).toDate(),
        isEdited:  map['isEdited']  ?? false,
        isDeleted: map['isDeleted'] ?? false,
      );
}