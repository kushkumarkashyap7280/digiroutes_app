/// User data model.
class AppUser {
  final String id;
  final String email;
  final String name;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:    json['_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name:  json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':   id,
    'email': email,
    'name':  name,
  };
}
