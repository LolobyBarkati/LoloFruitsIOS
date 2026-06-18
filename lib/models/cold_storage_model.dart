class ColdStorageModel {
  final String id;
  final String name;
  final String price;
  final String phone;
  final String mapLink;
  final String fileUrl;

  ColdStorageModel({
    required this.id,
    required this.name,
    required this.price,
    required this.phone,
    required this.mapLink,
    required this.fileUrl,
  });

  factory ColdStorageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ColdStorageModel(
      id: id,
      name: data['name'] ?? '',
      price: data['price_per_week'] ?? '',
      phone: data['director_number'] ?? '',
      mapLink: data['google_map_link'] ?? '',
      fileUrl: data['file_url'] ?? '',
    );
  }

  Map<String, dynamic> toCache() => {
        'id': id,
        'name': name,
        'price': price,
        'phone': phone,
        'mapLink': mapLink,
        'fileUrl': fileUrl,
      };

  factory ColdStorageModel.fromCache(Map<String, dynamic> json) {
    return ColdStorageModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      phone: json['phone'] ?? '',
      mapLink: json['mapLink'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
    );
  }
}