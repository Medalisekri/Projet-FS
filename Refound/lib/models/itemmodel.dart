class ItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;       // ← new
  final String type;
  final String status;
  final String location;
  final String imageUrl;       // ← new
  final String date;           // ← new
  final DateTime createdAt;
 final double? lat;    // ← new
  final double? lng; 
  ItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.status,
    required this.location,
    required this.imageUrl,
    required this.date,
    required this.createdAt,
    required this.lat,
     required this.lng,
  });

  bool get isLost => type == 'lost';

  Map<String, dynamic> toMap() => {
    'userId':      userId,
    'title':       title,
    'description': description,
    'category':    category,
    'type':        type,
    'status':      status,
    'location':    location,
    'imageUrl':    imageUrl,
    'date':        date,
    'createdAt':   createdAt.toIso8601String(),
      'lat': lat,
    'lng': lng,
  };

  factory ItemModel.fromMap(Map<String, dynamic> map, String id) => ItemModel(
    id:          id,
    userId:      map['userId'] ?? '',
    title:       map['title'] ?? '',
    description: map['description'] ?? '',
    category:    map['category'] ?? 'Other',
    type:        map['type'] ?? 'lost',
    status:      map['status'] ?? 'active',
    location:    map['location'] ?? '',
    imageUrl:    map['imageUrl'] ?? '',
    date:        map['date'] ?? '',
    createdAt:   DateTime.parse(map['createdAt']),
     lat: (map['lat'] as num?)?.toDouble(),
    lng: (map['lng'] as num?)?.toDouble(),
  );
}


/*

### Firestore index needed

Since the query uses both `where` and `orderBy`, add this index in Firebase Console → Firestore → Indexes:
```
Collection: items
Fields:     userId (Ascending) + createdAt (Descending)*/