// lib/models/photo.dart
class Photo {
  final String id;
  final String url; // This is the local file path of the compressed image
  final String timestamp;
  final String docName; // This will be the "Container Position"
  final String description; // ADDED: Field for the description

  Photo({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.docName,
    required this.description, // ADDED
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      url: json['url'],
      timestamp: json['timestamp'],
      docName: json['docName'],
      description: json['FileDesc'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp,
      'docName': docName,
      'description': description,
    };
  }
}
