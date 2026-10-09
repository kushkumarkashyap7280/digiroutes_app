/// User data model.
class AppUser {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final String avatarId;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl = '',
    this.avatarId = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:        json['_id'] as String? ?? json['id'] as String? ?? '',
      email:     json['email'] as String? ?? '',
      name:      json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      avatarId:  json['avatarId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id':       id,
    'email':     email,
    'name':      name,
    'avatarUrl': avatarUrl,
    'avatarId':  avatarId,
  };

  /// First letters of the first two words — used when there is no avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
