class UserProfile {
  final String id;
  final String name;

  UserProfile({required this.id, required this.name});

  // Convert MongoDB JSON to Dart Object
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(id: json['_id'].toString(), name: json['name']);
  }

}


