class Profile {
  final String id;
  final String? nickname;
  final String? profileUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    this.nickname,
    this.profileUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      nickname: json['nickname'],
      profileUrl: json['profile_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'profile_url': profileUrl,
    };
  }
}
