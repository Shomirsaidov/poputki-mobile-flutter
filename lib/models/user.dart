class User {
  final int id;
  final String? phone;
  final String? name;
  final int? age;
  final String? role;
  final String? photoUrl;
  final bool isNew;

  User({
    required this.id,
    this.phone,
    this.name,
    this.age,
    this.role,
    this.photoUrl,
    required this.isNew,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      age: json['age'],
      role: json['role'],
      photoUrl: json['photo_url'],
      isNew: json['isNew'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'age': age,
      'role': role,
      'photo_url': photoUrl,
      'isNew': isNew,
    };
  }
}
