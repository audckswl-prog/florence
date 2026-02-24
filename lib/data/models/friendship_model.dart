class Friendship {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status; // 'pending' or 'accepted'
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'],
      requesterId: json['requester_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
